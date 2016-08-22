//
//  HealthDataDataViewController.swift
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
    
    var realmHealthObjects: Results<HealthData>?
    
    var realmNotification: NotificationToken?
    
    //MARK: - Application Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let healthObjTypeStr = healthObjectType else { return }
        
        let realm = try! Realm()
        realmNotification = realm.objects(HealthData).filter("type == %@", healthObjTypeStr).addNotificationBlock({ (notification) in
            self.reloadData()
        })
        
        reloadData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        realmNotification?.stop()
        realmNotification = nil
    }
    
    deinit {
        if realmNotification != nil {
            realmNotification?.stop()
            realmNotification = nil
        }
    }
    
    //MARK: - Reload Data
    
    func reloadData() {
        guard let healthObjTypeStr = healthObjectType else { return }
        
        let realm = try! Realm()
        
        realmHealthObjects = realm.objects(HealthData).filter("type == %@", healthObjTypeStr)
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
            //assuming label and value will never be nil
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
