//
//  HealthData.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

/// An object that represents a single piece of health data. Each HealthDataValue obj is connected to a HealthObj.
class HealthDataValue: Object {
    
    dynamic var healthObject: HealthData?
    dynamic var label: String?
    dynamic var value: String?
    
    class func saveToRealm(label: String, value: String, healthObj: HealthData) throws -> HealthDataValue  {
        let realm = try! Realm()
        
        let healthDataObj = HealthDataValue()
        healthDataObj.label = label
        healthDataObj.value = value
        healthDataObj.healthObject = healthObj
        
        try realm.write {
            realm.add(healthDataObj)
        }
        
        return healthDataObj
    }
}