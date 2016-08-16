//
//  HKSampleExtension.swift
//  Starter App
//
//  Created by ismails on 5/27/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import HealthKit

extension HKSample {
    /**
     Converts an HKSample to a dictionary. Currently this only handles Weight data (HKQuantityTypeIdentifierBodyMass).
     
     - returns: <#return value description#>
     */
    func toDictionary() -> [String: AnyObject] {
        let date = self.startDate
        let healthkit_uuid = self.UUID.UUIDString
        let sourceName = self.sourceRevision.source.name
        
        var resultDict: [String: AnyObject] = [:]
        resultDict[HKObjectKey.Date.rawValue] = date
        resultDict[HKObjectKey.HealthKitUUID.rawValue] = healthkit_uuid
        resultDict[HKObjectKey.SourceName.rawValue] = sourceName
        
        var sampleSpecificDict: [String: AnyObject] = [:]
        
        switch self.sampleType.identifier {
        case HKQuantityTypeIdentifierBodyMass:
            sampleSpecificDict = weightValuesToDictionary()
        default:
            break
        }
        
        for keyValPair in sampleSpecificDict {
            resultDict[keyValPair.0] = keyValPair.1
        }
        
        return resultDict
    }
    
    /**
     Converts Weight specific HKSamples to a dictionary.
     */
    private func weightValuesToDictionary() -> [String: AnyObject] {
        guard let quantitySample = self as? HKQuantitySample else { return [:] }
        
        let weightValue = quantitySample.quantity.doubleValueForUnit(HKUnit.poundUnit())
        return [HKObjectKey.WeightValue.rawValue: weightValue]
    }
}