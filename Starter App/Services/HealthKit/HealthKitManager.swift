//
//  HealthKitManager.swift
//  Starter App
//
//  Created by ismails on 5/27/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit

//T1ODO-ADD-NEW-DATA-TYPE
//Add in a key for the values inside a HKObject
//This is used to parse the values out of the HK Object and store it in a dictionary
enum HKObjectKey: String {
    case Date = "date"
    case SourceName = "sourceName"
    case HealthKitUUID = "healthkitUUID"
    case Value = "value"
}

/// Manages HealthKit authorization, querying, storing, etc.
class HealthKitManager {
    /// Shared Instance - This class is a singleton. You must use this instance to interact with HealthKitManager.
    static let sharedInstance = HealthKitManager()
    
    // MARK: - Properties
    var didConfigureHKAuth: Bool {
        get {
            let prefs = UserDefaults.standard
            return prefs.bool(forKey: "didConfigureHKAuth")
        }
        set {
            let prefs = UserDefaults.standard
            prefs.set(newValue, forKey: "didConfigureHKAuth")
        }
    }
    
    fileprivate var readAuthArr: [HKObjectType] = []
    fileprivate var writeAuthArr: [HKSampleType] = []
    fileprivate var backgroundDeliveryArr: [HKSampleType] = []
    
    let hkHealthStore = HKHealthStore()
    
    // MARK: - Closures
    
    // MARK: - Notifications
    /**
     Keys for Items in User Info Dictionary in NSNotification
     
     - ErrorObj: the NSError object
     */
    enum NotificationUserInfoKey: String {
        case ErrorObj = "ErrorObj"
        case HKObjects = "HKObjects"
        case HKObjectTypeId = "HKObjectType"
    }
    
    /**
     Names of NSNotifications that are published
     
     - AuthorizationSuccess: notification for when authorization was  successfull
     - AuthorizatonError:    notification for when authorization failed
     */
    enum Notification: String {
        case AuthorizationSuccess = "AuthSuccess"
        case AuthorizatonError = "AuthError"
        case BackgroundDeliveryError = "BackgroundDeliveryError"
        case BackgroundDeliveryResultError = "BackgroundDeliveryResultError"
        case BackgroundDeliveryResultSuccess = "BackgroundDeliveryResultSuccess"
    }
    
    // MARK: - Errors
    enum HKAuthorizationError: Error {
        case alreadyConfigured
        case healthDataUnavailable
    }
    
    // MARK: - Configure
    func initializeHealthKitManager(sampleTypesForReadAuth readArr: [HKObjectType],
                                                           sampleTypesForWriteAuth writeArr: [HKSampleType],
                                                                                   sampleTypesForBackgroundDelivery backgroundDeliveryArr: [HKSampleType]) throws {
        
        self.readAuthArr = readArr
        self.writeAuthArr = writeArr
        self.backgroundDeliveryArr = backgroundDeliveryArr
        
        // if we have already asked for health kit authorization, then enable background delivery
        // if not, then request for authorization. in the notification of a successful auth,
        // then we enable background delivery
        if HealthKitManager.sharedInstance.didConfigureHKAuth {
            HealthKitManager.sharedInstance.enableBackgroundDelivery(self.backgroundDeliveryArr)
        } else {
            try HealthKitManager.sharedInstance.requestHKAuthorization(sampleTypesForReadAuth: Set(self.readAuthArr), sampleTypesForWriteAuth: Set(self.writeAuthArr))
        }
    }
    
