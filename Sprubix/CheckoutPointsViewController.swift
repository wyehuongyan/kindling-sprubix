//
//  CheckoutPointsViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 14/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking

class CheckoutPointsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let checkoutPointsItemCellIdentifier = "CheckoutPointsItemCell"
    let checkoutPointsIndividualSectionHeaderIdentifier = "CheckoutPointsIndividualSectionHeader"
    let checkoutPointsSectionHeaderIdentifier = "CheckoutPointsSectionHeader"
    let checkoutPointsSectionFooterIdentifier = "CheckoutPointsSectionFooter"
    
    var pointsHeaderView: UIView!
    var pointsTotal: Float = 0
    
    var parentOutfitDict: NSMutableDictionary?
    var outfitsPointsData: NSMutableDictionary = NSMutableDictionary()
    var outfitsContributorsData: NSMutableDictionary = NSMutableDictionary()
    var outfitIds = [Int]()
    var outfits: NSMutableDictionary?
    var pieces: [NSDictionary] = [NSDictionary]()
    
    var cartViewController: CartViewController?
    var checkoutViewController: CheckoutViewController?
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    @IBOutlet var checkoutPointsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        checkoutPointsTableView.dataSource = self
        checkoutPointsTableView.delegate = self
        checkoutPointsTableView.backgroundColor = sprubixGray
        checkoutPointsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        formatCheckoutPoints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        initPointsHeader()
        
        self.checkoutPointsTableView.reloadData()
    }
    
    func initPointsHeader() {
        // set up order total view
        pointsHeaderView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeaderAndStatusbarHeight))
        
        pointsHeaderView.backgroundColor = sprubixGray
        
        let labelContainer = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        labelContainer.backgroundColor = UIColor.whiteColor()
        
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotal.textColor = sprubixColor
        grandTotal.text = "Points Total"
        
        var grandTotalAmount: UILabel = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = sprubixColor
        grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotalAmount.text = String(format: "%.0f", pointsTotal)
        
        labelContainer.addSubview(grandTotal)
        labelContainer.addSubview(grandTotalAmount)
        
        pointsHeaderView.addSubview(labelContainer)
        
        checkoutPointsTableView.tableFooterView = pointsHeaderView
    }
    
    func formatCheckoutPoints() {
        if parentOutfitDict != nil {
            var individuallyAddedItems: NSDictionary? = parentOutfitDict?.objectForKey(0) as? NSDictionary
            
            // individually added items should be at the bottom of the table
            if individuallyAddedItems != nil {
                var checkoutPointsDict = NSDictionary(object: individuallyAddedItems!.allKeys, forKey: 0)
                
                outfitIds.append(0)
            }
            
            pointsTotal = 0
            outfitsPointsData.removeAllObjects()
            
            // loop through parentOutfitDict and prepend to checkoutPointsArray
            for (parentOutfitId, piecesKeyCartItemsDict) in parentOutfitDict! {
                if parentOutfitId as! Int != 0 {
                    outfitIds.insert(parentOutfitId as! Int, atIndex: 0)
                }
                
                // calculate total price for each piece id
                var outfitTotalPrice: Float = 0
                var boughtPieceIds: [Int] = [Int]()
                
                for (piece, cartItems) in piecesKeyCartItemsDict as! NSDictionary {
                    var totalQuantity = 0
                    
                    // loop through all cartItems for this piece to obtain total quantity
                    for cartItem in cartItems as! [NSDictionary] {
                        let quantity = cartItem["quantity"] as! Int
                        
                        totalQuantity += quantity
                    }
                    
                    let price = (piece["price"] as! NSString).floatValue
                    let pieceTotalPrice = Float(totalQuantity) * price
                    outfitTotalPrice += pieceTotalPrice
                    
                    boughtPieceIds.append(piece["id"] as! Int)
                }
                
                var outfitPointsData = NSMutableDictionary()
                outfitPointsData.setObject(outfitTotalPrice, forKey: "outfit_price")
                
                var percentEntitlement: Float = 0.00
                let numUniquePieces = piecesKeyCartItemsDict.allKeys.count

                outfitPointsData.setObject(numUniquePieces, forKey: "num_unique_pieces")
                
                // buyer total points entitlement
                if numUniquePieces > 1 {
                    percentEntitlement = 0.03
                    
                    if numUniquePieces > 2 {
                        percentEntitlement = 0.04
                        
                        if numUniquePieces > 3 {
                            percentEntitlement = 0.05
                        }
                    }
                }
                
                outfitPointsData.setObject(percentEntitlement, forKey: "percent_entitlement")
                
                // calculate points earned
                var pointsEarned = (percentEntitlement * outfitTotalPrice) * 100
                
                outfitPointsData.setObject(pointsEarned, forKey: "points_earned")
                pointsTotal += pointsEarned
                
                // contributors total points entitlement
                var outfitContributorData = NSMutableDictionary()
                var contributorPointsEarned = (0.01 * outfitTotalPrice) * 100
                
                outfitContributorData.setObject(contributorPointsEarned, forKey: "contributor_points_earned")
                outfitContributorData.setObject(boughtPieceIds, forKey: "bought_piece_ids")
                
                // set
                outfitsPointsData.setObject(outfitPointsData, forKey: parentOutfitId as! Int)
                outfitsContributorsData.setObject(outfitContributorData, forKey: "\(parentOutfitId)")
            }
        }
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "Points Earned"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        //var backButtonView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: backButton.frame.width, height: backButton.frame.height))
        //backButtonView.addSubview(backButton)
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("continue", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 80, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "continueCheckout:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }

    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return outfitIds.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return (parentOutfitDict!.objectForKey(outfitIds[section]) as! NSDictionary).count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cell: UITableViewCell?
        
        let outfitId = outfitIds[section] as Int
        var outfit = outfits?.objectForKey(outfitId) as? NSDictionary
        
        if outfit == nil {
            cell = tableView.dequeueReusableCellWithIdentifier(checkoutPointsIndividualSectionHeaderIdentifier) as! CheckoutPointsIndividualSectionHeader
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(checkoutPointsSectionHeaderIdentifier) as! CheckoutPointsSectionHeader
            
            // assign image
            var outfitImagesString = outfit!["images"] as! NSString
            var outfitImagesData:NSData = outfitImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var outfitImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(outfitImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
            var outfitImageDict: NSDictionary = outfitImagesDict["images"] as! NSDictionary
            
            var imageURLString = outfitImageDict["thumbnail"] as! String

            (cell as! CheckoutPointsSectionHeader).outfitImageView.setImageWithURL(NSURL(string: imageURLString))
            
            (cell as! CheckoutPointsSectionHeader).tappedOnOutfitAction = { Void in
            
                // REST call to server to retrieve outfit
                manager.POST(SprubixConfig.URL.api + "/outfits",
                    parameters: [
                        "id": outfitId
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                        
                        var outfit = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                        
                        let outfitDetailsViewController = OutfitDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                        
                        outfitDetailsViewController.outfits = [outfit]
                        outfitDetailsViewController.delegate = containerViewController.mainInstance()
                        
                        // push outfitDetailsViewController onto navigation stack
                        let transition = CATransition()
                        transition.duration = 0.3
                        transition.type = kCATransitionMoveIn
                        transition.subtype = kCATransitionFromTop
                        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                        
                        self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
                        self.navigationController!.pushViewController(outfitDetailsViewController, animated: false)
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
                
                return
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return navigationHeight
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let outfitId = outfitIds[section] as Int
        var outfit = outfits?.objectForKey(outfitId) as? NSDictionary
        
        if outfit != nil {
            let cell = tableView.dequeueReusableCellWithIdentifier(checkoutPointsSectionFooterIdentifier) as! CheckoutPointsSectionFooter
            
            let outfitId = outfitIds[section] as Int
            let outfitPointsData = outfitsPointsData[outfitId] as! NSDictionary
            
            let percentEntitlement = outfitPointsData["percent_entitlement"] as? Float
            let numUniquePieces = outfitPointsData["num_unique_pieces"] as? Int
            let outfitPrice = outfitPointsData["outfit_price"] as? Float
            let pointsEarned = outfitPointsData["points_earned"] as? Float
            
            if numUniquePieces != nil && percentEntitlement != nil {
                let formattedPercentEntitlement = String(format: "%.0f", percentEntitlement! * 100)
                
                var title = "You've earned \(formattedPercentEntitlement)% (\(numUniquePieces!)"
                title += numUniquePieces > 1 ? " items)" : " item)"
                
                cell.pointsEntitlement.setTitle(title, forState: UIControlState.Normal)
            }
            
            if outfitPrice != nil {
                cell.subtotal.text = String(format: "$%.2f", outfitPrice!)
            }
            
            if pointsEarned != nil {
                cell.points.text = String(format: "%.0f", pointsEarned!)
            }
            
            return cell
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let outfitId = outfitIds[section] as Int
        var outfit = outfits?.objectForKey(outfitId) as? NSDictionary
        
        if outfit != nil {
            return 86.0
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(checkoutPointsItemCellIdentifier, forIndexPath: indexPath) as! CheckoutPointsItemCell
        
        let outfitId = outfitIds[indexPath.section] as Int
        let piecesKeyCartItemsDict = parentOutfitDict?.objectForKey(outfitId) as! NSDictionary
        let pieces = piecesKeyCartItemsDict.allKeys
        let piece = pieces[indexPath.row] as! NSDictionary
        let cartItems = piecesKeyCartItemsDict[piece] as! [NSDictionary]
        
        var totalQuantity = 0
        
        // loop through all cartItems for this piece to obtain total quantity
        for cartItem in cartItems {
            let quantity = cartItem["quantity"] as! Int
            
            totalQuantity += quantity
        }
        
        let price = (piece["price"] as! NSString).floatValue
        let totalPrice = Float(totalQuantity) * price
        
        let pieceImagesString = piece["images"] as! NSString
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
        
        let thumbnailURLString = pieceImageDict["thumbnail"] as! String
        let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
        
        cell.name.text = piece["name"] as? String
        cell.quantity.text = "Quantity: \(totalQuantity)"
        cell.price.text = String(format: "$%.2f", totalPrice)
        cell.itemImageView.setImageWithURL(pieceImageURL)
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func detailsViewControllerLayout () -> UICollectionViewFlowLayout {
        let flowLayout = UICollectionViewFlowLayout()
        
        let itemSize = CGSizeMake(screenWidth, screenHeight)
        
        flowLayout.itemSize = itemSize
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .Horizontal
        
        return flowLayout
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func continueCheckout(sender: UIBarButtonItem) {
        if checkoutViewController == nil {
            checkoutViewController = UIStoryboard.checkoutViewController()
        }
        
        checkoutViewController?.sellerCartItemDictionary = cartViewController?.sellerCartItemDictionary
        checkoutViewController?.sellers = cartViewController!.sellers
        checkoutViewController?.sellerDeliveryMethods = cartViewController!.sellerDeliveryMethods
        checkoutViewController?.sellerDeliveryMethodIds = cartViewController!.sellerDeliveryMethodIds
        checkoutViewController?.sellerSubtotal = cartViewController!.sellerSubtotal
        checkoutViewController?.sellerShippingRate = cartViewController!.sellerShippingRate
        checkoutViewController?.orderTotal = cartViewController?.grandTotal
        checkoutViewController?.pointsTotal = pointsTotal
        checkoutViewController?.outfitsContributorsData = outfitsContributorsData
        
        checkoutViewController?.delegate = cartViewController?.delegate
        
        self.navigationController?.pushViewController(checkoutViewController!, animated: true)
        
        // Mixpanel - Viewed Checkout
        mixpanel.track("Viewed Checkout")
        // Mixpanel - End
    }
}
