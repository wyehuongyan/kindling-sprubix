//
//  Macro.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 13/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import Braintree

let screenBounds = UIScreen.mainScreen().bounds
let screenSize   = screenBounds.size
let screenWidth  = screenSize.width
let screenHeight = screenSize.height
let gridWidth: CGFloat = (screenWidth - 30) / 2
let navigationHeight: CGFloat = 44.0
let statusbarHeight: CGFloat = 20.0
let navigationHeaderAndStatusbarHeight : CGFloat = navigationHeight + statusbarHeight
let sprubixColor: UIColor = UIColor(red: 255/255, green: 102/255, blue: 108/255, alpha: 1)
let sprubixGray: UIColor = UIColor(red: 229/255, green: 229/255, blue: 229/255, alpha: 1)
let sprubixLightGray: UIColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
let sprubixYellow: UIColor = UIColor(red: 255/255, green: 255/255, blue: 224/255, alpha: 1)
let sprubixBlue: UIColor = UIColor(red: 102/255, green: 180/255, blue: 255/255, alpha: 1)
let sprubixLightBlue: UIColor = UIColor(red: 102/255, green: 220/255, blue: 255/255, alpha: 1)
let sprubixGreen: UIColor = UIColor(red: 102/255, green: 255/255, blue: 102/255, alpha: 1)
let sprubixOrange: UIColor = UIColor(red: 255/255, green: 152/255, blue: 102/255, alpha: 1)
let countriesAvailable = ["SG"]
let testUsernames = ["cameron", "tingzhi", "cecilia", "sprubixshop", "flufflea"]
let testEmails = ["cameron@example.com", "tingzhi@example.com", "cecilia@example.com", "developers@sprubix.com", "shop@flufflea.com"]

var timestamp: String {
    get {
        return "\(NSDate().timeIntervalSince1970)" // in secs, * 1000 for ms
    }
}

var localDate: String {
    get {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.stringFromDate(NSDate())
        
        return formattedDate
    }
}

// braintree
var braintreeRef: Braintree?

// notifications
var sprubixNotificationViewController: NotificationViewController?
var mainBadge: UILabel = UILabel()

// there are 3 places where sprubixNotificationViewController is init
// 1. after signing in to sprubix and logging into firebase when retrieve a new token (SignInViewController)
// 2. when clicking on notifications option in side panel (ContainerViewController)
// 3. when mainfeed's viewDidAppear (MainFeedController)
// reasons: 1 happens when token expires and new token is retrieve, and a relogin is done. 3 happens when there's no sign in (due to cookies). 2 is incase 1 and 3 fails.


// exposed outfits
var exposedOutfits = [Int]()

// check for account logout/login, this is to detect if it's a fresh login
// viewDidLoad don't trigger again when a user logout followed by another login
// there's a need to run functions that are suppose to trigger on every logins, such like dashboard
var freshLogin: Bool = Bool()
