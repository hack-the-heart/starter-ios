//
//  HealthKitSync.swift
//  Starter App
//
//  Created by ismails on 6/4/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import RealmSwift

// MARK: HealthKit
/// Read/Write/Background Delivery Objects


//TODO-ADD-NEW-DATA-TYPE
//Add in the right objects for read/write/and background delivery permissions here.
//For example, if I wanted support for steps, I would add:
//  READ:
//      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
//
//  WRITE:
//      HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
//
//  BACKGROUND:
//      HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!



let readHKObjects = [
    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
]

let writeHKSamples = [
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
]

let backgroundDeliveryHKSamples = [
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
]

/// HealthKitSync pulls in data from HealthKit and stores it locally in realm
class HealthKitSync: NSObject {
    static let sharedInstance = HealthKitSync()
    
    /**
     Initializes the HealthKitManager.
     */
    override init() {
        super.init()
        
        // subscribe to any notifications from HealthKitManager
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(handleHKManagerNotifications(_:)), name: nil, object: HealthKitManager.sharedInstance)
        
        do {
            try HealthKitManager.sharedInstance.initializeHealthKitManager(sampleTypesForReadAuth: readHKObjects, sampleTypesForWriteAuth: writeHKSamples, sampleTypesForBackgroundDelivery: backgroundDeliveryHKSamples)
        } catch {
            //TODO: do something with this error
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - Notification Handlers
    func handleHKManagerNotifications(notification: NSNotification) {
        
        switch notification.name {
        case HealthKitManager.Notification.AuthorizationSuccess.rawValue:
            HealthKitSync.saveAllHKData_ToRealmAndServer()
            
        case HealthKitManager.Notification.AuthorizatonError.rawValue:
            let alert: UIAlertController = UIAlertController(title: "HealthKit Authorization Error", message: "There seems to be an issue with getting access to your HealthKit data. Please allow access to data in the \"Sources\" tab, inside the Health app.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            let appDelegate = UIApplication.sharedApplication().delegate
            appDelegate?.window??.rootViewController?.presentViewController(alert, animated: true, completion: nil)
            
        case HealthKitManager.Notification.BackgroundDeliveryResultSuccess.rawValue:
            guard let userInfo = notification.userInfo else { return }
            handleHKBackgroundUpdate(userInfo)
            
        default:
            break
        }
    }
    
    /**
     Handle background update notification and store data to realm and server.
     
     - parameter userInfo: nsnotification user info object
     */
    func handleHKBackgroundUpdate(userInfo: [NSObject: AnyObject]) {
        guard let typeIdentifier = userInfo[HealthKitManager.NotificationUserInfoKey.HKObjectTypeId.rawValue] as? String,
            hkObjectsDictionary = userInfo[HealthKitManager.NotificationUserInfoKey.HKObjects.rawValue] as? [[String: AnyObject]]
            else { return }
        
        // filter out results that are from our app. this is to avoid any duplicates.
        let filteredResults = hkObjectsDictionary.flatMap({ (hkObjectDict) -> [String: AnyObject]? in
            guard let sourceName = hkObjectDict[HKObjectKey.SourceName.rawValue] as? String else { return nil }
            
            if sourceName != HKSource.defaultSource().name { return hkObjectDict }
            
            return nil
        })
        
        //TODO-ADD-NEW-DATA-TYPE
        //Add support for handling the new data type on background update here.
        for result in filteredResults {
            switch typeIdentifier {
            case HKQuantityTypeIdentifierBodyMass:
                HealthKitSync.saveHKWeightData_ToRealmAndServer(result)
            case HKQuantityTypeIdentifierStepCount:
                HealthKitSync.saveHKStepData_ToRealmAndServer(result)
            default:
                break
            }
        }
    }
    
    // MARK: - CLASS FUNCTIONS
    // MARK: Save Realm Data to HK
    /**
     Saves realm data to healthkit.
     
     ideally you would like to store data back into HealthKit,
     but for the purposes of this hackathon and the starter app,
     we are only reading data from health kit, and saving it to
     our local realm db and the server.
     
     if we get data from the server, we only save it to local db.
     this method is stubbed out for future implementation
     
     - parameter realmID: id of realm object that needs to be stored in health kit
     
     - throws: some error
     */
    class func saveRealmData_ToHealthKit(withRealmID realmID: String) throws {
        //        let realm = try! Realm()
        //        guard let weightObj = realm.objects(Weight).filter("id == %@", realmID).first,
        //            let weightValue = weightObj.value.value,
        //            let startDate = weightObj.date else { return }
        //
        //        let quantity = HKQuantity(unit: HKUnit.poundUnit(), doubleValue: weightValue)
        //
        //        let bodyMass = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
        //
        //        let newSample = HKQuantitySample(type: bodyMass, quantity: quantity, startDate: startDate, endDate: startDate)
        //
        //        HealthKitManager.sharedInstance.hkHealthStore.saveObject(newSample) { (success, error) in
        //            if success == true {
        //                do {
        //                    try ObjectIDMap.store(realmID: realmID, healthkitUUID: newSample.UUID.UUIDString, serverUUID: nil)
        //                } catch {
        //                    //TODO: do something with this error
        //                }
        //            } else {
        //                //TODO: do something with this error
        //            }
        //        }
    }
    
    // MARK: Get All Data from HK
    /**
     Save all healthkit data to realm and server. This function is called after a successful authorization to sync all data from HealthKit and store it in Realm.
     
     Currently only weight data is synced but to sync more data add additional functions here.
     */
    class func saveAllHKData_ToRealmAndServer() {
        saveAllHKWeightData_ToRealmAndServer()
        
        //TODO-ADD-NEW-DATA-TYPE
        //Call the function that queries for new data and stores it on the server and locally
        
        saveAllHKStepData_ToRealmAndServer()
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
    
    //TODO-ADD-NEW-DATA-TYPE
    //Add a new function to support querying for all data and storing it locally and the server
    
    private class func saveAllHKStepData_ToRealmAndServer() {
        let stepSampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
        
        HealthKitManager.sharedInstance.queryForSampleType(stepSampleType, afterDate: nil, beforeDate: nil, limit: -1, sortDateAscending: false) { (sampleQuery, sampleArr, error) in
            
            guard let results = sampleArr else { return }
            
            for result in results {
                self.saveHKStepData_ToRealmAndServer(result.toDictionary())
            }
        }
    }
    
    // MARK: Save HK Data to Realm
    /**
     Save a specific health kit weight object to realm
     
     - parameter hkObject: health kit object represented as a dictionary
     */
    private class func saveHKWeightData_ToRealmAndServer(hkObject: [String:AnyObject]) {
        let sourceName = hkObject[HKObjectKey.SourceName.rawValue] as! String
        
        let weightValue = hkObject[HKObjectKey.Value.rawValue] as! Double
        let date = hkObject[HKObjectKey.Date.rawValue] as! NSDate
        
        let healthkitUUID = hkObject[HKObjectKey.HealthKitUUID.rawValue] as! String
        
        do {
            
            //            if let mapObject = ObjectIDMap.findMapObject(realmID: nil, healthkitUUID: healthkitUUID, serverUUID: nil) where mapObject.realmID != nil {
            //                //dont do anything if object already exists
            //            } else {
            
            if let _ = HealthData.find(usingDate: date) {
                //dont do anything if object already exists
            } else {
                
                //save to realm
                let healthObjType = HealthDataType.Weight
                let weightHealthObj = try HealthData.saveToRealmIfNeeded(healthObjType.rawValue, date: date, source: sourceName, origin:.HealthKit)
                let _ = try HealthDataValue.saveToRealm("value", value: String(weightValue), healthObj: weightHealthObj)
                
                //                try ObjectIDMap.store(realmID: weightHealthObj.id, healthkitUUID: healthkitUUID, serverUUID: nil)
                
                ServerSync.sharedInstance.uploadData_ToServer(withRealmID: weightHealthObj.id)
            }
        } catch {
            print("error saving weight data to realm")
        }
    }
    
    
    //TODO-ADD-NEW-DATA-TYPE
    //Add a function to support storing healthkit data onto realm and server
    private class func saveHKStepData_ToRealmAndServer(hkObject: [String:AnyObject]) {
        let sourceName = hkObject[HKObjectKey.SourceName.rawValue] as! String
        
        let stepValue = hkObject[HKObjectKey.Value.rawValue] as! Double
        let date = hkObject[HKObjectKey.Date.rawValue] as! NSDate
        
        let healthkitUUID = hkObject[HKObjectKey.HealthKitUUID.rawValue] as! String
        
        do {
            
            //            if let mapObject = ObjectIDMap.findMapObject(realmID: nil, healthkitUUID: healthkitUUID, serverUUID: nil) where mapObject.realmID != nil {
            //                //dont do anything if object already exists
            //            } else {
            if let _ = HealthData.find(usingDate: date) {
                //dont do anything if object already exists
            } else {
                //save to realm
                let healthObjType = HealthDataType.Step
                let stepHealthObj = try HealthData.saveToRealmIfNeeded(healthObjType.rawValue, date: date, source: sourceName, origin:.HealthKit)
//                let weightHealthObj = try HealthData.saveToRealm(healthObjType.rawValue, date: date, source: sourceName)
                let _ = try HealthDataValue.saveToRealm("value", value: String(stepValue), healthObj: stepHealthObj)
                
//                try ObjectIDMap.store(realmID: weightHealthObj.id, healthkitUUID: healthkitUUID, serverUUID: nil)
                
                ServerSync.sharedInstance.uploadData_ToServer(withRealmID: stepHealthObj.id)
            }
        } catch {
            print("error saving weight data to realm")
        }
        
    }
    
}