//
//  HealthData.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

/// A HealthData that contains generic information such as type, source, date, and etc. Health specific data is not stored here. See HealthDataValue.
class HealthData: Object {
    
    dynamic var id: String = UUID().uuidString
    dynamic var source: String?
    dynamic var date: Date?
    dynamic var type: String?
    
    dynamic var participantId: String?
    dynamic var sessionId: String?
    //    dynamic var origin: String?
    
    /**
     Realm specific property to pull in all HealthDataValue objects that have self as the healthObject.
     */
    let dataObjects = LinkingObjects(fromType: HealthDataValue.self, property: "healthObject")
    
    class func saveToRealm(_ type: String, date: Date, source: String, participantId: String, sessionId: String, overrideExisting: Bool = false) throws -> HealthData  {
        let realm = try! Realm()
        
        if let healthDataObj = HealthData.find(usingDate: date, andType: type) {
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
        healthObj.participantId = participantId
        healthObj.sessionId = sessionId
        
        try realm.write {
            realm.add(healthObj)
        }
        
        return healthObj
    }
    
    class func find(usingSecondsSince1970 seconds: TimeInterval, andType type: String) -> HealthData? {
        return find(usingDate: Date(timeIntervalSince1970: seconds), andType: type)
    }
    
    class func find(usingDate date: Date, andType type: String) -> HealthData? {
        let realm = try! Realm()
        
        let objects = realm.objects(HealthData.self).filter("date == %@ AND type == %@", date, type)
        
        if objects.count == 0 {
            return nil
        }
        
        return objects[0]
    }
    
    
}
