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
    func spruceOutfit(selectedOutfit: NSDictionary, userName: String, userThumbnail: String)
    func showProfile(user: NSDictionary)
}

class SprubixFeedCell: UITableViewCell {
    
    @IBOutlet var userName: UILabel!
    @IBOutlet var userThumbnail: UIImageView!
    @IBOutlet var timestamp: UILabel!
    @IBOutlet var spruceButton: UIButton!
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var commentsButton: UIButton!
    
    @IBAction func spruceItUp(sender: AnyObject) {
        delegate?.spruceOutfit(outfit, userName: userName.text!, userThumbnail: user["image"] as! String)
    }
    
    @IBAction func viewComments(sender: AnyObject) {
        delegate?.displayCommentsView(outfit)
    }
    
    @IBAction func likeOutfit(sender: UIButton) {
        if sender.selected != true {
            sender.selected = true
        } else {
            sender.selected = false
        }
    }
    
    var user: NSDictionary!
    
    var navController:UINavigationController?
    var delegate:SprubixFeedCellProtocol?
    
    // one cell = one outfit
    var outfitHeight:CGFloat = 0
    var pieces:[NSDictionary]!
    var outfit:NSDictionary!
    var pieceImages: [UIImageView] = [UIImageView]()
    
    var likeImageView:UIImageView!
    
    override func prepareForReuse() {
        for pieceImage in pieceImages {
            
            for gestureRecognizer in pieceImage.gestureRecognizers as! [UIGestureRecognizer] {
                pieceImage.removeGestureRecognizer(gestureRecognizer)
            }
            
            pieceImage.removeFromSuperview()
            pieceImage.image = nil
        }
        
        likeButton.selected = false
        userThumbnail.image = nil
        pieceImages.removeAll()
    }
    
    // array of UIImageViews to store images for each piece
    func initOutfit() {
        pieces = outfit["pieces"] as! [NSDictionary]
        
        var prevPieceHeight:CGFloat = 0
        outfitHeight = 0
        
        for var i = 0; i < pieces.count; i++ {
            var piece = pieces[i]
            
            // calculate piece UIImageView height
            var itemHeight = piece["height"] as! CGFloat
            var itemWidth = piece["width"] as! CGFloat
            
            let pieceHeight:CGFloat = itemHeight * screenWidth / itemWidth
            
            // setting the image for piece
            let pieceImageView:UIImageView = UIImageView()
            pieceImageView.image = nil
            pieceImageView.frame = CGRect(x:0, y: prevPieceHeight, width: UIScreen.mainScreen().bounds.width, height: pieceHeight)
            
            var pieceImagesString = piece["images"] as! String
            var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            
            var pieceCoverURL = NSURL(string: pieceImagesDict["cover"] as! String)

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
        
        // gesture recognizer
        let userThumbnailToProfile:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile:")
        userThumbnailToProfile.numberOfTapsRequired = 1
        
        userThumbnail.userInteractionEnabled = true
        userThumbnail.addGestureRecognizer(userThumbnailToProfile)
        
        let userNameToProfile:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showProfile:")
        userNameToProfile.numberOfTapsRequired = 1
        
        userName.userInteractionEnabled = true
        userName.addGestureRecognizer(userNameToProfile)
        
        // like heart image
        let likeImageViewWidth:CGFloat = 150
        likeImageView = UIImageView(image: UIImage(named: "main-like-filled-large"))
        likeImageView.frame = CGRect(x: screenWidth / 2 - likeImageViewWidth / 2, y: 0, width: likeImageViewWidth, height: outfitHeight)
        likeImageView.contentMode = UIViewContentMode.ScaleAspectFit
        likeImageView.alpha = 0
        
        contentView.addSubview(likeImageView)
        
        initUserInfo()
    }
    
    func initUserInfo() {
        userThumbnail.layer.cornerRadius = userThumbnail.frame.size.width / 2
        userThumbnail.clipsToBounds = true
        userThumbnail.layer.borderWidth = 1.0
        userThumbnail.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        // user info
        user = outfit["user"] as! NSDictionary
        let userThumbnailURL = NSURL(string: user["image"] as! String)

        userThumbnail.setImageWithURL(userThumbnailURL)
        userName.text = user["username"] as? String
        
        // time stamp
        let created_at = outfit["created_at_custom_format"] as! NSDictionary
        let timestampString = created_at["created_at_human"] as! String
        var timestampArray = split(timestampString) {$0 == " "}
        var time = timestampArray[0]
        var stamp = timestampArray[1]
        
        timestamp.text = time + stamp[0]
        
        // add glow to buttons
        Glow.addGlow(spruceButton)
        Glow.addGlow(likeButton)
        Glow.addGlow(commentsButton)
        Glow.addGlow(userName)
        Glow.addGlow(timestamp)
    }
    
    func wasSingleTapped(gesture: UITapGestureRecognizer) {
        var selectedPiece:UIImageView = gesture.view as! UIImageView

        //println("pieceImages: \(pieceImages)")
        //println("selectedPiece: \(selectedPiece)")
        var position = find(pieceImages, selectedPiece)
        // position sometimes become nil and causes the app to crash
        // reason: pieceImages refresh everytime main feed is loaded. selectedPiece sometimes does not refresh. why? 
        // solution: remove the gestureRecognizer in prepareForReuse
        //println("position: \(position)")
        var currentIndexPath:NSIndexPath = NSIndexPath(forItem: position!, inSection: 0)
        
        let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: detailsViewControllerLayout(), currentIndexPath: currentIndexPath)
        pieceDetailsViewController.pieces = pieces
        pieceDetailsViewController.user = user
        
        var inspiredBy: AnyObject = outfit["inspired_by"]!
        
        if inspiredBy.isKindOfClass(NSNull) {
            pieceDetailsViewController.inspiredBy = nil
        } else {
            pieceDetailsViewController.inspiredBy = outfit["inspired_by"] as! NSDictionary
        }
        
        //collectionView.setToIndexPath(indexPath)
        navController!.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromTop
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        navController?.view.layer.addAnimation(transition, forKey: kCATransition)
        navController!.pushViewController(pieceDetailsViewController, animated: false)
        
        navController!.delegate = transitionDelegateHolder
    }
    
    func wasDoubleTapped(gesture: UITapGestureRecognizer) {
        // like outfit
        UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.likeImageView.alpha = 1.0
            }, completion: { finished in
                if finished {
                    UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                        self.likeImageView.alpha = 0.0
                        }, completion: nil)
                }
        })
        
        likeButton.selected = true
    }
    
    func showProfile(gesture: UITapGestureRecognizer) {
        delegate?.showProfile(user)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}
