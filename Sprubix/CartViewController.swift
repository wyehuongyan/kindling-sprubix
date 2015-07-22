//
//  CartViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 30/6/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import DZNEmptyDataSet
import KLCPopup
import ActionSheetPicker_3_0
import TSMessages

class CartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var delegate: SidePanelViewControllerDelegate?
    var cartData: NSDictionary = NSDictionary()

    var sellerCartItemDictionary: NSMutableDictionary = NSMutableDictionary()
    var sellers: [NSDictionary] = [NSDictionary]()
    var sellerDeliveryMethods: [String] = [String]()
    var sellerSubtotal: [Float] = [Float]()
    var sellerShippingRate: [Float] = [Float]()
    
    let cartItemCellIdentifier = "CartItemCell"
    let cartItemSectionHeaderIdentifier = "CartItemSectionHeader"
    let cartItemSectionFooterIdentifier = "CartItemSectionFooter"
    
    // buy
    var itemBuySizeLabel: UILabel!
    var itemBuyQuantityLabel: UILabel!
    var itemBuyDeliveryLabel: UILabel!
    
    var deliveryMethods: [NSDictionary]?
    var buyPieceInfo: NSMutableDictionary?
    var buyPopup: KLCPopup?
    
    var selectedSize: String?
    var darkenedOverlay: UIView?
    var currentEditPiece: NSDictionary!
    var currentSeller: NSDictionary!
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    var tableFooterView: UIView!
    var grandTotalAmount: UILabel!
    
    @IBOutlet var cartTableView: UITableView!
    
    // checkout
    var checkoutViewController: CheckoutViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = sprubixGray
        
        // empty dataset
        cartTableView.emptyDataSetSource = self
        cartTableView.emptyDataSetDelegate = self
        
        // get rid of line seperator for empty cells
        cartTableView.backgroundColor = sprubixGray
        cartTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // add table footerview
        tableFooterView = UIView(frame: CGRectMake(0, 0, screenWidth, navigationHeight))
        
        tableFooterView.backgroundColor = UIColor.whiteColor()
        
        let grandTotal = UILabel(frame: CGRectMake(10, 10, screenWidth / 2 - 10, 24))
        
        grandTotal.font = UIFont.boldSystemFontOfSize(20.0)
        grandTotal.textColor = sprubixColor
        grandTotal.text = "Order Total"
        
        grandTotalAmount = UILabel(frame: CGRectMake(screenWidth / 2, 10, screenWidth / 2 - 10, 24))
        grandTotalAmount.textAlignment = NSTextAlignment.Right
        grandTotalAmount.textColor = sprubixColor
        grandTotalAmount.font = UIFont.boldSystemFontOfSize(20.0)
        
        tableFooterView.addSubview(grandTotal)
        tableFooterView.addSubview(grandTotalAmount)
        tableFooterView.alpha = 0.0
        
        cartTableView.tableFooterView = tableFooterView
        
        retrieveCartItems()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        
        if darkenedOverlay == nil {
            // manual dim background because of TSMessage being blocked
            darkenedOverlay = UIView(frame: CGRectMake(0, 0, screenWidth, screenHeight))
            darkenedOverlay?.backgroundColor = UIColor.blackColor()
            darkenedOverlay?.alpha = 0
            
            view.addSubview(darkenedOverlay!)
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

        let cartItemData = cartData["cart_items"] as? [NSDictionary]
        newNavItem.title = cartItemData != nil ? "My Cart (\(cartItemData!.count))" : "My Cart"
        
        // 4. create a custom back button
        var backButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var image: UIImage = UIImage(named: "spruce-arrow-back")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        backButton.setImage(image, forState: UIControlState.Normal)
        backButton.frame = CGRect(x: -10, y: 0, width: 20, height: 20)
        backButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        backButton.imageView?.tintColor = UIColor.lightGrayColor()
        backButton.addTarget(self, action: "backTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        backButton.exclusiveTouch = true
        
        var backBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: backButton)
        backBarButtonItem.tintColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1.0)
        
        newNavItem.leftBarButtonItem = backBarButtonItem
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("checkout", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 80, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "checkout:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        newNavItem.rightBarButtonItem = nextBarButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 5. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "\nItems ready for checkout"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text: String = "When you add an item to the cart, you'll see it here."
        
        var paragraph: NSMutableParagraphStyle = NSMutableParagraphStyle.new()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = NSTextAlignment.Center
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(14.0),
            NSForegroundColorAttributeName: UIColor.lightGrayColor(),
            NSParagraphStyleAttributeName: paragraph
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    /*func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        let text: String = "Button Title"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(17.0)
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }*/
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "emptyset-cart")
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sellers.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let seller = sellers[section] as NSDictionary
        
        return sellerCartItemDictionary.objectForKey(seller)!.count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionHeaderIdentifier) as! CartItemSectionHeader
        
        let seller = sellers[section] as NSDictionary
        let pieceImagesString = seller["image"] as! String
        let pieceImageURL: NSURL = NSURL(string: pieceImagesString)!
        let sellerId = seller["id"] as! Int
        
        cell.sellerImageView.setImageWithURL(pieceImageURL)
        cell.sellerName.text = seller["username"] as? String
        
        cell.tappedOnSellerAction = { Void in
            self.delegate?.showUserProfile(seller)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return navigationHeight
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemSectionFooterIdentifier) as! CartItemSectionFooter
        
        let sellerDeliveryMethod = sellerDeliveryMethods[section] as String
    
        cell.deliveryMethod.setTitle(sellerDeliveryMethod, forState: UIControlState.Normal)
        cell.subtotal.text = String(format: "$%.2f", sellerSubtotal[section])
        cell.shippingRate.text = String(format: "$%.2f", sellerShippingRate[section])
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 86.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cartItemCellIdentifier, forIndexPath: indexPath) as! CartItemCell
        
        let seller = sellers[indexPath.section] as NSDictionary
        let cartItems = sellerCartItemDictionary[seller] as! [NSDictionary]
        let cartItem = cartItems[indexPath.row] as NSDictionary
        
        let piece = cartItem["piece"] as! NSDictionary
        let price = piece["price"] as! NSString
        let quantity = cartItem["quantity"] as! Int
        let size = cartItem["size"] as? String

        cell.cartItemName.text = piece["name"] as? String
        cell.cartItemPrice.text = String(format: "$%.2f", price.floatValue * Float(quantity))
        cell.cartItemQuantity.text = "Quantity: \(quantity)"
        cell.cartItemSize.text = "Size: \(size!)"
        
        let pieceId = piece["id"] as! Int
        let pieceImagesString = piece["images"] as! NSString
        let pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        let pieceImageDict: NSDictionary = (pieceImagesDict["images"] as! NSArray)[0] as! NSDictionary // position 0 is the cover
        
        let thumbnailURLString = pieceImageDict["thumbnail"] as! String
        let pieceImageURL: NSURL = NSURL(string: thumbnailURLString)!
        
        cell.cartItemImageView.setImageWithURL(pieceImageURL)
        
        cell.editCartItemAction = { Void in
            
            // KLCPopup
            self.editCartItemDetails(piece, cartItem: cartItem, seller: seller)
            
            return
        }
        
        cell.deleteCartItemAction = { Void in
            
            var alert = UIAlertController(title: "Confirm delete?", message: "This action cannot be undone", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Yes
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: { action in
                
                let cartItemId = cartItem["id"] as! Int
                
                // REST to server to delete item from cart
                self.deleteCartItem(cartItemId)
            }))
            
            // No
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        cell.tappedOnImageAction = { Void in
            
            println("Piece \(pieceId)'s item image tapped")
            
            manager.POST(SprubixConfig.URL.api + "/pieces",
                parameters: [
                    "id": pieceId
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    
                    var piece = (responseObject["data"] as! NSArray)[0] as! NSDictionary
                    
                    let pieceDetailsViewController = PieceDetailsViewController(collectionViewLayout: self.detailsViewControllerLayout(), currentIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                    
                    pieceDetailsViewController.pieces = [piece]
                    pieceDetailsViewController.user = piece["user"] as! NSDictionary
                    
                    // push outfitDetailsViewController onto navigation stack
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = kCATransitionMoveIn
                    transition.subtype = kCATransitionFromTop
                    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    
                    self.navigationController?.view.layer.addAnimation(transition, forKey: kCATransition)
                    self.navigationController!.pushViewController(pieceDetailsViewController, animated: false)
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func retrieveCartItems() {
        // REST call to server to create cart item and add to user's cart
        manager.GET(SprubixConfig.URL.api + "/cart",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject:
                AnyObject!) in
                
                self.cartData = responseObject as! NSDictionary
                
                self.formatCartItemData()
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func formatCartItemData() {
        // reset all
        sellerCartItemDictionary.removeAllObjects()
        sellers.removeAll()
        sellerDeliveryMethods.removeAll()
        sellerSubtotal.removeAll()
        sellerShippingRate.removeAll()
        
        let cartItemData = cartData["cart_items"] as! [NSDictionary]

        if cartItemData.count > 0 {
            // set navbar title
            newNavItem.title = "My Cart (\(cartItemData.count))"
            
            for cartItem in cartItemData {
                let seller = cartItem["seller"] as! NSDictionary
                
                var cartItems: [NSDictionary]? = sellerCartItemDictionary.objectForKey(seller) as? [NSDictionary]
                
                if cartItems == nil {
                    cartItems = [NSDictionary]()
                }
                
                cartItems?.append(cartItem)
                
                // formatted into key: seller, value: [cartItem, cartItem]
                sellerCartItemDictionary.setObject(cartItems!, forKey: seller)
            }
            
            var grandTotal: Float = 0
            
            for (seller, cartItems) in sellerCartItemDictionary {
                sellers.append(seller as! NSDictionary)
                
                var highestDeliveryOption: String = ""
                var highestDeliveryOptionCost: Float = 0
                var subtotal: Float = 0
                
                for cartItem in cartItems as! [NSDictionary] {
                    // compare delivery costs
                    // // always take the higher cost
                    let deliveryOption = cartItem["delivery_option"] as! NSDictionary

                    let currentDeliveryOptionCost = (deliveryOption["price"] as! NSString).floatValue
                    
                    if currentDeliveryOptionCost > highestDeliveryOptionCost {
                        highestDeliveryOptionCost = currentDeliveryOptionCost
                        highestDeliveryOption = deliveryOption["name"] as! String
                    }
                    
                    // add up costs of items
                    let piece = cartItem["piece"] as! NSDictionary
                    let quantity = cartItem["quantity"] as! Int
                    subtotal += (piece["price"] as! NSString).floatValue * Float(quantity)
                }
                
                sellerDeliveryMethods.append(highestDeliveryOption)
                sellerShippingRate.append(highestDeliveryOptionCost)
                sellerSubtotal.append(subtotal)
                
                grandTotal += subtotal + highestDeliveryOptionCost
            }
            
            cartTableView.reloadData()
            
            // set grandTotalAmount and refresh tableFooterView
            grandTotalAmount.text = String(format: "$%.2f", grandTotal)
            tableFooterView.setNeedsLayout()
            tableFooterView.alpha = 1.0
        } else {
            println("Cart is empty")
            
            cartTableView.reloadData()
            tableFooterView.alpha = 0.0
        }
    }
    
    func deleteCartItem(cartItemId: Int) {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // REST call to server to delete user shipping address
            manager.DELETE(SprubixConfig.URL.api + "/cart/item/\(cartItemId)",
                parameters: [
                    "owner_id": userId!
                ],
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Delivery address deleted", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.retrieveCartItems()
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    var automatic: NSTimeInterval = 0
                    
                    // error exception
                    TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Server is experiencing some issues.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
            })
        } else {
            println("userId not found, please login or create an account")
        }
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
    
    func editCartItemDetails(piece: NSDictionary, cartItem: NSDictionary, seller: NSDictionary) {
        
        currentEditPiece = piece
        currentSeller = seller
        
        // add info into buyPieceInfo
        buyPieceInfo = NSMutableDictionary()
        buyPieceInfo?.setObject(piece["id"] as! Int, forKey: "piece_id")
        buyPieceInfo?.setObject(seller["id"] as! Int, forKey: "seller_id")
        buyPieceInfo?.setObject(cartItem["id"] as! Int, forKey: "id")
        
        let quantity = cartItem["quantity"] as! Int
        buyPieceInfo?.setObject(quantity, forKey: "quantity")
        
        let size = cartItem["size"] as? String
        selectedSize = size
        buyPieceInfo?.setObject(selectedSize!, forKey: "size")
        
        let deliveryOption = cartItem["delivery_option"] as! NSDictionary
        let deliveryOptionId = deliveryOption["id"] as! Int
        let deliveryOptionName = deliveryOption["name"] as! String
        let deliveryOptionPrice = deliveryOption["price"] as! String
        let deliveryOptionText = "\(deliveryOptionName) ($\(deliveryOptionPrice))"
        buyPieceInfo?.setObject(deliveryOptionId, forKey: "delivery_option_id")
        
        let itemSpecHeight:CGFloat = 45
        let popupWidth: CGFloat = screenWidth - 100
        let popupHeight: CGFloat = popupWidth + itemSpecHeight * 3 + navigationHeight
        let itemImageViewWidth:CGFloat = 0.25 * popupWidth
        
        let popupContentView: UIView = UIView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        popupContentView.backgroundColor = UIColor.whiteColor()
        popupContentView.layer.cornerRadius = 12.0
        
        let buyPieceView: UIView = UIView(frame: popupContentView.bounds)
        
        // add content to popupContentView
        var buyPiecesScrollView = UIScrollView(frame: CGRectMake(0, 0, popupWidth, popupHeight))
        buyPiecesScrollView.layer.cornerRadius = 12.0
        buyPiecesScrollView.pagingEnabled = true
        buyPiecesScrollView.alwaysBounceHorizontal = true
        
        var pieceImagesString = piece["images"] as! String
        var pieceImagesData:NSData = pieceImagesString.dataUsingEncoding(NSUTF8StringEncoding)!
        
        var pieceImagesDict: NSDictionary = NSJSONSerialization.JSONObjectWithData(pieceImagesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
        
        let imageURL = NSURL(string: pieceImagesDict["cover"] as! String)
        
        // cover image
        var buyPieceImage: UIImageView = UIImageView(frame: CGRectMake(0, 0, popupWidth, popupWidth))
        buyPieceImage.backgroundColor = sprubixGray
        buyPieceImage.contentMode = UIViewContentMode.ScaleAspectFit
        buyPieceImage.setImageWithURL(imageURL)
        
        // price label
        let padding: CGFloat = 10
        let priceLabelHeight: CGFloat = 35
        var buyPriceLabel = UILabel()
        buyPriceLabel.textAlignment = NSTextAlignment.Center
        buyPriceLabel.font = UIFont.boldSystemFontOfSize(18.0)
        
        let price = piece["price"] as! String
        buyPriceLabel.text = "$\(price)"
        buyPriceLabel.frame = CGRectMake(buyPieceImage.frame.width - (buyPriceLabel.intrinsicContentSize().width + 20.0) - padding, padding, (buyPriceLabel.intrinsicContentSize().width + 20.0), priceLabelHeight)
        
        buyPriceLabel.layer.cornerRadius = priceLabelHeight / 2
        buyPriceLabel.clipsToBounds = true
        buyPriceLabel.textColor = UIColor.whiteColor()
        buyPriceLabel.backgroundColor = sprubixColor
        
        buyPieceImage.addSubview(buyPriceLabel)
        
        buyPieceView.addSubview(buyPieceImage)
        
        // size
        var itemSizeImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemSizeImage.setImage(UIImage(named: "view-item-size"), forState: UIControlState.Normal)
        itemSizeImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemSizeImage.frame = CGRect(x: 0, y: popupWidth, width: itemImageViewWidth, height: itemSpecHeight)
        itemSizeImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemSizeImage)
        
        var itemSizeButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuySizeLabel = UILabel(frame: itemSizeButton.bounds)
        itemBuySizeLabel.text = size
        itemBuySizeLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuySizeLabel.textColor = UIColor.lightGrayColor()
        
        itemSizeButton.addSubview(itemBuySizeLabel)
        itemSizeButton.addTarget(self, action: "selectBuySize:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // quantity
        var itemQuantityImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        itemQuantityImage.setImage(UIImage(named: "view-item-quantity"), forState: UIControlState.Normal)
        itemQuantityImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemQuantityImage.frame = CGRect(x: 0, y: popupWidth + itemSpecHeight, width: itemImageViewWidth, height: itemSpecHeight)
        itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemQuantityImage)
        
        var itemQuantityButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth + itemSpecHeight, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuyQuantityLabel = UILabel(frame: itemQuantityButton.bounds)
        itemBuyQuantityLabel.text = "\(quantity)"
        itemBuyQuantityLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuyQuantityLabel.textColor = UIColor.lightGrayColor()
        
        itemQuantityButton.addSubview(itemBuyQuantityLabel)
        itemQuantityButton.addTarget(self, action: "selectBuyQuantity:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // delivery method
        var itemDeliveryImage = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        var deliveryImage: UIImage = UIImage(named: "sidemenu-fulfilment")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        itemDeliveryImage.setImage(deliveryImage, forState: UIControlState.Normal)
        itemDeliveryImage.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        itemDeliveryImage.imageView?.tintColor = UIColor.whiteColor()
        itemDeliveryImage.frame = CGRect(x: 0, y: popupWidth + itemSpecHeight * 2, width: itemImageViewWidth, height: itemSpecHeight)
        itemQuantityImage.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0)
        
        Glow.addGlow(itemDeliveryImage)
        
        var itemDeliveryButton: UIButton = UIButton(frame: CGRect(x: itemImageViewWidth, y: popupWidth + itemSpecHeight * 2, width: popupWidth - itemImageViewWidth, height: itemSpecHeight))
        itemBuyDeliveryLabel = UILabel(frame: itemDeliveryButton.bounds)
        itemBuyDeliveryLabel.text = deliveryOptionText
        itemBuyDeliveryLabel.font = UIFont.systemFontOfSize(14.0)
        itemBuyDeliveryLabel.textColor = UIColor.lightGrayColor()
        
        itemDeliveryButton.addSubview(itemBuyDeliveryLabel)
        itemDeliveryButton.addTarget(self, action: "selectBuyDeliveryMethod:", forControlEvents: UIControlEvents.TouchUpInside)
        
        buyPieceView.addSubview(itemSizeImage)
        buyPieceView.addSubview(itemSizeButton)
        
        buyPieceView.addSubview(itemQuantityImage)
        buyPieceView.addSubview(itemQuantityButton)
        
        buyPieceView.addSubview(itemDeliveryImage)
        buyPieceView.addSubview(itemDeliveryButton)
        
        buyPiecesScrollView.addSubview(buyPieceView)
        popupContentView.addSubview(buyPiecesScrollView)
        
        // add to cart button
        var addToCart: UIButton = UIButton(frame: CGRectMake(0, popupHeight - navigationHeight, popupWidth, navigationHeight))
        addToCart.backgroundColor = sprubixColor
        addToCart.setTitle("Update Item", forState: UIControlState.Normal)
        addToCart.titleLabel?.font = UIFont.boldSystemFontOfSize(addToCart.titleLabel!.font.pointSize)
        addToCart.addTarget(self, action: "updateCartItemPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        buyPieceView.addSubview(addToCart)
        
        buyPopup = KLCPopup(contentView: popupContentView, showType: KLCPopupShowType.BounceInFromTop, dismissType: KLCPopupDismissType.BounceOutToTop, maskType: KLCPopupMaskType.Clear, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        
        // dim background
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            darkenedOverlay?.alpha = 0.5
            }, completion: nil)
        
        buyPopup?.willStartDismissingCompletion = {
            // brighten background
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                darkenedOverlay?.alpha = 0.0
                }, completion: nil)
            
            self.selectedSize = nil
        }
        
        buyPopup?.show()
    }
    
    func selectBuySize(sender: UIButton) {
        var pieceSizesString = currentEditPiece["size"] as? String
        
        if pieceSizesString != nil {
            var pieceSizesData:NSData = pieceSizesString!.dataUsingEncoding(NSUTF8StringEncoding)!
            
            var pieceSizesArray: NSArray = NSJSONSerialization.JSONObjectWithData(pieceSizesData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSArray
            
            let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Size", rows: pieceSizesArray as! [String], initialSelection: 0,
                doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                    
                    // add info to buyPieceInfo
                    self.buyPieceInfo?.setObject(selectedValue, forKey: "size")
                    
                    self.itemBuySizeLabel.text = "\(selectedValue)"
                    self.itemBuySizeLabel.textColor = UIColor.blackColor()
                    
                    self.selectedSize = selectedValue as? String
                    
                }, cancelBlock: nil, origin: sender)
            
            // custom done button
            let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
            
            doneButton.setTitleTextAttributes([
                NSForegroundColorAttributeName: sprubixColor,
                ], forState: UIControlState.Normal)
            
            picker.setDoneButton(doneButton)
            
            // custom cancel button
            var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
            
            cancelButton.setTitle("X", forState: UIControlState.Normal)
            cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
            cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
            
            picker.showActionSheetPicker()
        }
    }
    
    func selectBuyQuantity(sender: UIButton) {
        if selectedSize != nil {
            // create quantity array
            var quantityArray: [Int] = [Int]()
            
            if !currentEditPiece["quantity"]!.isKindOfClass(NSNull) {
                var pieceQuantityString = currentEditPiece["quantity"] as! String
                var pieceQuantityData:NSData = pieceQuantityString.dataUsingEncoding(NSUTF8StringEncoding)!
                
                var pieceQuantityDict = NSJSONSerialization.JSONObjectWithData(pieceQuantityData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
                
                for var i = 1; i <= (pieceQuantityDict[selectedSize!] as! String).toInt(); i++ {
                    quantityArray.append(i)
                }
        
                let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Quantity", rows: quantityArray, initialSelection: 0,
                    doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                        
                        // add info to buyPieceInfo
                        self.buyPieceInfo?.setObject(selectedValue, forKey: "quantity")
                        
                        self.itemBuyQuantityLabel.text = "\(selectedValue)"
                        self.itemBuyQuantityLabel.textColor = UIColor.blackColor()
                        
                    }, cancelBlock: nil, origin: sender)
                
                // custom done button
                let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
                
                doneButton.setTitleTextAttributes([
                    NSForegroundColorAttributeName: sprubixColor,
                    ], forState: UIControlState.Normal)
                
                picker.setDoneButton(doneButton)
                
                // custom cancel button
                var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
                
                cancelButton.setTitle("X", forState: UIControlState.Normal)
                cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
                cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                
                picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
                
                picker.showActionSheetPicker()
            }
        } else {
            println("Please select size first")
        }
    }
    
    func selectBuyDeliveryMethod(sender: UIButton) {
        if deliveryMethods == nil {
            // REST call to server to retrieve delivery methods
            var shopId: Int? = currentSeller["id"] as? Int
            
            if shopId != nil {
                manager.POST(SprubixConfig.URL.api + "/delivery/options",
                    parameters: [
                        "user_id": shopId!
                    ],
                    success: { (operation: AFHTTPRequestOperation!, responseObject:
                        AnyObject!) in
                        
                        self.deliveryMethods = responseObject["data"] as? [NSDictionary]
                        
                        self.showBuyDeliveryMethodPicker(sender)
                    },
                    failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                        println("Error: " + error.localizedDescription)
                })
            } else {
                println("userId not found, please login or create an account")
            }
        } else {
            showBuyDeliveryMethodPicker(sender)
        }
    }

    private func showBuyDeliveryMethodPicker(sender: UIButton) {
        // create delivery array
        var deliveryArray: [String] = [String]()
        var deliveryIdsArray: [Int] = [Int]()
        
        for deliveryOption in deliveryMethods! {
            let deliveryOptionName = deliveryOption["name"] as! String
            let deliveryOptionPrice = deliveryOption["price"] as! String
            let deliveryOptionId = deliveryOption["id"] as! Int
            
            deliveryArray.append("\(deliveryOptionName) ($\(deliveryOptionPrice))")
            deliveryIdsArray.append(deliveryOptionId)
        }
        
        let picker: ActionSheetStringPicker = ActionSheetStringPicker(title: "Delivery method", rows: deliveryArray, initialSelection: 0,
            doneBlock: { actionSheetPicker, selectedIndex, selectedValue in
                
                let selectedDeliveryId = deliveryIdsArray[selectedIndex]
                
                // add info to buyPieceInfo
                self.buyPieceInfo?.setObject(selectedDeliveryId, forKey: "delivery_option_id")
                
                self.itemBuyDeliveryLabel.text = "\(selectedValue)"
                self.itemBuyDeliveryLabel.textColor = UIColor.blackColor()
                
            }, cancelBlock: nil, origin: sender)
        
        // custom done button
        let doneButton = UIBarButtonItem(title: "done", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        
        doneButton.setTitleTextAttributes([
            NSForegroundColorAttributeName: sprubixColor,
            ], forState: UIControlState.Normal)
        
        picker.setDoneButton(doneButton)
        
        // custom cancel button
        var cancelButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        
        cancelButton.setTitle("X", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        picker.setCancelButton(UIBarButtonItem(customView: cancelButton))
        
        picker.showActionSheetPicker()
    }
    
    func updateCartItemPressed(sender: UIButton) {
        let userId: Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil && buyPieceInfo != nil {
            buyPieceInfo?.setObject(userId!, forKey: "buyer_id")
        
            let cartId = buyPieceInfo?.objectForKey("id") as! Int
            
            println(buyPieceInfo)
            
            // REST call to server to create cart item and add to user's cart
            manager.POST(SprubixConfig.URL.api + "/cart/item/edit/\(cartId)",
                parameters: buyPieceInfo!,
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    
                    var status = responseObject["status"] as! String
                    var automatic: NSTimeInterval = 0
                    
                    if status == "200" {
                        // success
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Success!", subtitle: "Item updated", image: UIImage(named: "filter-check"), type: TSMessageNotificationType.Success, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                        
                        self.retrieveCartItems()
                        self.buyPopup?.dismiss(true)
                    } else {
                        // error exception
                        TSMessage.showNotificationInViewController(                        TSMessage.defaultViewController(), title: "Error", subtitle: "Something went wrong.\nPlease try again.", image: UIImage(named: "filter-cross"), type: TSMessageNotificationType.Error, duration: automatic, callback: nil, buttonTitle: nil, buttonCallback: nil, atPosition: TSMessageNotificationPosition.Bottom, canBeDismissedByUser: true)
                    }
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        }
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func checkout(sender: UIBarButtonItem) {
        let cartItemData = cartData["cart_items"] as! [NSDictionary]
        
        if cartItemData.count > 0 {
            if checkoutViewController == nil {
                checkoutViewController = UIStoryboard.checkoutViewController()
            }
            
            checkoutViewController?.sellerCartItemDictionary = sellerCartItemDictionary
            checkoutViewController?.sellers = sellers
            checkoutViewController?.sellerDeliveryMethods = sellerDeliveryMethods
            checkoutViewController?.sellerSubtotal = sellerSubtotal
            checkoutViewController?.sellerShippingRate = sellerShippingRate
            checkoutViewController?.orderTotal = grandTotalAmount.text
            
            checkoutViewController?.delegate = delegate
            
            self.navigationController?.pushViewController(checkoutViewController!, animated: true)
            
            // Mixpanel - Checkout
            mixpanel.track("Checkout")
            // Mixpanel - End
        } else {
            let alert = UIAlertController(title: "Oops!", message: "Your cart is empty! Unable to check out.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.view.tintColor = sprubixColor
            
            // Ok
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
