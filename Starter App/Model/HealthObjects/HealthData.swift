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
    
    dynamic var id: String = ""
    
    dynamic var source: String = "" {
        didSet {
            id = compoundIdValue()
        }
    }
    
    dynamic var date: Date = Date() {
        didSet {
            id = compoundIdValue()
        }
    }
    
    dynamic var type: String = "" {
        didSet {
            id = compoundIdValue()
        }
    }
    
    dynamic var participantId: String = "" {
        didSet {
            id = compoundIdValue()
        }
    }
    
    dynamic var sessionId: String?
    
    /**
     Realm specific property to pull in all HealthDataValue objects that have self as the healthObject.
     */
    let dataObjects = LinkingObjects(fromType: HealthDataValue.self, property: "healthObject")
    
    open override static func primaryKey() -> String? {
        return "id"
    }
    
    fileprivate func compoundIdValue() -> String {
        return HealthData.generateCompoundId(date: date, participantId: participantId, source: source, type: type)
    }
    
    // class functions
    
    class func saveToRealm(_ type: String, date: Date, source: String, participantId: String, sessionId: String?, overrideExisting: Bool = false) throws -> HealthData  {
        let realm = try! Realm()
        
        let compoundId = HealthData.generateCompoundId(date: date, participantId: participantId, source: source, type: type)
        
        if let healthDataObj = HealthData.find(id: compoundId) {
            if overrideExisting {
                try realm.write {
                    realm.delete(healthDataObj.dataObjects)
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
    
    class func find(id: String) -> HealthData? {
        let realm = try! Realm()
        
        let objects = realm.objects(HealthData.self).filter("id == %@", id)
        
        if objects.count == 0 {
            return nil
        }
        
        return objects[0]
    }
    
    class func generateCompoundId(date: Date, participantId: String, source: String, type: String) -> String {
        let timestamp = String(describing: date.timeIntervalSince1970)
        return HealthData.generateCompoundId(timestamp: timestamp, participantId: participantId, source: source, type: type)
    }
    
    class func generateCompoundId(timestamp: String, participantId: String, source: String, type: String) -> String {
        let id = timestamp + participantId + source + type
        return id
    }
}
