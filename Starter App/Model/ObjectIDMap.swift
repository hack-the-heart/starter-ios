//
//  ObjectIDMap.swift
//  Starter App
//
//  Created by ismails on 6/5/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

class ObjectIDMap : Object {
    
    dynamic var realmID: String?
    dynamic var healthkitUUID: String?
    dynamic var serverUUID: String?
    
    // MARK: - Helper Functions
    // Nil values as method arguments does not override existing values.
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
    
    class func findUsingHealthkitUUID(healthkitUUID: String) -> ObjectIDMap? {
        let realm = try! Realm()
        let object = realm.objects(ObjectIDMap).filter("healthkitUUID == %@", healthkitUUID).first
        return object
    }
    
    class func findUsingServerUUID(serverUUID: String) -> ObjectIDMap? {
        let realm = try! Realm()
        let object = realm.objects(ObjectIDMap).filter("serverUUID == %@", serverUUID).first
        return object
    }
}