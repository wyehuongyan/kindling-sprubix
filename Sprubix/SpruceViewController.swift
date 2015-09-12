//
//  SpruceViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import QuartzCore
import JDFTooltips

protocol SpruceViewProtocol {
    func dismissSpruceView()
}

class SpruceViewController: UIViewController, UIScrollViewDelegate, SprucePieceFeedProtocol, SpruceSelectedPiecesProtocol {
    var delegate: SpruceViewProtocol?
    
    var userIdFrom: Int!
    var usernameFrom: String!
    var userThumbnailFrom: String!
    
    var outfit: NSDictionary?
    var pieces: [NSDictionary]!
    var currentSprucePieceTypes: [String] = [String]() // contains the types of pieces in the current outfit
    
    var scrollView: UIScrollView = UIScrollView()
    var creditsView:UIView!
    let creditsViewHeight:CGFloat = 80

    let outfitHeight: CGFloat = screenHeight - (navigationHeight * 2) - 80 // creditsViewHeight = 80
    
    var childControllers:[SprucePieceFeedController] = [SprucePieceFeedController]()
    
    var addRemovePieceActionSheet: UIActionSheet!
    var actionSheetButtonNames: [String]! = ["HEAD", "TOP", "BOTTOM", "FEET"] // contains the types of pieces NOT in the current outfit
    var defaultPieceTypes: [String]! = ["HEAD", "TOP", "BOTTOM", "FEET"]
    
    var toggleRemovePieceFeed: Bool = false
    
    var trashPieceBarButton: UIBarButtonItem!
    var trashPieceButton: UIButton!
    var searchBarButton: UIBarButtonItem!
    var searchButton: UIButton!
    var closetBarButton: UIBarButtonItem!
    var closetButton: UIButton!
    var addPieceBarButton: UIBarButtonItem!
    var addPieceButton: UIButton!
    
    var activityView: UIActivityIndicatorView!
    
    // tooltip
    var tooltipManager: JDFSequentialTooltipManager!
    
    func trashPiece(sender: AnyObject) {
        toggleDeletePieceCrosses()
    }
    
    func searchPieces(sender: AnyObject) {
        // SpruceSearchViewController
        let spruceSearchViewController = SpruceSearchViewController()
        
        self.navigationController?.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromTop
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
        self.navigationController?.pushViewController(spruceSearchViewController, animated: false)
        
        // Mixpanel - Search, Spruce
        mixpanel.track("Search", properties: [
            "Type": "Spruce"
        ])
        // Mixpanel - End
    }
    
    func closetSelection(sender: AnyObject) {
        // SpruceSearchResultsViewController 
        let myClosetViewController = MyClosetViewController()
        myClosetViewController.delegate = self
        
        self.navigationController?.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromTop
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
        self.navigationController?.pushViewController(myClosetViewController, animated: false)
        
        // Mixpanel - Use Closet, Spruce
        mixpanel.track("Use Closet", properties: [
            "Type": "Spruce"
        ])
        // Mixpanel - End
    }
    
    func addPiece(sender: AnyObject) {
        showAddPieceActionSheet()
    }
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var placeholderText:String = "Tell us more about this outfit!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register method when tapped to hide keyboard
        let tableTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        view.backgroundColor = UIColor.whiteColor()
        
        initToolBar()
        initSprucePieceFeeds()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()

