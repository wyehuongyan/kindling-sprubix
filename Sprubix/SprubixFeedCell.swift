//
//  SprubixFeedCell.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 2/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol SprubixFeedCellProtocol {
    func displayCommentsView(selectedOutfit: NSDictionary)
    func spruceOutfit(selectedOutfit: NSDictionary)
}

class SprubixFeedCell: UITableViewCell {
    
    @IBOutlet var userThumbnail: UIImageView!
    
    @IBAction func spruceItUp(sender: AnyObject) {
        delegate?.spruceOutfit(outfit)
    }
    
    @IBAction func viewComments(sender: AnyObject) {
        delegate?.displayCommentsView(outfit)
    }
    
    var navController:UINavigationController?
    var delegate:SprubixFeedCellProtocol?
    
    // one cell = one outfit
    var outfitHeight:CGFloat = 0
    var pieces:[NSDictionary]!
    var outfit:NSDictionary!
    var pieceImages: [UIImageView] = [UIImageView]()
    
    // array of UIImageViews to store images for each piece
    func initOutfit(outfit: NSDictionary) {
        self.outfit = outfit
        
        pieces = outfit["pieces"] as [NSDictionary]
        
        var prevPieceHeight:CGFloat = 0
        outfitHeight = 0
        
        for var i = 0; i < pieces.count; i++ {
            var piece = pieces[i]
            
            // calculate piece UIImageView height
            var itemHeight = piece["height"] as CGFloat
            var itemWidth = piece["width"] as CGFloat
            
            let pieceHeight:CGFloat = itemHeight * screenWidth / itemWidth
            
            // setting the image for piece
            var pieceImageView:UIImageView = UIImageView()
            pieceImageView.image = nil
            pieceImageView.frame = CGRect(x:0, y: prevPieceHeight, width: UIScreen.mainScreen().bounds.width, height: pieceHeight)
            
            var pieceImagesString = piece["images"] as NSString!
            var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
            
            var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as NSString)

            pieceImageView.setImageWithURL(pieceCoverURL)
            pieceImageView.contentMode = UIViewContentMode.ScaleAspectFit
            pieceImageView.userInteractionEnabled = true
            
            pieceImages.append(pieceImageView)
            
            // add gesture recognizers
            var singleTap = UITapGestureRecognizer(target: self, action: Selector("wasSingleTapped:"))
            singleTap.numberOfTapsRequired = 1
            pieceImageView.addGestureRecognizer(singleTap)
            
            var doubleTap = UITapGestureRecognizer(target: self, action: Selector("wasDoubleTapped:"))
            doubleTap.numberOfTapsRequired = 2
            pieceImageView.addGestureRecognizer(doubleTap)
            
            singleTap.requireGestureRecognizerToFail(doubleTap) // so that single tap will not be called during a double tap
            
            //contentView.addSubview(pieceImageView)
            contentView.insertSubview(pieceImageView, atIndex: 0)
            
            prevPieceHeight += pieceHeight // to offset 2nd piece image's height with first image's height
            outfitHeight += pieceHeight // accumulate height of all pieces
        }
        
        initUserInfo()
    }
    
    func initUserInfo() {
        userThumbnail.layer.cornerRadius = userThumbnail.frame.size.width / 2
        userThumbnail.clipsToBounds = true
        userThumbnail.layer.borderWidth = 1.0
        userThumbnail.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        var selectedPiece:UIImageView = gesture.view as UIImageView
        var position = find(pieceImages, selectedPiece)
        
        var currentIndexPath:NSIndexPath = NSIndexPath(forItem: position!, inSection: 0)
        
        let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: currentIndexPath)
        pieceDetailsViewController.pieces = pieces
        
        //collectionView.setToIndexPath(indexPath)
        navController!.delegate = nil
        navController!.pushViewController(pieceDetailsViewController, animated: true)
        navController!.delegate = transitionDelegateHolder
    }
    
    func wasDoubleTapped(gesture: UITapGestureRecognizer) {
        println("I was double tapped! \n\(gesture.view!)")
        
        var cookies:[NSHTTPCookie] = [NSHTTPCookie]()
        cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies as [NSHTTPCookie]!
        println("currently we have these cookies: \(cookies)")
        
        // testingly delete cookies
        for cookie in cookies {
            NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            println("deleted cookie: \(cookie)\n")
            println(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!)
        }
        
        // remove userId object from user defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("userId")
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight) //navController!.navigationBarHidden ?
            //CGSizeMake(screenWidth, screenHeight+20) : CGSizeMake(screenWidth, screenHeight-navigationHeaderAndStatusbarHeight)
        
        //let itemSize = CGSizeMake(screenWidth, screenHeight + navigationHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
