//
//  FirstViewController.swift
//  Starter App
//
//  Created by Saad Ismail on 5/23/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import UIKit
import HealthKit
import RealmSwift

class ViewDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    //property for storing a selected cell in a tableview. this is passed to ViewSpecificDataViewController
    var selectedHealthObject: String?
    
    //container to store HealthObjects. Used for UITableView
    var healthObjects: [String] = []
    
    /// realm notification to monitor any changes/additions to the realm obj: "HealthObject"
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
        
        let realm = try! Realm()
        realmNotification = realm.objects(HealthObject).addNotificationBlock({ (notification) in
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DisplayHealthObjectData",
            let selectedHealthObject = self.selectedHealthObject,
            let viewController = segue.destinationViewController as? ViewSpecificDataViewController {
            
            viewController.healthObjectType = selectedHealthObject
            
        }
    }
    
    //MARK: - Load Data
    
    func reloadData() {
        let realm = try! Realm()
        healthObjects = Array(Set(realm.objects(HealthObject).valueForKey("type") as! [String]))
        
        self.tableView.reloadData()
    }
    
    //MARK: - TableView Delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthObjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath)
        }
        
        cell.title.text = healthObjects[indexPath.item]
        cell.healthObjType = healthObjects[indexPath.item]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? HealthDataTableViewCell else { return }
        
        selectedHealthObject = cell.healthObjType
        self.performSegueWithIdentifier("DisplayHealthObjectData", sender: self)
    }
    
}

