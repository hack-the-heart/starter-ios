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
    
    var selectedHealthObject: String?
    
    var healthObjects: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadData()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DisplayHealthObjectData",
            let selectedHealthObject = self.selectedHealthObject,
            let viewController = segue.destinationViewController as? ViewSpecificDataViewController {
            
            viewController.healthObjectType = selectedHealthObject
            
        }
    }
    
    //MARK: - Load Data
    func loadData() {
        do {
            healthObjects = try Array(Set(Realm().objects(HealthObject).valueForKey("type") as! [String]))
        } catch {
            print(error)
        }
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

