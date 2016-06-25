//
//  Weight.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

final class Weight: BaseHealthObject {
    
    let value = RealmOptional<Double>(nil)
    
    override var description: String {
        get {
            return "Weight Reading\t\(value)"
        }
    }
    
    // MARK: - Helper Functions
    /**
     Save to realm assumes the object does not exist in realm already. It will create a new Weight realm object and return the object that was created.
     
     - parameter weightValue:   value of weight
     - parameter date:          date this weight value was recorded
     - parameter sourceName:    name of where this value was recorded
     
     - throws: errors when writing to realm
     
     - returns: weight realm object
     */
    class func saveToRealm(weightValue weightValue: Double, date: NSDate, sourceName: String) throws -> Weight? {
        let realm = try! Realm()
        
        let weightObj = Weight()
        weightObj.value.value = weightValue
        weightObj.date = date
        weightObj.source = sourceName
        
        try realm.write {
            realm.add(weightObj)
        }
        
        return weightObj
    }
}