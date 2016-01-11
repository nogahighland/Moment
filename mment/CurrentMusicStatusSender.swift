//
//  CurrentMusicStatusSender.swift
//  mment
//
//  Created by noga.highland on 2015/12/02.
//  Copyright © 2015年 nogahighland. All rights reserved.
//

import Foundation
import MediaPlayer
import CoreLocation

class CurrentMusicSender: NSObject, CLLocationManagerDelegate, SRWebSocketDelegate {
    
    var player: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer()
    var nowPlayingItem: MPMediaItem?
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var url: NSURL = NSURL.init(string: "ws://192.168.11.5:8080/mment-server/ws")!
    var webSocket : SRWebSocket
    
    override init() {
        webSocket = SRWebSocket.init(URL: url)
        nowPlayingItem = player.nowPlayingItem
        
        super.init()
        
        //音楽
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                selector: "nowPlayingItemDidChange:",
                name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
                object: player)
        player.beginGeneratingPlaybackNotifications()
        
        //位置情報
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        //WebSocket
        webSocket.delegate = self
        webSocket.open()
    }
    
    private func sendNowPlayingMusicWithCoordinate() {
        if (currentLocation == nil) {
            return
        }
        if (nowPlayingItem == nil || webSocket.readyState != SRReadyState.OPEN) {
            return;
        }
        let dic:NSMutableDictionary = [
            "artist": (nowPlayingItem?.artist)!,
            "title" : (nowPlayingItem?.title)!,
            "album" : (nowPlayingItem?.albumTitle)!,
            "coord" : [
                "lat":NSNumber.init(double:(currentLocation?.coordinate.latitude)!),
                "lon":NSNumber.init(double:(currentLocation?.coordinate.longitude)!),
            ],
            "uuid" : ApplicationUUID.uuidString()
        ]
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dic, options:.PrettyPrinted)
        let json = NSString.init(data: jsonData, encoding: NSUTF8StringEncoding)
        webSocket.send(json)
    }
    
    private func reopenWebSocket() {
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
    
    //MARK: - Now Playing Music
    
    @objc
    func nowPlayingItemDidChange(notify : NSNotification) {
        nowPlayingItem = player.nowPlayingItem
        sendNowPlayingMusicWithCoordinate()
    }
    
    //MARK: - CLLocationManager delegate methods
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print(status)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
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