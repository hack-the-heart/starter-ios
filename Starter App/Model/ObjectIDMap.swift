//
//  ObjectIDMap.swift
//  Starter App
//
//  Created by ismails on 6/5/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

/// This Realm Object maps objects from three different sources: Local (Realm), HealthKit, and Server
/// When creating HealthObject, make sure to create a ObjectIDMap obj with the right IDs. 

/// For example, if the health data is coming from the server and we are storing it locally in realm
/// create an ObjectIDMap with the correct server and realm id's. This helps with syncing data between
/// all three sources. We can go through the list of objs in ObjectIDMap and see what ids are missing. 
/// With our previous example, the healthkit id was missing, therefore the health data will need to be stored
/// in HealthKit

class ObjectIDMap : Object {
    
    dynamic var realmID: String?
    dynamic var healthkitUUID: String?
    dynamic var serverUUID: String?
    
    // MARK: - Helper Functions
    
    /**
     Stores the realmID, healthKitUUID, and serverUUID. If an ID or some combination of the IDs already exist, then 
     that record will be updated. Nil values do not override existing values.
     
     - returns: returns an ObjectIDMap object
     */
    class func store(realmID realmID: String?, healthkitUUID: String?, serverUUID: String?) throws -> ObjectIDMap? {
        if realmID == nil && healthkitUUID == nil && serverUUID == nil {
            return nil
        }
        
        let realm = try! Realm()
        
        var objectMap = ObjectIDMap.findMapObject(realmID: realmID, healthkitUUID: healthkitUUID, serverUUID: serverUUID)
        
        if objectMap == nil {
            objectMap = ObjectIDMap()
            try realm.write {
                realm.add(objectMap!)
            }
        }
        
        try realm.write {
            if realmID != nil {
                objectMap?.realmID = realmID
            }
            
            if healthkitUUID != nil {
                objectMap?.healthkitUUID = healthkitUUID
            }
            
            if serverUUID != nil {
                objectMap?.serverUUID = serverUUID
            }
        }
        
        return objectMap!
    }
    
    /**
     Find the map object that matches ONE of these realmId, healthKidUUID, or serverUUID.
     
     - returns: returns an ObjectIDMap object
     */
    class func findMapObject(realmID realmID: String?, healthkitUUID: String?, serverUUID: String?) -> ObjectIDMap? {
        let realm = try! Realm()
        
        var predicateArr: [String] = []
        
        if let realmID = realmID {
            predicateArr.append(String(format: "realmID == '%@'", realmID))
        }
        
        if let healthkitUUID = healthkitUUID {
            predicateArr.append(String(format: "healthkitUUID == '%@'", healthkitUUID))
        }
        
        if let serverUUID = serverUUID {
            predicateArr.append(String(format: "serverUUID == '%@'", serverUUID))
        }
        
        let predicate = predicateArr.joinWithSeparator(" OR ")
        
        return realm.objects(ObjectIDMap).filter(predicate).first
    }
}