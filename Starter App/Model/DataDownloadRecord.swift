//
//  HealthData.swift
//  Starter App
//
//  Created by ismails on 6/2/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

/// An object that represents a single instance of data download. 
/// When a csv file is downloaded, a record of that gets stored in realm
/// to keep track of what files have been downloaded.

class DataDownloadRecord: Object {
    
    dynamic var url: String?
    dynamic var date: Date?
    
    override class func primaryKey() -> String? {
        return "url"
    }
    
    class func saveToRealm(_ url: String, date: Date) throws -> DataDownloadRecord  {
        let realm = try! Realm()
        
        let record = DataDownloadRecord()
        record.url = url
        record.date = date
        
        try realm.write {
            realm.add(record, update: true)
        }
        
        return record
    }
}
