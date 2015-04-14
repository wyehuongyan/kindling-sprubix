//
//  SpruceViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 21/3/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import QuartzCore

protocol SpruceViewProtocol {
    func dismissSpruceView()
}

class SpruceViewController: UIViewController, UIScrollViewDelegate, UIActionSheetDelegate, UITextViewDelegate, SprucePieceFeedProtocol {
    var delegate: SpruceViewProtocol?
    
    var usernameFrom: String!
    var userThumbnailFrom: String!
    
    var outfit: NSDictionary!
    var pieces: [NSDictionary]!
    var currentSprucePieceTypes: [String] = [String]() // contains the types of pieces in the current outfit
    
    var scrollView: UIScrollView = UIScrollView()
    var creditsView:UIView!
    let creditsViewHeight:CGFloat = 80
    
    let descriptionHeight:CGFloat = 50
    
    var childControllers:[SprucePieceFeedController] = [SprucePieceFeedController]()
    
    var addRemovePieceActionSheet: UIActionSheet!
    var actionSheetButtonNames: [String]! = ["HEAD", "TOP", "BOTTOM", "FEET"] // contains the types of pieces NOT in the current outfit
    
    var addPieceFeedButton: UIButton!
    var removePieceFeedButton: UIButton!
    var toggleRemovePieceFeed: Bool = false
    var confirmButton: UIButton!
    var magicButton: UIButton!
    
    var longPress:UILongPressGestureRecognizer!
    
    // custom nav bar
    var newNavBar:UINavigationBar!
    var newNavItem:UINavigationItem!
    
    var descriptionText:UITextView!
    var placeholderText:String = "Tell us more about this outfit!"
    var keyboardVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listen to keyboard show/hide events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        // register method when tapped to hide keyboard
        let tableTapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tableTapped:")
        self.view.addGestureRecognizer(tableTapGestureRecognizer)
        
