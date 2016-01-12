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

    var targetURL = "http://10.1.17.250:8082/mment-server/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAddressURL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadAddressURL() {
        let requestURL = NSURL(string: targetURL)
        let req = NSMutableURLRequest(URL: requestURL!)
        let uuid = ApplicationUUID.uuidString()
        req.setValue("x-mment-uuid", forHTTPHeaderField: uuid)
        webView.loadRequest(req)
    }
}
