//
//  HealthData.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

enum HealthOrigin: String {
    case HealthKit = "healthkit"
    case SelfReported = "self-reported"
    case Server = "server"
    case CSV = "csv"
}

/// A HealthData that contains generic information such as type, source, date, and etc. Health specific data is not stored here. See HealthDataValue.
class HealthData: Object {
    
    dynamic var id: String = NSUUID().UUIDString
    dynamic var source: String?
    dynamic var origin: String?
    dynamic var date: NSDate?
    dynamic var type: String?
    
    /**
     Realm specific property to pull in all HealthDataValue objects that have self as the healthObject.
     */
    let dataObjects = LinkingObjects(fromType: HealthDataValue.self, property: "healthObject")
    
    class func saveToRealm(type: String, date: NSDate, source: String, origin: HealthOrigin, overrideExisting: Bool = false) throws -> HealthData  {
        let realm = try! Realm()
        
        if let healthDataObj = HealthData.find(usingDate: date) {
            if overrideExisting {
                try realm.write {
                    realm.delete(healthDataObj)
                }                
            } else {
                return healthDataObj
            }
        }
        
        let healthObj = HealthData()
        healthObj.type = type
        healthObj.date = date
        healthObj.source = source
        healthObj.origin = origin.rawValue
        
        try realm.write {
            realm.add(healthObj)
        }
        
        return healthObj
    }
    
    class func find(usingSecondsSince1970 seconds: NSTimeInterval) -> HealthData? {
        return find(usingDate: NSDate(timeIntervalSince1970: seconds))
    }
    
    class func find(usingDate date: NSDate) -> HealthData? {
        let realm = try! Realm()
        
        let objects = realm.objects(HealthData).filter("date == %@", date)
        
        if objects.count == 0 {
            return nil
        }
        
        return objects[0]
    }
    
    
}