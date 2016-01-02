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
    var url: NSURL = NSURL.init(string: "ws://192.168.11.5:8080/mment-server/")!
    var webSocket : SRWebSocket
    var isWSOpen: Bool = false
    var timer: NSTimer = NSTimer()
    var uuid: NSUUID = NSUUID.init()
    
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
    
    private func reopenWebSocket() {
        webSocket = SRWebSocket.init(URL: url)
        webSocket.delegate = self
        if (!isWSOpen) {
            webSocket.open()
        }
        if (!timer.valid) {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "reopenWebSocket", userInfo: nil, repeats: true);
        }
    }
    
    private func sendNowPlayingMusicWithCoordinate() {
        if (currentLocation == nil) {
            return
        }
        let dic:NSMutableDictionary = [
            "artist": (nowPlayingItem?.artist)!,
            "title" : (nowPlayingItem?.title)!,
            "album" : (nowPlayingItem?.albumTitle)!,
            "coord" : [
                "lat":NSNumber.init(double:(currentLocation?.coordinate.latitude)!),
                "lon":NSNumber.init(double:(currentLocation?.coordinate.longitude)!),
            ],
            "uuid" : uuid.UUIDString
        ]
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dic, options:.PrettyPrinted)
        let json = NSString.init(data: jsonData, encoding: NSUTF8StringEncoding)
        webSocket.send(json)
        
        let artwork = nowPlayingItem?.artwork
        if (artwork == nil) {
            return
        }
        let image = artwork?.imageWithSize((artwork?.bounds.size)!)
        let imageData = UIImagePNGRepresentation(image!)
        webSocket.send(imageData)
        
    }
    
    //MARK: - Now Playing Music
    
    @objc
    func nowPlayingItemDidChange(notify : NSNotification) {
        nowPlayingItem = player.nowPlayingItem!
        if (isWSOpen) {
            sendNowPlayingMusicWithCoordinate()
        }
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
        isWSOpen = true
        print("ws open")
        timer.invalidate()
    }

    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        isWSOpen = false
        print("ws error")
        reopenWebSocket()
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isWSOpen = false
        print("ws close")
        reopenWebSocket()
    }
}