    // MARK: - Initial Setup/Config
    /**
     Requests HealthKit authorization based on the readSet and writeSet that are passed.
     This function will not attempt to authorize if it has already authorized once or if
     health data is not available on the device.
     
     An NSNotification will be sent out based on the status of the authorization.
     
     - parameter readSet:  objects that requesting for read access
     - parameter writeSet: objects that requesting for write access
     
     - throws: an HKAuthorizationError
     */
    func requestHKAuthorization(sampleTypesForReadAuth readSet: Set<HKObjectType>,
                                                       sampleTypesForWriteAuth writeSet: Set<HKSampleType>) throws {
        defer {
            didConfigureHKAuth = true
        }
        
        // If user already configured HealthKit access then do not configure again.
        // Apple only allows configuration once (CONFIRM). After the first configuration,
        // the user can update the app's health kit access settings in the Apple Health App
        guard didConfigureHKAuth == false else {
            throw HKAuthorizationError.alreadyConfigured
        }
        
        // Not all devices support HealthKit (e.g. iPad). Check to see if health data is
        // available in the first place.
        guard HKHealthStore.isHealthDataAvailable() == true else {
            throw HKAuthorizationError.healthDataUnavailable
        }
        
        hkHealthStore.requestAuthorization(toShare: writeSet, read: readSet) { (success, error) in
            if success {
                // We successfully asked for HealthKit Authorization. Send out the notification and enable background delivery.
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.AuthorizationSuccess.rawValue), object: HealthKitManager.sharedInstance, userInfo: nil)
                })
                
                self.enableBackgroundDelivery(self.backgroundDeliveryArr)
                
                return
            }
            
            // Something went wrong while asking HealthKit for authorization. This does not
            // indicate whether or not we were granted authorization to read/write data from HealthKit.
            
            var userInfo: [AnyHashable: Any] = [:]
            if let errorObj = error {
                userInfo[NotificationUserInfoKey.ErrorObj.rawValue] = errorObj
            }
            
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.AuthorizatonError.rawValue), object: HealthKitManager.sharedInstance, userInfo: userInfo)
            })
        }
        
    }
    
    // MARK: - Query for Data
    /**
     Query for objects in HealthKit.
     
     - parameter sampleType:          the type of the HealthKit object
     - parameter afterDate:           filter the query by after a certain date
     - parameter beforeDate:          filter the query by before a certain date
     - parameter limit:               limit the number of items retireved from HealthKit
     - parameter sortDateAscending:   sort by date (ascending)
     - parameter queryResultsHandler: handler for when results are returned from the query
     */
    func queryForSampleType(_ sampleType: HKSampleType, afterDate: Date?, beforeDate: Date?, limit: Int, sortDateAscending: Bool, queryResultsHandler: @escaping (HKSampleQuery, [HKSample]?, NSError?) -> Void)
    {
        var predicate: NSPredicate?
        
        if(afterDate != nil && beforeDate != nil) {
            predicate = NSPredicate(format: "(startDate >= %@) and (startDate < %@)", afterDate! as CVarArg, beforeDate! as CVarArg)
        } else if(afterDate != nil) {
            predicate = NSPredicate(format: "(startDate >= %@)", afterDate! as CVarArg)
        } else if(beforeDate != nil) {
            predicate = NSPredicate(format: "(startDate < %@)", beforeDate! as CVarArg)
        }
        
        let sortDescriptors = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: sortDateAscending)
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptors], resultsHandler: backgroundQueryResultHandler)
        
        self.hkHealthStore.execute(query)
    }
    
    // MARK: - Background Delivery
    /**
     Enable background delivery for HealthKit. This registers the application for updates
     to HealthKit obects in the background.
     
     When we get the notification stating that there have been updates, we will need to query for
     the latest objects. This query searches for any new objects in the past hour. An NSNotification will
     then be posted with an array of the objects updated in the last hour.
     
     The class that is listening to the NSNotification must iterate through the array of objects and compare it
     with the objects saved locally to find the new objects (reword)
     
     - parameter sampleTypesArr:  objects that need to be registered for background delivery
     - parameter updateFrequency: the update frequency of the background delivery (defaults to .Immediate)
     */
    func enableBackgroundDelivery(_ sampleTypesArr: [HKSampleType], updateFrequency: HKUpdateFrequency = .immediate) {
        for sampleType in sampleTypesArr {
            self.hkHealthStore.enableBackgroundDelivery(for: sampleType, frequency: updateFrequency) { (success, error) -> Void in
                if success {
                    let hourAgo = Date(timeIntervalSinceNow: -3600)
                    let pred = NSPredicate(format: "startDate > %@", hourAgo as CVarArg)
                    let query = HKObserverQuery(sampleType: sampleType, predicate: pred, updateHandler: self.backgroundQueryHandler)
                    
                    self.hkHealthStore.execute(query)
                    
                    print("Enabled background delivery for \t\(sampleType.description)")
                } else {
                    print("Error enabling background delivery for \(sampleType.description). Error: \(error?.localizedDescription ?? "none")")
                }
            }
        }
    }
    
    /**
     Handler for background delivery update. When we get a notification stating that something has updated,
     we will need to query for it. The handler for this query is located at backgroundQueryResultsHandler.
     
     - parameter query:             the query that the background delivery was triggered on
     - parameter completionHandler: the completion handler of the background delivery query
     - parameter error:             the error returned by the background delivery query
     */
    func backgroundQueryHandler(_ query: HKObserverQuery, completionHandler: HKObserverQueryCompletionHandler, error : Error?) {
        guard error == nil else {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.BackgroundDeliveryError.rawValue), object: HealthKitManager.sharedInstance, userInfo: [NotificationUserInfoKey.ErrorObj.rawValue: error!])
            })
            
            return
        }
        
        guard let sampleType = query.objectType as? HKSampleType else {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.BackgroundDeliveryError.rawValue), object: HealthKitManager.sharedInstance, userInfo: nil)
            })
            
            return
        }
        
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: query.predicate, limit: 100, sortDescriptors: sort, resultsHandler: self.backgroundQueryResultHandler)
        
        self.hkHealthStore.execute(sampleQuery)
        
        //must call when subscribing to background updates
        completionHandler()
    }
    
    /**
     Handler for the query made inside backgroundQueryHandler.
     
     - parameter query:   the query that the handler is responding to
     - parameter results: the results from the query that was just executed
     - parameter error:   an error returned by the sample query
     */
    func backgroundQueryResultHandler(_ query: HKSampleQuery, results: [HKSample]?, error: Error?) {
        guard error == nil else {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.BackgroundDeliveryResultError.rawValue), object: HealthKitManager.sharedInstance, userInfo: [NotificationUserInfoKey.ErrorObj.rawValue: error!])
            })
            
            return
        }
        
        guard let sampleResults = results , sampleResults.count != 0 else {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.BackgroundDeliveryResultError.rawValue), object: HealthKitManager.sharedInstance, userInfo: nil)
            })
            
            return
        }
        
        //let sampleResultsDict = sampleResults.map { $0.toDictionary() }
        let typeIdentifier = query.objectType?.identifier
        
        let userInfo: [String: AnyObject] = [
            NotificationUserInfoKey.HKObjectTypeId.rawValue: typeIdentifier != nil ? typeIdentifier! as AnyObject : "Unknown" as AnyObject,
            NotificationUserInfoKey.HKObjects.rawValue: sampleResults as AnyObject]
        
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: Notification.BackgroundDeliveryResultSuccess.rawValue), object: HealthKitManager.sharedInstance, userInfo: userInfo)
        })
    }
}
