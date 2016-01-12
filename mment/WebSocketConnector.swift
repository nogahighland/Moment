//
//  WebSocketConnector.swift
//  mment
//
//  Created by noga.highland on 2016/01/11.
//  Copyright © 2016年 nogahighland. All rights reserved.
//

import Foundation

class WebSocketConnector : NSObject, SRWebSocketDelegate {
    
    var url: NSURL = NSURL.init(string: "ws://10.1.17.250:8082/mment-server/ws")!
    var webSocket : SRWebSocket

    override init() {
        webSocket = SRWebSocket.init(URL: url)
        super.init()
        webSocket.delegate = self
        webSocket.open()
    }

    class var sharedInstance: WebSocketConnector {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: WebSocketConnector? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = WebSocketConnector()
        }
        return Static.instance!
    }
    
    func send(data:AnyObject) -> Bool {
        if (webSocket.readyState == SRReadyState.OPEN) {
            webSocket.send(data)
            return true
        }
        return false
    }
    
    //MARK: - private
    
    private func reopenWebSocket() {
        
        if (webSocket.readyState == SRReadyState.CONNECTING) {
            return
        }
        
        webSocket = SRWebSocket.init(URL: url)
        webSocket.delegate = self
        webSocket.open()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if (self.webSocket.readyState != SRReadyState.CONNECTING) {
                return;
            }
            self.reopenWebSocket();
        }
    }

    //MARK: - SRWebSocket delegate
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        print(message as? NSString)
    }
    
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        print("ws open")
    }
    
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("ws error")
        reopenWebSocket()
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("ws close")
        reopenWebSocket()
    }
}