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

class HealthObject: Object {
    
    dynamic var id: String = NSUUID().UUIDString
    dynamic var source: String?
    dynamic var date: NSDate?
    dynamic var type: String?
    
    let dataObjects = LinkingObjects(fromType: HealthData.self, property: "healthObject")
    
    class func saveToRealm(type: HealthObjectType, date: NSDate, source: String) throws -> HealthObject  {
        let realm = try! Realm()
        
        let healthObj = HealthObject()
        healthObj.type = type.rawValue
        healthObj.date = date
        healthObj.source = source
        
        try realm.write {
            realm.add(healthObj)
        }
        
        return healthObj
    }
}