//
//  ModelController.swift
//  mment
//
//  Created by noga.highland on 2015/11/08.
//  Copyright © 2015年 nogahighland. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreLocation

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


class ModelController: NSObject, UIPageViewControllerDataSource, CLLocationManagerDelegate, SRWebSocketDelegate {

    var pageData: [String] = []
    var player: MPMusicPlayerController
    var nowPlayingItem: MPMediaItem
    var locationManager: CLLocationManager
    var currentLocation: CLLocation?
    var webSocket : SRWebSocket
    var isWSOpen:Bool

    override init() {

        let url = NSURL.init(string: "ws://192.168.11.5:8080/mment-server/");
        webSocket = SRWebSocket.init(URL: url);
        player = MPMusicPlayerController.systemMusicPlayer();
        locationManager = CLLocationManager();
        nowPlayingItem = player.nowPlayingItem!;

        isWSOpen = false;

        super.init()

        //音楽
        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                selector: "nowPlayingItemDidChange:",
                name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
                object: player);
        player.beginGeneratingPlaybackNotifications();

        //位置情報
        locationManager.requestAlwaysAuthorization();
        locationManager.startUpdatingLocation();
        locationManager.delegate = self;

        //WebSocket
        webSocket.delegate = self;
        webSocket.open();
        
        // Create the data model.
        let dateFormatter = NSDateFormatter()
        pageData = dateFormatter.monthSymbols
    }

    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> DataViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewControllerWithIdentifier("DataViewController") as! DataViewController
        dataViewController.dataObject = self.pageData[index]
        return dataViewController
    }

    func indexOfViewController(viewController: DataViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return pageData.indexOf(viewController.dataObject) ?? NSNotFound
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index--
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! DataViewController)
        if index == NSNotFound {
            return nil
        }
        
        index++
        if index == self.pageData.count {
            return nil
        }
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    
    
    private func sendNowPlayingMusicWithCoordinate() {
        if (currentLocation == nil) {
            return;
        }
        let dic:NSMutableDictionary = [
            "artist":nowPlayingItem.artist!,
            "coord" : [
                "lat":NSNumber.init(double:(currentLocation?.coordinate.latitude)!),
                "lon":NSNumber.init(double:(currentLocation?.coordinate.longitude)!),
            ],
            "title" : nowPlayingItem.title!,
            "album" : nowPlayingItem.albumTitle!
        ];
        let jsonData = try! NSJSONSerialization.dataWithJSONObject(dic, options:.PrettyPrinted);
        let json = NSString.init(data: jsonData, encoding: NSUTF8StringEncoding);
        webSocket.send(json);

        let artwork = nowPlayingItem.artwork;
        if (artwork == nil) {
            return;
        }
        let image = artwork?.imageWithSize((artwork?.bounds.size)!);
        let imageData = UIImagePNGRepresentation(image!);
        webSocket.send(imageData);
    
    }
    
    //MARK: - Now Playing Music

    @objc
    func nowPlayingItemDidChange(notify : NSNotification) {
        nowPlayingItem = player.nowPlayingItem!;
        if (isWSOpen) {
            sendNowPlayingMusicWithCoordinate();
        }
    }
    
    //MARK: - CLLocationManager delegate methods
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print(status);
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location;
    }
    
    //MARK: - SRWebSocket delegate
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        print(message as? NSString);
    }
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        isWSOpen = true;
        print("open!!");
    }
    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        isWSOpen = false;
        print("fail");
    }

}

