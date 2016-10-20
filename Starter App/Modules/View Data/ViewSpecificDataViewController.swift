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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let healthObjTypeStr = healthObjectType else { return }
        
        let realm = try! Realm()
        realmNotification = realm.objects(HealthData.self).filter("type == %@", healthObjTypeStr).addNotificationBlock({ (notification) in
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
    
    //MARK: - Reload Data
    
    func reloadData() {
        guard let healthObjTypeStr = healthObjectType else { return }
        
        let realm = try! Realm()
        
        realmHealthObjects = realm.objects(HealthData.self).filter("type == %@", healthObjTypeStr)
        self.tableView.reloadData()
    }
    
    //MARK: - TableView Delegates
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = realmHealthObjects?.count {
            return count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath) as? HealthDataTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath)
        }
        
        guard let realmHealthObjects = realmHealthObjects else {
            cell.title.text = "Error"
            return cell
        }
        
        let healthObj = realmHealthObjects[(indexPath as NSIndexPath).item]
        let healthDataObjArr = healthObj.dataObjects
        
        //set data values string
        let dataValuesArr = healthDataObjArr.map { (dataObj) -> String in
            //assuming label and value will never be nil
            return dataObj.label! + ": " + dataObj.value!
        }
        
        let dataValuesStr = dataValuesArr.joined(separator: ",")
        
        cell.title.text = dataValuesStr
        
        //set date
        let date = healthObj.date
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.short
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: date)
        
        cell.subtitle.text = dateString
        
        return cell
    }
    
}
