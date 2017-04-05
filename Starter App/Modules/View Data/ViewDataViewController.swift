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
    var selectedHealthData: String?
    
    //container to store HealthDatas. Used for UITableView
    var healthObjects: [String] = []
    
    /// realm notification to monitor any changes/additions to the realm obj: "HealthData"
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let realm = try! Realm()
        realmNotification = realm.objects(HealthData.self).addNotificationBlock({ (notification) in
            self.reloadData()
        })
        
        reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayHealthObjectData",
            let selectedHealthData = self.selectedHealthData,
            let viewController = segue.destination as? ViewSpecificDataViewController {
            
            viewController.healthObjectType = selectedHealthData
            
        }
    }
    
    //MARK: - Load Data
    
    func reloadData() {
        let realm = try! Realm()
        healthObjects = Array(Set(realm.objects(HealthData.self).value(forKey: "type") as! [String]))
        
        self.tableView.reloadData()
    }
    
    //MARK: - TableView Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath)
        }
        
        cell.title.text = healthObjects[(indexPath as NSIndexPath).item]
        cell.subtitle.text = ""
        cell.healthObjType = healthObjects[(indexPath as NSIndexPath).item]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? HealthDataTableViewCell else { return }
        
        selectedHealthData = cell.healthObjType
        self.performSegue(withIdentifier: "DisplayHealthObjectData", sender: self)
    }
    
}

