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
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!,
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!,
    HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.respiratoryRate)!,
]

let writeHKSamples = [
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.respiratoryRate)!,
]

let backgroundDeliveryHKSamples = [
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.oxygenSaturation)!,
    HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.respiratoryRate)!,
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleHKManagerNotifications(_:)), name: nil, object: HealthKitManager.sharedInstance)
        
        do {
            try HealthKitManager.sharedInstance.initializeHealthKitManager(sampleTypesForReadAuth: readHKObjects, sampleTypesForWriteAuth: writeHKSamples, sampleTypesForBackgroundDelivery: backgroundDeliveryHKSamples)
        } catch {
            //TODO: do something with this error
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Notification Handlers
    func handleHKManagerNotifications(_ notification: Foundation.Notification) {
        
        switch notification.name.rawValue {
        case HealthKitManager.Notification.AuthorizationSuccess.rawValue:
            HealthKitSync.saveAllHKData_ToRealmAndServer()
            
        case HealthKitManager.Notification.AuthorizatonError.rawValue:
            let alert: UIAlertController = UIAlertController(title: "HealthKit Authorization Error", message: "There seems to be an issue with getting access to your HealthKit data. Please allow access to data in the \"Sources\" tab, inside the Health app.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            let appDelegate = UIApplication.shared.delegate
            appDelegate?.window??.rootViewController?.present(alert, animated: true, completion: nil)
            
        case HealthKitManager.Notification.BackgroundDeliveryResultSuccess.rawValue:
            guard let userInfo = (notification as NSNotification).userInfo else { return }
            handleHKBackgroundUpdate(userInfo)
            
        default:
            break
        }
    }
    
    /**
     Handle background update notification and store data to realm and server.
     
     - parameter userInfo: nsnotification user info object
     */
    func handleHKBackgroundUpdate(_ userInfo: [AnyHashable: Any]) {
        guard let _ = userInfo[HealthKitManager.NotificationUserInfoKey.HKObjectTypeId.rawValue] as? String,
            let hkObjectsDictionary = userInfo[HealthKitManager.NotificationUserInfoKey.HKObjects.rawValue] as? [HKSample] //as? [[String: AnyObject]]
            else { return }
        
        // filter out results that are from our app. this is to avoid any duplicates.
        let filteredResults = hkObjectsDictionary.flatMap({ (hkObject) -> HKSample? in
            //guard let sourceName =  hkObject.sourceRevision.source.name else { return nil }
            //[HKObjectKey.SourceName.rawValue] as? String else { return nil }
            
            if hkObject.sourceRevision.source.name != HKSource.default().name { return hkObject }
            
            return nil
        })
        
        //TODO-ADD-NEW-DATA-TYPE-CATEGORY-SUPPORT
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
                    
                    //TODO-ADD-NEW-DATA-TYPE-CATEGORY-SUPPORT
                    //Add support for handling the new data type initial query here
                    
                    if let quantitySample = result as? HKQuantitySample {
                        self.saveHKQuantitySample_ToRealmAndServer(quantitySample)
                    }
                }
                
            }
            
        }
    }
    
    fileprivate class func saveHKQuantitySample_ToRealmAndServer(_ quantitySample: HKQuantitySample) {
        let date = quantitySample.startDate
        let _ = quantitySample.uuid.uuidString
        let sourceName = quantitySample.sourceRevision.source.name
        
        var quantitySampleValue: Double?
        var dataValueName = "value"
        
        //TODO-ADD-NEW-DATA-TYPE
        //add in support for different quantity samples
        switch quantitySample.sampleType.identifier {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.pound())
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.count())
        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
            dataValueName = "systolic-value"
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
        case HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
        case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.percent())
        case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
            quantitySampleValue = quantitySample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.second()))
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
