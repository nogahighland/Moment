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

class MmentTracker: NSObject, CLLocationManagerDelegate {
    
    var player: MPMusicPlayerController = MPMusicPlayerController.systemMusicPlayer()
    var nowPlayingItem: MPMediaItem?
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var logger: PURLogger
    
    override init() {
        nowPlayingItem = player.nowPlayingItem
        
        //Logger
        let configuration = PURLoggerConfiguration.defaultConfiguration()
        configuration.filterSettings = [
            PURFilterSetting(filter: PURFilter.self, tagPattern: "mment.nowlistening"),
        ]
        configuration.outputSettings = [
            PUROutputSetting(output: NowListeningLogger.self,   tagPattern: "mment.nowlistening"),
        ]
        logger = PURLogger(configuration: configuration)
        
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
        
    }
    
    func track() {
        nowPlayingItem = player.nowPlayingItem
        sendNowPlayingMusicWithCoordinate()
    }
    
    //MARK: - private
    
    private func sendNowPlayingMusicWithCoordinate() {
        if (currentLocation == nil) {
            return
        }
        if (nowPlayingItem == nil) {
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
            "uuid" : ApplicationUUID.uuidString()
        ]
        logger.postLog(dic, tag: "mment.nowlistening")
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
}