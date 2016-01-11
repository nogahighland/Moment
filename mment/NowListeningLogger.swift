//
//  NowListeningLogger.swift
//  mment
//
//  Created by noga.highland on 2016/01/11.
//  Copyright © 2016年 nogahighland. All rights reserved.
//

import Foundation

class NowListeningLogger : PURBufferedOutput {
    
    var sender: WebSocketConnector
    
    override init(logger: PURLogger, tagPattern: String) {
        sender = WebSocketConnector.sharedInstance
        super.init(logger: logger, tagPattern: tagPattern)
    }
    
    override func writeChunk(chunk: PURBufferedOutputChunk, completion: (Bool) -> Void) {
        for purLog in chunk.logs {
            let log = NSMutableDictionary(dictionary:purLog.userInfo)
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = dateFormatter.stringFromDate(purLog.date)
            
            log.setValue(timestamp, forKey: "timestamp")
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(log, options:.PrettyPrinted)
            let json = NSString.init(data: jsonData, encoding: NSUTF8StringEncoding)
            completion(sender.send(json!))
        }
    }
}
