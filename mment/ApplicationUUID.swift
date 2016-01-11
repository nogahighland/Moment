//
//  ApplicationUUID.swift
//  mment
//
//  Created by noga.highland on 2016/01/11.
//  Copyright © 2016年 nogahighland. All rights reserved.
//

import Foundation

class ApplicationUUID : NSObject {
    
    class func uuidString() -> String {
        let ud = NSUserDefaults.standardUserDefaults()
        var uuid = ud.valueForKey("uuid")
        if (uuid == nil) {
            uuid = NSUUID.init().UUIDString
            ud.setValue(uuid, forKey: "uuid")
        }
        return uuid as! String
    }
}
