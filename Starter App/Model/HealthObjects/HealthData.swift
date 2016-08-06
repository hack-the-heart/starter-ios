//
//  HealthObject.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

class HealthData: Object {
    
    dynamic var healthObject: HealthObject?
    dynamic var label: String?
    dynamic var value: String?
    
    class func saveToRealm(label: String, value: String, healthObj: HealthObject) throws -> HealthData  {
        let realm = try! Realm()
        
        let healthDataObj = HealthData()
        healthDataObj.label = label
        healthDataObj.value = value
        healthDataObj.healthObject = healthObj
        
        try realm.write {
            realm.add(healthDataObj)
        }
        
        return healthDataObj
    }
}