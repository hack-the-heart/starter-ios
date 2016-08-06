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
    
    var healthObjectType: HealthObjectType?
    var realmHealthObjects: Results<HealthObject>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Reload Data
    func reloadData() {
        guard let healthObjTypeStr = healthObjectType?.rawValue else { return }
        
        let realm = try! Realm()
        
        realmHealthObjects = realm.objects(HealthObject).filter("type == %@", healthObjTypeStr)
        self.tableView.reloadData()
    }
    
    //MARK: - TableView Delegates
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = realmHealthObjects?.count {
            return count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath)
        }
        
        guard let realmHealthObjects = realmHealthObjects else {
            cell.title.text = "Error"
            return cell
        }
        
        let healthObj = realmHealthObjects[indexPath.item]
        let healthDataObjArr = healthObj.dataObjects
        
        //set data values string
        let dataValuesArr = healthDataObjArr.map { (dataObj) -> String in
            return dataObj.label! + ": " + dataObj.value!
        }
        
        let dataValuesStr = dataValuesArr.joinWithSeparator(",")
        
        cell.title.text = dataValuesStr
        
        //set date
        if let date = healthObj.date {
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
