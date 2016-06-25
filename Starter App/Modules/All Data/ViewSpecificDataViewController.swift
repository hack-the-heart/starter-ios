//
//  HealthObjectDataViewController.swift
//  Starter App
//
//  Created by ismails on 6/21/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit
import UIKit
import RealmSwift

class ViewSpecificDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var healthObjectType: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let realm = try! Realm()
        
        switch healthObjectType! {
            
        case String(Weight):
            return realm.objects(Weight).count
            
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath)
        }
        
        let realm = try! Realm()
        var healthObject: BaseHealthObject?
        
        switch healthObjectType! {
            
        case String(Weight):
            let allWeightObjs = realm.objects(Weight).sorted("date", ascending: false)
            let weightObj = allWeightObjs[indexPath.item]
            healthObject = weightObj
            
            cell.title.text = "\(weightObj.value.value!)"
        default:
            break
        }
        
        if let date = healthObject?.date {
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.ShortStyle
            formatter.timeStyle = .ShortStyle
            
            let dateString = formatter.stringFromDate(date)
            
            cell.subtitle.text = dateString
        } else {
            cell.subtitle.text = "Unknown"
        }
        
        return cell
    }

}
