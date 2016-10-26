//
//  StringExtension.swift
//  Starter App
//
//  Created by ismails on 10/26/16.
//  Copyright © 2016 Saad Ismail. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func md5() -> Data? {
        guard let messageData = self.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    func lastCharacter() -> String {
        let characters = Array(self.characters)
        return String(characters[characters.count - 1])
    }
}
