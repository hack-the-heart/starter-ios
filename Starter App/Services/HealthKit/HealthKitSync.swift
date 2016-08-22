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
    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
]

let writeHKSamples = [
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
]

let backgroundDeliveryHKSamples = [
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureSystolic)!,
    HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBloodPressureDiastolic)!,
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
            hkObjectsDictionary = userInfo[HealthKitManager.NotificationUserInfoKey.HKObjects.rawValue] as? [HKSample] //as? [[String: AnyObject]]
            else { return }
        
        // filter out results that are from our app. this is to avoid any duplicates.
        let filteredResults = hkObjectsDictionary.flatMap({ (hkObject) -> HKSample? in
            //guard let sourceName =  hkObject.sourceRevision.source.name else { return nil }
            //[HKObjectKey.SourceName.rawValue] as? String else { return nil }
            
            if hkObject.sourceRevision.source.name != HKSource.defaultSource().name { return hkObject }
            
            return nil
        })
        
        //TODO-ADD-NEW-DATA-TYPE
        //Add support for handling the new health kit object type on background update here.
        for result in filteredResults {
            if let quantitySample = result as? HKQuantitySample {
                HealthKitSync.saveHKQuantitySample_ToRealmAndServer(quantitySample)
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
        for hkIdentifier in readHKObjects {
            
            HealthKitManager.sharedInstance.queryForSampleType(hkIdentifier, afterDate: nil, beforeDate: nil, limit: -1, sortDateAscending: false) { (sampleQuery, sampleArr, error) in
                
                guard let results = sampleArr else { return }
                
                for result in results {
                    
                    //TODO-ADD-NEW-DATA-TYPE
                    //Add support for handling the new data type initial query here
                    
                    if let quantitySample = result as? HKQuantitySample {
                        self.saveHKQuantitySample_ToRealmAndServer(quantitySample)
                    }
                }
                
            }
            
        }
    }
    
    private class func saveHKQuantitySample_ToRealmAndServer(quantitySample: HKQuantitySample) {
        let date = quantitySample.startDate
        let _ = quantitySample.UUID.UUIDString
        let sourceName = quantitySample.sourceRevision.source.name
        
        var quantitySampleValue: Double?
        var dataValueName = "value"
        
        //TODO-ADD-NEW-DATA-TYPE
        //add in support for different quantity samples
        switch quantitySample.sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            quantitySampleValue = quantitySample.quantity.doubleValueForUnit(HKUnit.poundUnit())
        case HKQuantityTypeIdentifierStepCount:
            quantitySampleValue = quantitySample.quantity.doubleValueForUnit(HKUnit.countUnit())
        case HKQuantityTypeIdentifierBloodPressureSystolic:
            dataValueName = "systolic-value"
            quantitySampleValue = quantitySample.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
        case HKQuantityTypeIdentifierBloodPressureDiastolic:
            dataValueName = "diastolic-value"
            quantitySampleValue = quantitySample.quantity.doubleValueForUnit(HKUnit.millimeterOfMercuryUnit())
        default:
            break
        }
        
        guard let value = quantitySampleValue, let shortString = healthKitShortString[quantitySample.sampleType.identifier]?.rawValue else {
            print("Error storing Quantity Sample from health kit. Could not find value in quantity sample object or short string for quantity sample type")
            return
        }
        
        do {
            if let healthDataObj = HealthData.find(usingDate: date)   {
                let objs = healthDataObj.dataObjects.filter({ (healthDataValue) -> Bool in
                    return healthDataValue.label == dataValueName && healthDataValue.value == String(value)
                })
                
                if(objs.count > 0) {
                    return
                }
                
            }
            
            //save to realm
            let healthObj = try HealthData.saveToRealm(shortString, date: date, source: sourceName, origin:.HealthKit)
            let _ = try HealthDataValue.saveToRealm(dataValueName, value: String(value), healthObj: healthObj)
            
            ServerSync.sharedInstance.uploadData_ToServer(withRealmID: healthObj.id)
            
        } catch {
            print("error saving weight data to realm")
        }
    }
    
}