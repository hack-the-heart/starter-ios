//
//  HealthObject.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

class DataDownloadRecord: Object {
    
    dynamic var url: String?
    dynamic var date: NSDate?
    
    class func saveToRealm(url: String, date: NSDate) throws -> DataDownloadRecord  {
        let realm = try! Realm()
        
        let record = DataDownloadRecord()
        record.url = url
        record.date = date
        
        try realm.write {
            realm.add(record)
        }
        
        return record
    }
}