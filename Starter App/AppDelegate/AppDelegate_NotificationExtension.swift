//
//  AppDelegate_ConfigureExtension.swift
//  Starter App
//
//  Created by ismails on 6/4/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit
import UIKit

extension AppDelegate {    
    func handleHKManagerNotifications(notification: NSNotification) {
        switch notification.name {
        case HealthKitManager.Notification.AuthorizationSuccess.rawValue:
            HealthKitSync.saveAllHKData_ToRealmAndServer()
            
        case HealthKitManager.Notification.AuthorizatonError.rawValue:
            let alert: UIAlertController = UIAlertController(title: "HealthKit Authorization Error", message: "There seems to be an issue with getting access to your HealthKit data. Please allow access to data in the \"Sources\" tab, inside the Health app.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))

            self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)

        default:
            break
        }
    }
}