        // Mixpanel - People - Spruce Outfit (prevents coming from Create > Spruce Closet), only add from 'spruce button'
        if outfit != nil {
            mixpanel.people.increment("Spruce Outfit", by: 1)
        }
        // Mixpanel - End
    }
    
    override func viewDidAppear(animated: Bool) {
        // Tooltip
        let onboarded = defaults.boolForKey("onboardedSpruce")
        
        if onboarded == false {
            tooltipOnboarding()
        }
    }
    
    func tooltipOnboarding() {
        tooltipManager = JDFSequentialTooltipManager(hostView: self.view)
        tooltipManager.showsBackdropView = true
        tooltipManager.backdropColour = UIColor.blackColor()
        tooltipManager.backdropAlpha = 0.3
        
        let swipeText = "Think you can make a better outfit?\nSwipe left or right to mix and match the outfit"
        let swipePoint: CGPoint = CGPoint(x: screenWidth/2 - 20, y: screenHeight/3)
        let swipeTooltip: JDFTooltipView = JDFTooltipView(targetPoint: swipePoint, hostView: self.view, tooltipText: swipeText, arrowDirection: JDFTooltipViewArrowDirection.Down, width: screenWidth*2/3)
        
        tooltipManager.addTooltip(swipeTooltip)
        
        tooltipManager.setFontForAllTooltips(UIFont.systemFontOfSize(16))
        tooltipManager.setTextColourForAllTooltips(UIColor.whiteColor())
        tooltipManager.setBackgroundColourForAllTooltips(sprubixColor)
        tooltipManager.showNextTooltip()
        defaults.setBool(true, forKey: "onboardedSpruce")
    }
    
    func initToolBar() {
        // create uitoolbar programmatically
        let spruceToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, screenHeight - navigationHeight, screenWidth, navigationHeight))
        
        // trash piece
        trashPieceButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        trashPieceButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        var image: UIImage = UIImage(named: "details-thumbnail-trash")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        trashPieceButton.setImage(image, forState: UIControlState.Normal)
        trashPieceButton.tintColor = UIColor.lightGrayColor()
        trashPieceButton.contentMode = UIViewContentMode.ScaleAspectFit
        trashPieceButton.addTarget(self, action: "trashPiece:", forControlEvents: UIControlEvents.TouchUpInside)
        
        trashPieceBarButton = UIBarButtonItem(customView: trashPieceButton)
        
        // search
        searchButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        searchButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        image = UIImage(named: "spruce-search")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        searchButton.setImage(image, forState: UIControlState.Normal)
        searchButton.tintColor = UIColor.lightGrayColor()
        searchButton.contentMode = UIViewContentMode.ScaleAspectFit
        searchButton.addTarget(self, action: "searchPieces:", forControlEvents: UIControlEvents.TouchUpInside)
        
        searchBarButton = UIBarButtonItem(customView: searchButton)
        
        // my closet
        closetButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        closetButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        image = UIImage(named: "profile-mycloset")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        closetButton.setImage(image, forState: UIControlState.Normal)
        closetButton.tintColor = UIColor.lightGrayColor()
        closetButton.contentMode = UIViewContentMode.ScaleAspectFit
        closetButton.addTarget(self, action: "closetSelection:", forControlEvents: UIControlEvents.TouchUpInside)
        closetButton.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 2, 0)
        
        closetBarButton = UIBarButtonItem(customView: closetButton)
        
        // add piece
        addPieceButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        addPieceButton.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        image = UIImage(named: "spruce-piece-add")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        addPieceButton.setImage(image, forState: UIControlState.Normal)
        addPieceButton.tintColor = UIColor.lightGrayColor()
        addPieceButton.contentMode = UIViewContentMode.ScaleAspectFit
        addPieceButton.addTarget(self, action: "addPiece:", forControlEvents: UIControlEvents.TouchUpInside)
        
        addPieceBarButton = UIBarButtonItem(customView: addPieceButton)
        
        // flexible space
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        
        spruceToolbar.setItems([trashPieceBarButton, flexibleSpace, searchBarButton, closetBarButton, addPieceBarButton], animated: true)
        
        view.addSubview(spruceToolbar)
        
        // here the spinner is initialized
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: (outfitHeight / 2 - activityViewWidth / 2) + navigationHeight, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
    }
    
    func initSprucePieceFeeds() {
        scrollView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.backgroundColor = sprubixGray
        scrollView.delegate = self
        
        var prevPieceHeight: CGFloat = 0
        
        if outfit != nil {
            // depending on piece type (HEAD, TOP, BOTTOM, FEET)
            // instantiate an instance of SprucePieceFeedController
            pieces = outfit!["pieces"] as! [NSDictionary]
            
            let totalHeight: CGFloat = outfit!["height"] as! CGFloat
            
            for piece in pieces {
                var pieceType: String = piece["type"] as! String
                var position = find(actionSheetButtonNames, pieceType)
                
                if position != nil {
                    actionSheetButtonNames.removeAtIndex(position!) // contains the types of pieces NOT in the current outfit
                }
                
                currentSprucePieceTypes.append(pieceType) // contains the types of pieces in the current outfit
                
                // calculate height percentages
                var pieceHeight: CGFloat = piece["height"] as! CGFloat / totalHeight * outfitHeight
                
                let sprucePieceFeedController = SprucePieceFeedController(collectionViewLayout: sprucePieceFeedControllerLayout(itemHeight: pieceHeight), pieceType: pieceType, pieceHeight: pieceHeight, outfit: outfit)

                if piece["deleted_at"]!.isKindOfClass(NSNull) {
                    sprucePieceFeedController.piece = piece
                    sprucePieceFeedController.sprucePieces.insert(piece, atIndex: 0)
                }
                
                sprucePieceFeedController.delegate = self
                
                sprucePieceFeedController.willMoveToParentViewController(self)
                self.addChildViewController(sprucePieceFeedController)
                sprucePieceFeedController.view.frame = CGRect(x: 0, y: navigationHeight + prevPieceHeight, width: screenWidth, height: pieceHeight)
                sprucePieceFeedController.view.alpha = 0
                scrollView.addSubview(sprucePieceFeedController.view)
                
                // there's this annoying flashing due to view.addsubview (previous line) no idea why, could be a ios bug
                UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    sprucePieceFeedController.view.alpha = 1.0
                    }, completion: nil)
                
                sprucePieceFeedController.didMoveToParentViewController(self)
                
                childControllers.append(sprucePieceFeedController)
                
                prevPieceHeight += pieceHeight
            }
        } else {
            activityView.startAnimating()
            
            // outfit == nil
            // // came from create outfit
            for var i = 0; i < defaultPieceTypes.count; i++ {
                var pieceType: String = defaultPieceTypes[i]
                var position = find(actionSheetButtonNames, pieceType)
                
                if position != nil {
                    actionSheetButtonNames.removeAtIndex(position!) // contains the types of pieces NOT in the current outfit
                }
                
                currentSprucePieceTypes.append(pieceType) // contains the types of pieces in the current outfit
                
                // calculate height percentages
                let sprucePieceFeedController = SprucePieceFeedController(collectionViewLayout: sprucePieceFeedControllerLayout(), pieceType: pieceType)
                
                sprucePieceFeedController.delegate = self
                
                sprucePieceFeedController.willMoveToParentViewController(self)
                self.addChildViewController(sprucePieceFeedController)
                sprucePieceFeedController.view.frame = CGRect(x: 0, y: navigationHeight + prevPieceHeight, width: screenWidth, height: 0)
                sprucePieceFeedController.view.alpha = 0
                scrollView.addSubview(sprucePieceFeedController.view)
                
                // there's this annoying flashing due to view.addsubview (previous line) no idea why, could be a ios bug
                UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    sprucePieceFeedController.view.alpha = 1.0
                    }, completion: nil)
                
                sprucePieceFeedController.didMoveToParentViewController(self)
                
                childControllers.append(sprucePieceFeedController)
            }
        }
        
        if actionSheetButtonNames.count <= 0 {
            // empty, disable add pieces button
            addPieceButton.enabled = false
        }
        
        // init 'posted by' and 'from' credits
        creditsView = UIView(frame: CGRect(x: 0, y: navigationHeight + outfitHeight, width: screenWidth, height: creditsViewHeight))
        
        let userData:NSDictionary! = defaults.dictionaryForKey("userData")
        
        var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: userData["username"] as! String, userThumbnail: userData["image"] as! String)
        var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "inspired by", username: usernameFrom, userThumbnail: userThumbnailFrom)
        
        creditsView.addSubview(postedByButton)
        creditsView.addSubview(fromButton)
        
        scrollView.addSubview(creditsView)
        
        scrollView.contentSize = CGSize(width: screenWidth, height: navigationHeight + prevPieceHeight + creditsViewHeight)
        
        view.insertSubview(scrollView, atIndex: 0)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Spruce"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("next", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "nextTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func toggleDeletePieceCrosses() {
        if toggleRemovePieceFeed == false {
            // loop through childControllers and enable deletionCrosses
            for childController in childControllers {
                childController.showDeletionCrosses()
            }
            
            // disable all other buttons
            addPieceButton.enabled = false
            closetButton.enabled = false
            searchButton.enabled = false
            
            var emptyNavItem:UINavigationItem = UINavigationItem()
            emptyNavItem.title = "Remove"
            
            newNavBar.setItems([emptyNavItem], animated: false)
            
            // update toggleRemovePiece
            toggleRemovePieceFeed = true
        } else {
            // loop through childControllers and disable deletionCrosses
            for childController in childControllers {
                childController.hideDeletionCrosses()
            }
            
            // enable all other buttons
            addPieceButton.enabled = true
            closetButton.enabled = true
            searchButton.enabled = true

            newNavBar.setItems([newNavItem], animated: true)

            // update toggleRemovePiece
            toggleRemovePieceFeed = false
        }
    }
    
    func showAddPieceActionSheet() {
        let alertViewController = UIAlertController(title: "Which piece would you like to add?", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertViewController.view.tintColor = UIColor.grayColor()
        
        for buttonName in actionSheetButtonNames {
            let buttonAction = UIAlertAction(title: buttonName.lowercaseString.capitalizeFirst, style: UIAlertActionStyle.Default, handler: {
                action in
                // handler
                self.clickedButtonAction(action.title)
            })
            
            alertViewController.addAction(buttonAction)
        }
        
        // add cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {
            action in
            // handler
            self.dismissViewControllerAnimated(true, completion: nil)
            alertViewController.removeFromParentViewController()
        })
        
        alertViewController.addAction(cancelAction)
        
        self.presentViewController(alertViewController, animated: true, completion: nil)
    }
    
    func clickedButtonAction(buttonName: String) {
        // create a new pieceController based on the buttonName
        let pieceType: String = buttonName.uppercaseString
        var pieceIndex: Int?

        switch buttonName {
            
        case "Head":
            //println("Head pressed")
            // append to currentSprucePieces position 0
            pieceIndex = 0
           
        case "Top":
            //println("Top pressed")
            
            if childControllers.count > 0 {
                // check if first item is of pieceType "HEAD"
                if currentSprucePieceTypes.first?.uppercaseString == "HEAD" {
                    // yes it is "HEAD"
                    pieceIndex = 1 // 2nd one, after HEAD
                } else {
                    // its not "HEAD", could be bottom or feet
                    pieceIndex = 0 // it will definitely be the first
                }
            } else {
                pieceIndex = 0
            }
            
        case "Bottom":
            //println("Bottom pressed")
            
            if childControllers.count > 0 {
                // check if last item is of pieceType "FEET"
                if currentSprucePieceTypes.last?.uppercaseString == "FEET" {
                    // yes it is "FEET"
                    pieceIndex = currentSprucePieceTypes.count - 1 // 2nd last, before the last 1
                } else {
                    // its not "FEET"
                    pieceIndex = currentSprucePieceTypes.count // it will definitely be the last
                }
            } else {
                pieceIndex = 0
            }
            
        case "Feet":
            //println("Feet pressed")
            // append to currentSprucePieces last position
            pieceIndex = currentSprucePieceTypes.count
            
        default:
            fatalError("Unknown piece entered")
        }
        
        if pieceIndex != nil {
            currentSprucePieceTypes.insert(pieceType, atIndex: pieceIndex!)
            
            let newPieceHeight:CGFloat = 100 // tentative
            
            // create another piece feed
            let sprucePieceFeedController = SprucePieceFeedController(collectionViewLayout: sprucePieceFeedControllerLayout(itemHeight: newPieceHeight), pieceType: pieceType, pieceHeight: newPieceHeight)
            
            sprucePieceFeedController.delegate = self
            
            sprucePieceFeedController.willMoveToParentViewController(self)
            self.addChildViewController(sprucePieceFeedController)
            
            var prevPieceHeight: CGFloat = 0
            
            // determine the y position of the new spruceFeedController by adding up the ones before it
            for var i = 0; i < pieceIndex; i++ {
                // retrieve heights of SprucePieceFeedControllers up till the button index
                let childController = self.childControllers[i]
                prevPieceHeight += childController.pieceHeight
            }
            
            // adjust the y positions of the other pieces BELOW this newly created SprucePieceFeedController
            for var j = pieceIndex!; j < self.childControllers.count; j++ {
                let childController = self.childControllers[j]
                
                childController.view.frame = CGRect(x: 0, y: childController.view.frame.origin.y + newPieceHeight, width: childController.view.frame.width, height: childController.view.frame.height)
            }
            
            sprucePieceFeedController.view.frame = CGRect(x: 0, y: navigationHeight + prevPieceHeight, width: screenWidth, height: newPieceHeight)
            sprucePieceFeedController.view.alpha = 0
            scrollView.addSubview(sprucePieceFeedController.view)
            
            // there's this annoying flashing due to view.addsubview (previous line) no idea why, could be a ios bug
            UIView.animateWithDuration(0.3, delay: 0.2, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                sprucePieceFeedController.view.alpha = 1.0
                }, completion: nil)
            
            sprucePieceFeedController.didMoveToParentViewController(self)
            
            childControllers.insert(sprucePieceFeedController, atIndex: pieceIndex!)
            
            // update actionSheetButtonNames
            var position = find(actionSheetButtonNames, buttonName.uppercaseString)
            
            if position != nil {
                actionSheetButtonNames.removeAtIndex(position!)
                
                if actionSheetButtonNames.count <= 0 {
                    // empty, disable add pieces button
                    addPieceButton.enabled = false
                }
            }
            
            // check if there are still childControllers
            if childControllers.count > 0 {
                // as long as there is at least 1
                trashPieceButton.enabled = true
            }
        }
    }
    
    func expandOutfit() {
        var prevHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var hasDress: Bool = false
        var hadHasDress: Bool = false
        
        // get total height of all current
        for childController in self.childControllers {
            let currentVisibleCell = childController.currentVisibleCell as SprucePieceFeedCell
            
            if hasDress != true {
                currentVisibleCell.compressedDueToDress = false
                totalHeight += currentVisibleCell.piece["height"] as! CGFloat
            } else {
                if currentVisibleCell.piece["type"] as! String == "BOTTOM" {
                    // dont add height for bottoms
                    // // set compression true
                    currentVisibleCell.compressedDueToDress = true
                    
                    // // reset hasDress
                    hasDress = false
                } else {
                    totalHeight += currentVisibleCell.piece["height"] as! CGFloat
                }
            }
            
            if currentVisibleCell.piece["is_dress"] as! Bool == true {
                hasDress = true
                hadHasDress = true
            }
        }
        
        // resize the heights of the viewcontrollers
        for childController in self.childControllers {
            let currentVisibleCell = childController.currentVisibleCell as SprucePieceFeedCell
            
            var height: CGFloat = currentVisibleCell.piece["height"] as! CGFloat / totalHeight * outfitHeight
            
            if currentVisibleCell.piece["type"] as! String == "BOTTOM" && hadHasDress == true {
                
                height = 0
            }
            
            // smooth animation
            UIView.animateWithDuration(0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                childController.pieceHeight = height
                
                // setting the new views
                childController.collectionView?.collectionViewLayout.invalidateLayout()
                
                childController.view.frame = CGRect(x: childController.view.frame.origin.x, y: prevHeight + navigationHeight, width: childController.view.frame.width, height: height)
                
                if childController.deleteOverlay != nil {
                    childController.deleteOverlay.frame.size.height = height
                }
                
                // moving the arrows to their new positions
                childController.setLeftArrowButtonFrame(height)
                childController.setRightArrowButtonFrame(height)
                
                prevHeight += height
                
                }, completion:{ finished in
                
                    if finished {
                        childController.collectionView?.setCollectionViewLayout(self.sprucePieceFeedControllerLayout(itemHeight: height), animated: false)
                    }
                })
        }
    }
    
    // SprucePieceFeedProtocol
    func deleteSprucePieceFeed(sprucePieceFeedController: SprucePieceFeedController) {
        var childPosition = find(childControllers, sprucePieceFeedController)

        if childPosition != nil {
            // 1. for childcontrollers after the one to be deleted,
            // shift them upwards (includes creditsView)
            
            let deleteChildController = childControllers.removeAtIndex(childPosition!)
            
            for var i = childPosition!; i < childControllers.count; i++ {
                let childController = childControllers[i]
                
                childController.view.frame = CGRect(x: 0, y: childController.view.frame.origin.y - deleteChildController.pieceHeight, width: childController.view.frame.width, height: childController.view.frame.height)
            }
            
            // 2. add the removed childcontroller piecetype back to actionSheetButtonNames
            if childControllers.count <= 0 {
                // empty, remove the removeSprucePieceFeed button
                trashPieceButton.enabled = false
            }
            
            toggleDeletePieceCrosses()
            expandOutfit()
            
            // update the two arrays: currentSprucePieceTypes and actionSheetButtonNames
            var position = find(currentSprucePieceTypes, deleteChildController.pieceType)

            if position != nil {
                currentSprucePieceTypes.removeAtIndex(position!)
                
                var actionIndex:Int?
                
                switch deleteChildController.pieceType {
                    
                case "HEAD":
                    // append to array position 0
                    actionIndex = 0
                    
                case "TOP":
                    if actionSheetButtonNames.count > 0 {
                        // check if first item is of pieceType "HEAD"
                        if actionSheetButtonNames.first?.uppercaseString == "HEAD" {
                            // yes it is "HEAD"
                            actionIndex = 1 // 2nd one, after HEAD
                        } else {
                            // its not "HEAD", could be bottom or feet
                            actionIndex = 0 // it will definitely be the first
                        }
                    } else {
                        actionIndex = 0
                    }
                    
                case "BOTTOM":
                    if actionSheetButtonNames.count > 0 {
                        // check if last item is of pieceType "FEET"
                        if actionSheetButtonNames.last?.uppercaseString == "FEET" {
                            // yes it is "FEET"
                            actionIndex = actionSheetButtonNames.count - 1 // 2nd last, before the last 1
                        } else {
                            // its not "FEET"
                            actionIndex = actionSheetButtonNames.count // it will definitely be the last
                        }
                    } else {
                        actionIndex = 0
                    }
                    
                case "FEET":
                    // append to array last position
                    actionIndex = actionSheetButtonNames.count
                    
                default:
                    fatalError("Unknown piece entered")
                }
                
                actionSheetButtonNames.insert(deleteChildController.pieceType, atIndex: actionIndex!)
                
                if actionSheetButtonNames.count > 0 {
                    // not empty, dont hide add pieces button
                    addPieceButton.enabled = true
                }
            }
            
            deleteChildController.view.removeFromSuperview()
            deleteChildController.view = nil
            deleteChildController.removeFromParentViewController()
        }
    }
    
    func resizeOutfit() {
        // here we need to check if all sprucePieceFeedControllers have non-nil currentVisibleCells
        // // if all are not nil, then resizeOutfit is called
        
        for var i = 0; i < childControllers.count; i++ {
            let childController = self.childControllers[i]
            
            if childController.currentVisibleCell == nil {
                break
            }
            
            // last one cleared
            if i == childControllers.count - 1 {
                expandOutfit()
                
                if outfit == nil {
                    activityView.stopAnimating()
                }
            }
        }
    }
    
    func sprucePieceFeedControllerLayout (itemHeight: CGFloat = 0) -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, itemHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MyClosetProtocol
    func insertSelectedClosetPieces(closetPieces: [NSDictionary]) {
        
        // sort into different arrays based on pieceType
        var closetPiecesDict: [String: [NSDictionary]] = [String: [NSDictionary]]()
        
        for closetPiece in closetPieces {
            let pieceType = closetPiece["type"] as! String
            
            if closetPiecesDict[pieceType] == nil {
               closetPiecesDict[pieceType] = [NSDictionary]()
            }
            
            closetPiecesDict[pieceType]?.append(closetPiece)
        }
        
        // insert into respective sprucePieceFeedControllers
        for childController in self.childControllers {
            let childPieceType = childController.pieceType
            
            let newPieces: [NSDictionary]? = closetPiecesDict[childPieceType]
            
            if newPieces != nil {
                childController.insertMorePieces(newPieces!)
            }
        }
    }
    
    /**
    * Called when the user click on the view (outside the UITextField).
    */
    func tableTapped(gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    /**
    * Called when 'return' key pressed. return NO to ignore.
    */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
        delegate?.dismissSpruceView()
    }
    
    func nextTapped(sender: UIBarButtonItem) {
        var images: [UIImage] = [UIImage]()
        var totalHeight: CGFloat = 0
        var width: CGFloat = screenWidth
        var sprucedPieces: [NSDictionary] = [NSDictionary]()
        
        // calculate totalHeight
        for childController in childControllers {
            let currentVisibleCell = childController.currentVisibleCell as SprucePieceFeedCell
            
            if currentVisibleCell.compressedDueToDress != true {
                var image = currentVisibleCell.pieceImageView.image!
                images.append(image)
                
                var piece = currentVisibleCell.piece
                sprucedPieces.append(piece)
                
                var newImageHeight = image.size.height * width / image.size.width
                totalHeight += newImageHeight
            }
        }
        
        // create the merged image
        var size:CGSize = CGSizeMake(width, totalHeight)
        var prevHeight:CGFloat = 0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
        
        for image in images {
            var pieceHeight = image.size.height * screenWidth / image.size.width
            
            image.drawInRect(CGRectMake(0, prevHeight, size.width, pieceHeight))
            
            prevHeight += pieceHeight
        }
        
        // final image
        var finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        // set SpruceShareViewController's outfitImageView image to be finalImage
        let spruceShareViewController = SpruceShareViewController()
        
        spruceShareViewController.outfitImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth / 0.75)
        spruceShareViewController.outfitImageView.image = finalImage
        
        spruceShareViewController.userIdFrom = userIdFrom
        spruceShareViewController.usernameFrom = usernameFrom
        spruceShareViewController.userThumbnailFrom = userThumbnailFrom
        spruceShareViewController.pieces = sprucedPieces
        spruceShareViewController.numPieces = images.count
        
        self.navigationController?.pushViewController(spruceShareViewController, animated: true)
        
        // Mixpanel - Create Outfit Share, Closet, Outfit
        mixpanel.track("Create Outfit Share", properties: [
            "Method": "Closet",
            "Type" : "Outfit"
        ])
        // Mixpanel - End
    }
}

extension String {
    var capitalizeIt:String {
        var result = Array(self)
        if !isEmpty { result[0] = Character(String(result.first!).uppercaseString) }
        return String(result)
    }
    var capitalizeFirst:String {
        var result = self
        result.replaceRange(startIndex...startIndex, with: String(self[startIndex]).capitalizedString)
        return result
    }
    
}
