//
//  HealthKitSync.swift
//  Starter App
//
//  Created by ismails on 6/4/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit
import RealmSwift

class HealthKitSync {
    
    // MARK: - Save Realm Data to HK
    class func saveWeightData_ToHealthKit(withRealmID realmID: String) throws {
        let realm = try! Realm()
        guard let weightObj = realm.objects(Weight).filter("id == %@", realmID).first,
            let weightValue = weightObj.value.value,
            let startDate = weightObj.date else { return }
        
        let quantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: weightValue)
        
        let bodyMass = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
        
        let newSample = HKQuantitySample(type: bodyMass, quantity: quantity, startDate: startDate, endDate: startDate)
        
        HealthKitManager.sharedInstance.hkHealthStore.saveObject(newSample) { (success, error) in
            if success == true {
                do {
                   try ObjectIDMap.store(realmID: realmID, healthkitUUID: newSample.UUID.UUIDString, serverUUID: nil)
                } catch {
                    //TODO: do something with this error
                }
            } else {
                //TODO: do something with this error
            }
        }
    }
    
    // MARK: - Get All Data from HK
    class func saveAllHKData_ToRealmAndServer() {
        saveAllHKWeightData_ToRealmAndServer()
    }
    
    /**
     Get Weight data.  Read in all data from eternity and add it to local Realm DB
     */
    private class func saveAllHKWeightData_ToRealmAndServer() {
        let weightSampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
        
        HealthKitManager.sharedInstance.queryForSampleType(weightSampleType, afterDate: nil, beforeDate: nil, limit: -1, sortDateAscending: false) { (sampleQuery, sampleArr, error) in
            
            guard let results = sampleArr else { return }
            
            for result in results {
                self.saveHKWeightData_ToRealmAndServer(result.toDictionary())
            }
        }
    }
    
    // MARK: - Save HK Data to Realm
    private class func saveHKWeightData_ToRealmAndServer(hkObject: [String:AnyObject]) {
        let sourceName = hkObject[HKObjectKey.SourceName.rawValue] as! String
        
        let weightValue = hkObject[HKObjectKey.WeightValue.rawValue] as! Double
        let date = hkObject[HKObjectKey.Date.rawValue] as! NSDate
        
        let healthkitUUID = hkObject[HKObjectKey.HealthKitUUID.rawValue] as! String
        
        do {
            
            if let _ = ObjectIDMap.findMapObject(realmID: nil, healthkitUUID: healthkitUUID, serverUUID: nil) {
                //dont do anything if object already exists
            } else {
                //save to realm
                guard let realmObj = try Weight.saveToRealm(weightValue: weightValue, date: date, sourceName: sourceName) else { return }
                
                try ObjectIDMap.store(realmID: realmObj.id, healthkitUUID: healthkitUUID, serverUUID: nil)
                
                ServerSync.uploadData_ToServer(withRealmID: realmObj.id)
            }
        } catch {
            print("error saving weight data to realm")
        }
    }
}