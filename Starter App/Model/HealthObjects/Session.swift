//
//  Session.swift
//  Starter App
//
//  Created by ismails on 10/19/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import RealmSwift

class Session: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var desc: String = ""
    dynamic var startTime: Date = Date()
    dynamic var endTime: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    class func saveToRealm(_ id: String, name: String, description: String, startTime: Date, endTime: Date) throws {
        let realm = try! Realm()
        
        let session = Session()
        session.id = id
        session.name = name
        session.desc = description
        session.startTime = startTime
        session.endTime = endTime
        
        try realm.write {
            realm.add(session, update: true)
        }
    }
}
