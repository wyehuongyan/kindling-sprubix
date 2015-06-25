//
//  SprubixPiece.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/5/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

class SprubixPiece: NSObject {
    var imageURLs: [NSURL] = [NSURL]()
    var images: [UIImage] = [UIImage]()
    
    var id: Int!
    var name: String!
    var category: String!
    var type: String!
    var isDress: Bool!
    var brand: String!
    var size: String!
    var desc: String!
    
    // if shop
    var quantity: Int!
    var price: String!
}
