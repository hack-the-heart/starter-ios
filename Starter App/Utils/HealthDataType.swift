//
//  Constants.swift
//  Starter App
//
//  Created by ismails on 8/22/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit

//TODO-ADD-NEW-DATA-TYPE
//add in a string for a new datatype here
//this is used for the HealthData

//// rawValues must be in lowercase
enum HealthDataType: String {
    case Weight = "weight"
    case Step = "step"
    case BloodPressure = "blood-pressure"
    case OxygenSaturation = "oxygen-saturation"
    case RespiratoryRate = "respiratory-rate"
}

//TODO-ADD-NEW-DATA-TYPE
// add in support for handling new short strings here
let healthKitShortString: [String: HealthDataType] = [
    HKQuantityTypeIdentifier.bodyMass.rawValue: HealthDataType.Weight,
    HKQuantityTypeIdentifier.stepCount.rawValue: HealthDataType.Step,
    
    HKCorrelationTypeIdentifier.bloodPressure.rawValue: HealthDataType.BloodPressure,
    HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue: HealthDataType.BloodPressure,
    HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue: HealthDataType.BloodPressure,
    HKQuantityTypeIdentifier.oxygenSaturation.rawValue: HealthDataType.OxygenSaturation,
    HKQuantityTypeIdentifier.respiratoryRate.rawValue: HealthDataType.RespiratoryRate,
]
