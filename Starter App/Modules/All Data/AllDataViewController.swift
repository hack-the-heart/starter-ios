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

class AllDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedHealthObject: String?
    
    let healthObjects = [ String(Weight) ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DisplayHealthObjectData",
            let selectedHealthObject = self.selectedHealthObject,
            let viewController = segue.destinationViewController as? HealthObjectDataViewController {
            
            viewController.healthObjectType = selectedHealthObject
            
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthObjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCellWithIdentifier("DataCell", forIndexPath: indexPath)
        }
        
        cell.title.text = healthObjects[indexPath.item]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? HealthDataTableViewCell else { return }
        
        selectedHealthObject = cell.title.text
        self.performSegueWithIdentifier("DisplayHealthObjectData", sender: self)
    }
    
}