        initSprucePieceFeeds()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        initButtons()
    }
    
    func initSprucePieceFeeds() {
        view.backgroundColor = UIColor.whiteColor()
        
        scrollView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.delegate = self
        
        // depending on piece type (HEAD, TOP, BOTTOM, FEET)
        // instantiate an instance of SprucePieceFeedController
        pieces = outfit["pieces"] as [NSDictionary]
        
        var prevPieceHeight:CGFloat = 0
        
        for piece in pieces {
            var pieceType: String = piece["type"] as String
            
            var position = find(actionSheetButtonNames, pieceType)
            
            if position != nil {
                actionSheetButtonNames.removeAtIndex(position!) // contains the types of pieces NOT in the current outfit
            }
            
            currentSprucePieceTypes.append(pieceType) // contains the types of pieces in the current outfit
            
            // calculate piece UIImageView height
            var itemHeight = piece["height"] as CGFloat
            var itemWidth = piece["width"] as CGFloat
            
            let pieceHeight:CGFloat = itemHeight * screenWidth / itemWidth
            let sprucePieceFeedController = SprucePieceFeedController(collectionViewLayout: sprucePieceFeedControllerLayout(pieceHeight), pieceType: pieceType, pieceHeight: pieceHeight)
            
            sprucePieceFeedController.piece = piece
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
        
        // init 'posted by' and 'from' credits
        creditsView = UIView(frame: CGRect(x: 0, y: navigationHeight + prevPieceHeight, width: screenWidth, height: creditsViewHeight))
        
        let userData:NSDictionary! = defaults.dictionaryForKey("userData")
        
        var postedByButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: 0, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "posted by", username: userData["username"] as String!, userThumbnail: userData["image"] as String!)
        var fromButton:SprubixCreditButton = SprubixCreditButton(frame: CGRect(x: screenWidth/2, y: 0, width: screenWidth/2, height: creditsViewHeight), buttonLabel: "from", username: usernameFrom, userThumbnail: userThumbnailFrom)
        
        creditsView.addSubview(postedByButton)
        creditsView.addSubview(fromButton)
        
        scrollView.addSubview(creditsView)
        
        descriptionText = UITextView(frame: CGRectInset(CGRect(x: 0, y: navigationHeight + prevPieceHeight + creditsViewHeight, width: screenWidth, height: descriptionHeight), 15, 0))

        descriptionText.tintColor = sprubixColor
        descriptionText.text = placeholderText
        descriptionText.textColor = UIColor.lightGrayColor()
        descriptionText.font = UIFont(name: descriptionText.font.fontName, size: 16)
        descriptionText.delegate = self
        
        scrollView.addSubview(descriptionText)
        
        scrollView.contentSize = CGSize(width: screenWidth, height: navigationHeight + prevPieceHeight + creditsViewHeight + descriptionHeight + 100)
        
        view.addSubview(scrollView)
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Spruce"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        backButton.setImage(UIImage(named: "spruce-arrow-back"), forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        Glow.addGlow(backButton)
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a custom magic button
        var expandOutfitButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        expandOutfitButton.frame = CGRect(x: 0, y: 0, width: 70, height: 37)
        expandOutfitButton.setTitle("Magic", forState: UIControlState.Normal)
        expandOutfitButton.setTitleColor(UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0), forState: UIControlState.Normal)
        expandOutfitButton.exclusiveTouch = true
        
        // gesture recognizer
        longPress = UILongPressGestureRecognizer(target: self, action: Selector("longPressed:"))
        
        // add gesture recognizer to button
        expandOutfitButton.addGestureRecognizer(longPress)
        
        var expandOutfitBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: expandOutfitButton)
        
        //newNavItem.rightBarButtonItem = expandOutfitBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
        
        //self.navigationController?.interactivePopGestureRecognizer.delegate = self
    }
    
    func initButtons() {
        // button for confirmation
        confirmButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        confirmButton.frame = CGRect(x: screenWidth - 60, y: screenHeight - 60, width: 50, height: 50)
        confirmButton.setImage(UIImage(named: "spruce-next"), forState: UIControlState.Normal)
        
        Glow.addGlow(confirmButton)
        
        confirmButton.addTarget(self, action: "spruceConfirmed", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(confirmButton)
        
        // magic button
        magicButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        magicButton.frame = CGRect(x: screenWidth - 120, y: screenHeight - 60, width: 50, height: 50)
        magicButton.setImage(UIImage(named: "spruce-original-size"), forState: UIControlState.Normal)
        
        Glow.addGlow(magicButton)
        
        magicButton.addGestureRecognizer(longPress)
        
        self.view.addSubview(magicButton)
        
        // removing an existing piece
        removePieceFeedButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        removePieceFeedButton.setImage(UIImage(named: "spruce-piece-remove"), forState: UIControlState.Normal)
        removePieceFeedButton.frame = CGRect(x: 10, y: screenHeight - 60, width: 50, height: 50)
        
        Glow.addGlow(removePieceFeedButton)
        
        removePieceFeedButton.addTarget(self, action: "toggleDeletePieceCrosses", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(removePieceFeedButton)
        
        // adding a new piece
        addPieceFeedButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        addPieceFeedButton.setImage(UIImage(named: "spruce-piece-add"), forState: UIControlState.Normal)
        addPieceFeedButton.frame = CGRect(x: 70, y: screenHeight - 60, width: 50, height: 50)

        Glow.addGlow(addPieceFeedButton)
        
        addPieceFeedButton.addTarget(self, action: "showAddPieceActionSheet", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.view.addSubview(addPieceFeedButton)
    }
    
    func toggleDeletePieceCrosses() {
        if toggleRemovePieceFeed == false {
            // loop through childControllers and enable deletionCrosses
            for childController in childControllers {
                childController.showDeletionCrosses()
            }
            
            // disable all other buttons 
            addPieceFeedButton.enabled = false
            addPieceFeedButton.alpha = 0.5
            confirmButton.enabled = false
            
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
            addPieceFeedButton.enabled = true
            addPieceFeedButton.alpha = 1.0
            confirmButton.enabled = true
           
            newNavBar.setItems([newNavItem], animated: true)

            // update toggleRemovePiece
            toggleRemovePieceFeed = false
        }
    }
    
    func showAddPieceActionSheet() {
        addRemovePieceActionSheet = UIActionSheet(title: "Which piece would you like to add?", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        
        for buttonName in actionSheetButtonNames {
            addRemovePieceActionSheet.addButtonWithTitle(buttonName.lowercaseString.capitalizeFirst)
        }
        
        addRemovePieceActionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        let buttonName: String = actionSheet.buttonTitleAtIndex(buttonIndex)

        // create a new pieceController based on the buttonName
        let pieceType: String = buttonName.uppercaseString
        var pieceIndex: Int?

        switch buttonName {
            
        case "Head":
            println("Head pressed")
            // append to currentSprucePieces position 0
            pieceIndex = 0
           
        case "Top":
            println("Top pressed")
            
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
            println("Bottom pressed")
            
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
            println("Feet pressed")
            // append to currentSprucePieces last position
            pieceIndex = currentSprucePieceTypes.count
            
        case "Cancel":
            println("Cancel")
            
        default:
            fatalError("Unknown piece entered")
        }
        
        if pieceIndex != nil {
            currentSprucePieceTypes.insert(pieceType, atIndex: pieceIndex!)
            
            let newPieceHeight:CGFloat = 100 // tentative
            
            // create another piece feed
            let sprucePieceFeedController = SprucePieceFeedController(collectionViewLayout: sprucePieceFeedControllerLayout(newPieceHeight), pieceType: pieceType, pieceHeight: newPieceHeight)
            
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
            
            // shift the credits view
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                self.creditsView.frame = CGRect(x: self.creditsView.frame.origin.x, y: self.creditsView.frame.origin.y + newPieceHeight, width: self.creditsView.frame.width, height: self.creditsView.frame.height)
                
                }, completion: nil)
            
            // increase height of scrollview
            scrollView.contentSize.height = scrollView.contentSize.height + newPieceHeight
            
            // update actionSheetButtonNames
            var position = find(actionSheetButtonNames, buttonName.uppercaseString)
            
            if position != nil {
                actionSheetButtonNames.removeAtIndex(position!)
                
                if actionSheetButtonNames.count <= 0 {
                    // empty, hide add pieces button
                    addPieceFeedButton.hidden = true
                }
            }
            
            // check if there are still childControllers
            if childControllers.count > 0 {
                // as long as there is at least 1
                removePieceFeedButton.hidden = false
            }
        }
    }
    
    func spruceConfirmed() {
        var images:[UIImage] = [UIImage]()
        var totalHeight:CGFloat = 0
        var width:CGFloat = screenWidth
        
        for childController in childControllers {
            let currentVisibleCell = childController.currentVisibleCell as SprucePieceFeedCell
            
            images.append(currentVisibleCell.pieceImageView.image!)
            
            totalHeight += currentVisibleCell.pieceHeight
        }
        
        // create the merged image
        var size:CGSize = CGSizeMake(width, totalHeight)
        var prevHeight:CGFloat = 0
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0) // avoid image quality degrading
        
        for image in images {
            image.drawInRect(CGRectMake(0, prevHeight, size.width, image.size.height))
            
            prevHeight += image.size.height
        }
        
        // final image
        var finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        // set SpruceShareViewController's outfitImageView image to be finalImage
        let spruceShareViewController = SpruceShareViewController()
        
        spruceShareViewController.outfitImageView.frame = CGRect(x: 0, y: 0, width: finalImage.size.width, height: finalImage.size.height)
        spruceShareViewController.outfitImageView.image = finalImage
        spruceShareViewController.usernameFrom = usernameFrom
        spruceShareViewController.userThumbnailFrom = userThumbnailFrom
        
        if descriptionText.text != placeholderText {
            spruceShareViewController.descriptionCellText = descriptionText.text
        }
        
        self.navigationController?.pushViewController(spruceShareViewController, animated: true)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
        delegate?.dismissSpruceView()
    }
    
    func expandOutfit() {
        var prevHeight:CGFloat = 0
        
        // resize the heights of the viewcontrollers
        for childController in self.childControllers {
            let currentVisibleCell = childController.currentVisibleCell as SprucePieceFeedCell
            
            let height:CGFloat = currentVisibleCell.pieceHeight
            
            // smooth animation
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                childController.pieceHeight = height
                
                // setting the new views
                childController.collectionView?.collectionViewLayout.invalidateLayout()
                
                childController.view.frame = CGRect(x: childController.view.frame.origin.x, y: prevHeight + navigationHeight, width: childController.view.frame.width, height: height)
                
                // moving the arrows to their new positions
                childController.setLeftArrowButtonFrame(height)
                childController.setRightArrowButtonFrame(height)
                
                prevHeight += height
                
                }, completion:{ finished in
                
                    if finished {
                        childController.collectionView?.setCollectionViewLayout(self.sprucePieceFeedControllerLayout(height), animated: true)
                    }
                })
        }
        
        // shift the credits and description view
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            
            self.creditsView.frame = CGRect(x: self.creditsView.frame.origin.x, y: prevHeight + navigationHeight, width: self.creditsView.frame.width, height: self.creditsView.frame.height)
            
            self.descriptionText.frame = CGRect(x: self.descriptionText.frame.origin.x, y: prevHeight + navigationHeight + self.creditsViewHeight, width: self.descriptionText.frame.width, height: self.descriptionText.frame.height)
            
            }, completion: nil)
    }
    
    func contractOutfit() {
        // revert outfit back to the original height of selected outfit
        // use startingPieceHeights
        var prevHeight:CGFloat = 0
        
        // resize the heights of the viewcontrollers to the original height when spruce begun
        for var i = 0; i < self.childControllers.count ; i++ {
            let childController = self.childControllers[i]
            let height:CGFloat = childController.startingPieceHeight
            
            // smooth animation
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                childController.pieceHeight = height
                
                // setting the new views
                childController.collectionView?.collectionViewLayout.invalidateLayout()
                
                childController.view.frame = CGRect(x: childController.view.frame.origin.x, y: prevHeight + navigationHeight, width: childController.view.frame.width, height: height)
                
                // moving the arrows to their new positions
                childController.setLeftArrowButtonFrame(height)
                childController.setRightArrowButtonFrame(height)
                
                prevHeight += height
                
                }, completion:{ finished in
                    
                    if finished {
                        childController.collectionView?.setCollectionViewLayout(self.sprucePieceFeedControllerLayout(height), animated: true)
                    }
            })
            
        }
        
        // shift the credits view
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            
            self.creditsView.frame = CGRect(x: self.creditsView.frame.origin.x, y: prevHeight + navigationHeight, width: self.creditsView.frame.width, height: self.creditsView.frame.height)
            
            self.descriptionText.frame = CGRect(x: self.descriptionText.frame.origin.x, y: prevHeight + navigationHeight + self.creditsViewHeight, width: self.descriptionText.frame.width, height: self.descriptionText.frame.height)
            
            }, completion: nil)
    }
    
    func longPressed(gesture: UILongPressGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Began {
            // held
            expandOutfit()
        }
        
        if gesture.state == UIGestureRecognizerState.Ended {
            // released
            contractOutfit()
        }
    }
    
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
            
            // shift the credits view
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                
                self.creditsView.frame = CGRect(x: self.creditsView.frame.origin.x, y: self.creditsView.frame.origin.y - deleteChildController.pieceHeight, width: self.creditsView.frame.width, height: self.creditsView.frame.height)
                
                }, completion: nil)
            
            // 2. add the removed childcontroller piecetype back to actionSheetButtonNames
            if childControllers.count <= 0 {
                // empty, remove the removeSprucePieceFeed button
                removePieceFeedButton.hidden = true
                toggleDeletePieceCrosses()
            }
            
            // decrease height of scrollview
            scrollView.contentSize.height = scrollView.contentSize.height - deleteChildController.pieceHeight
            
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
                    addPieceFeedButton.hidden = false
                }
            }
            
            deleteChildController.view.removeFromSuperview()
            deleteChildController.view = nil
            deleteChildController.removeFromParentViewController()
        }
    }
    
    func sprucePieceFeedControllerLayout (itemHeight: CGFloat) -> UICollectionViewFlowLayout {
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
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView.text == placeholderText {
            descriptionText.text = ""
            descriptionText.textColor = UIColor.blackColor()
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            descriptionText.text = "Tell us more about this outfit!"
            descriptionText.textColor = UIColor.lightGrayColor()
            descriptionText.resignFirstResponder()
        }
    }
    
    /**
    * Handler for keyboard show event
    */
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardVisible {
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in

                self.scrollView.frame.origin.y -= keyboardFrame.height
                self.keyboardVisible = true
                
                }, completion: nil)
        }
    }
    
    /**
    * Handler for keyboard hide event
    */
    func keyboardWillHide(notification: NSNotification) {
        if keyboardVisible {
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
            
            UIView.animateWithDuration(0.2, delay: 0.1, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.scrollView.frame.origin.y += keyboardFrame.height
                self.keyboardVisible = false
                
                }, completion: nil)
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
