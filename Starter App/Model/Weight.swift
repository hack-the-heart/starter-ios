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
}