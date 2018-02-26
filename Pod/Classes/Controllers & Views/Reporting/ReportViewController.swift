//
//  ReportViewController.swift
//  Peek
//
//  Created by Shaps Benkau on 26/02/2018.
//

import UIKit

internal protocol ReportViewControllerDelegate: class {
    func reportController(_ controller: ReportViewController, didSend report: Report)
    func reportControllerDidCancel(_ controller: ReportViewController)
}

internal final class ReportViewController: PeekSectionedViewController {
    
    internal weak var delegate: ReportViewControllerDelegate?
    
    private let includeScreenshotSwitch: UISwitch
    private let includeJSONSwitch: UISwitch
    
    private var report: Report
    
    internal init(peek: Peek, report: Report) {
        self.report = report
        
        includeScreenshotSwitch = UISwitch()
        includeJSONSwitch = UISwitch()
        
        super.init(peek: peek)
        
        title = "Report"
        
        includeScreenshotSwitch.addTarget(self, action: #selector(toggleScreenshot(_:)), for: .valueChanged)
        includeJSONSwitch.addTarget(self, action: #selector(toggleJSON(_:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelReport))
        let send = UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(sendReport))
        
        navigationItem.leftBarButtonItem = cancel
        navigationItem.rightBarButtonItem = send
    }
    
    @objc private func cancelReport() {
        delegate?.reportControllerDidCancel(self)
    }
    
    @objc private func sendReport() {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(report)
            let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            let jsonUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("report.json")
            try jsonData.write(to: jsonUrl, options: [.atomicWrite])
            
            var items: [Any?] = [ report.html ]
            
            if report.includeJSON {
                items.append(jsonData)
                items.append(json)
                items.append(jsonUrl)
            }
            
            if report.includeScreenshot {
                items.append(peek.screenshot)
            }
            
            let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            sheet.completionWithItemsHandler = { [weak self] type, success, activities, error in
                guard let `self` = self else { return }
                
                if success {
                    self.delegate?.reportController(self, didSend: self.report)
                } else {
                    self.delegate?.reportControllerDidCancel(self)
                }
            }
            
            present(sheet, animated: true, completion: nil)
        } catch {
            print(error)
        }
    }
    
    @objc private func toggleScreenshot(_ toggle: UISwitch) {
        report.includeScreenshot = toggle.isOn
    }
    
    @objc private func toggleJSON(_ toggle: UISwitch) {
        report.includeJSON = toggle.isOn
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return report.sections.count + 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mappedSection = section - 1
        return section == 0 ? 2 : report.sections[mappedSection].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = super.tableView(tableView, cellForRowAt: indexPath) as? InspectorCell else { fatalError() }
        
        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                cell.textLabel?.text = "Include Screenshot"
                cell.accessoryView = includeScreenshotSwitch
                includeScreenshotSwitch.isOn = report.includeScreenshot
            case 1:
                cell.textLabel?.text = "Include Detailed Report"
                cell.accessoryView = includeJSONSwitch
                includeJSONSwitch.isOn = report.includeJSON
            default: break
            }
        } else {
            let mappedSection = indexPath.section - 1
            let item = report.sections[mappedSection].items[indexPath.item]
            cell.textLabel?.text = item.displayTitle
            cell.detailTextLabel?.text = item.reportersNote
        }
        
        return cell
    }
    
    override func sectionTitle(for section: Int) -> String {
        let mappedSection = section - 1
        return section == 0 ? "Options" : report.sections[mappedSection].title
    }
    
}