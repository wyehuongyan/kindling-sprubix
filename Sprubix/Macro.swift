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

var mainBadge: UILabel = UILabel()
var sprubixNotificationsCount: Int = 0