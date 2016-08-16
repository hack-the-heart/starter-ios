//
//  HealthObject.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

// rawValues must be in lowercase
enum HealthObjectType: String {
    case Weight = "weight"
}

/// A HealthObject that contains generic information such as type, source, date, and etc. Health specific data is not stored here. See HealthData.
class HealthObject: Object {
    
    dynamic var id: String = NSUUID().UUIDString
    dynamic var source: String?
    dynamic var date: NSDate?
    dynamic var type: String?
    
    /**
     Realm specific property to pull in all HealthData objects that have self as the healthObject.
     */
    let dataObjects = LinkingObjects(fromType: HealthData.self, property: "healthObject")
    
    class func saveToRealm(typeStr: String, date: NSDate, source: String) throws -> HealthObject  {
        let realm = try! Realm()
        
        let healthObj = HealthObject()
        healthObj.type = typeStr
        healthObj.date = date
        healthObj.source = source
        
        try realm.write {
            realm.add(healthObj)
        }
        
        return healthObj
    }
}