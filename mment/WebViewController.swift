//
//  WebViewController.swift
//  mment
//
//  Created by noga.highland on 2016/01/11.
//  Copyright © 2016年 nogahighland. All rights reserved.
//

import UIKit

class WebViewController : UIViewController {
    
    @IBOutlet var webView: UIWebView!

    var targetURL = "http://192.168.11.5:8080/mment-server/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadAddressURL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadAddressURL() {
        let requestURL = NSURL(string: targetURL)
        let req = NSURLRequest(URL: requestURL!)
        webView.loadRequest(req)
    }
}
