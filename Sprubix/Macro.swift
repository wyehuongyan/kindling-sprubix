//
//  Macro.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import Foundation

let screenBounds = UIScreen.mainScreen().bounds
let screenSize   = screenBounds.size
let screenWidth  = screenSize.width
let screenHeight = screenSize.height
let gridWidth: CGFloat = 172.0
let navigationHeight: CGFloat = 44.0
let statusbarHeight: CGFloat = 20.0
let navigationHeaderAndStatusbarHeight : CGFloat = navigationHeight + statusbarHeight
let sprubixColor: UIColor = UIColor(red: 255/255, green: 102/255, blue: 108/255, alpha: 1)
let sprubixGray: UIColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
let sprubixLightGray: UIColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)

var timestamp: String {
    get {
        return "\(NSDate().timeIntervalSince1970)" // in secs, * 1000 for ms
    }
}

// notifications
var sprubixNotificationViewController: NotificationViewController?
var mainBadge: UILabel = UILabel()

// there are 3 places where sprubixNotificationViewController is init
// 1. after signing in to sprubix and logging into firebase when retrieve a new token (SignInViewController)
// 2. when clicking on notifications option in side panel (ContainerViewController)
// 3. when mainfeed's viewDidAppear (MainFeedController)
// reasons: 1 happens when token expires and new token is retrieve, and a relogin is done. 3 happens when there's no sign in (due to cookies). 2 is incase 1 and 3 fails.