//
//  SprubixFeedController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 28/2/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

@objc
protocol SprubixFeedControllerDelegate {
    optional func toggleSidePanel()
}

class SprubixFeedController: UIViewController, UITableViewDataSource, UITableViewDelegate, SprubixFeedCellProtocol, SprubixFeedCommentsProtocol, SpruceViewProtocol {
    
    @IBOutlet var sprubixFeedTableView: UITableView!
    
    @IBAction func sidePanel(sender: AnyObject) {
        delegate?.toggleSidePanel!()
    }
    
    var sprubixCommentsController: SprubixFeedCommentsController? // optional as it will be added/removed at times
    var spruceViewController: SpruceViewController?
    
    var indexCellHeight = [CGFloat]()
    var outfits:[NSDictionary] = [NSDictionary]()
    var followingUsers:[NSDictionary] = [NSDictionary]()
    var delegate: SprubixFeedControllerDelegate?
    
    // refresh control
    var refreshControl:UIRefreshControl!
    
    // create outfit custom button
    var createOutfitButton:UIButton!
    
    var lastContentOffset:CGFloat = 0
    var lastNavOffset:CGFloat = 0
    
    // darkened overlay over the view when sidemenu is toggled on
    var darkenedOverlay:UIView?
    
    func loadCookies() {
        var object:NSData? = defaults.objectForKey("sessionCookies") as? NSData
        
        if object != nil {
            let cookies:NSArray = NSKeyedUnarchiver.unarchiveObjectWithData(object!) as NSArray
            for cookie in cookies {
                var c = cookie as NSHTTPCookie
                
                NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookie(c)
                println("persisted cookie:  \(c)")
            }
        }
        
        defaults.removeObjectForKey("sessionCookies")
    }
    
    func retrieveOutfits() {
        let userId:Int? = defaults.objectForKey("userId") as? Int
        
        if userId != nil {
            // retrieve 3 example pieces
            manager.GET(SprubixConfig.URL.api + "/user/\(userId!)/outfits/following",
                parameters: nil,
                success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                    self.followingUsers = responseObject["data"] as [NSDictionary]!

                    // reset
                    self.outfits = [NSDictionary]()
                    
                    for followingUser in self.followingUsers {
                        var currentOutfits = followingUser["outfits"] as [NSDictionary]!
                        
                        for outfit in currentOutfits {
                            self.outfits.append(outfit)
                        }
                    }
                    
                    self.sprubixFeedTableView.reloadData()
                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
            })
        } else {
            println("userId not found, please login or create an account")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //loadCookies()
        
        sprubixFeedTableView.dataSource = self
        sprubixFeedTableView.delegate = self
        sprubixFeedTableView.showsVerticalScrollIndicator = false
        sprubixFeedTableView.separatorColor = UIColor.clearColor()
        
        self.shyNavBarManager.scrollView = self.sprubixFeedTableView
        self.shyNavBarManager.expansionResistance = 20
        self.shyNavBarManager.contractionResistance = 0
    
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = sprubixColor
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        sprubixFeedTableView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
        
        // sprubix logo
        var logoImageView = UIImageView(image: UIImage(named: "main-sprubix-logo"))
        let logoImageWidth:CGFloat = 50
        let logoImageHeight:CGFloat = 30
        logoImageView.frame = CGRect(x: -logoImageWidth / 2, y: -logoImageHeight / 2, width: logoImageWidth, height: logoImageHeight)
        
        /*
        var logoImageView = UIImageView(image: UIImage(named: "main-sprubix-text"))
        logoImageView.frame = CGRect(x: -screenWidth / 2 + 20, y: -20, width: 100, height: 40)
        */
        
        logoImageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.navigationItem.titleView = UIView()
        self.navigationItem.titleView?.addSubview(logoImageView)
        
        initButtons()
    }
    
    func refresh(sender: AnyObject) {
        //retrieveOutfits()
        
        refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        if(refreshControl.refreshing) {
            refreshControl.endRefreshing()
            refreshControl.beginRefreshing()
        }
        
        retrieveOutfits()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var currentDistanceMoved:CGFloat = 0
        var currentNavMoved:CGFloat = 0
        
        // ensuring the createOutfitButton is sticky
        if lastContentOffset > scrollView.contentOffset.y {
            // up
            currentDistanceMoved = lastContentOffset - scrollView.contentOffset.y
            createOutfitButton.frame.origin.y -= currentDistanceMoved
            
        } else if lastContentOffset < scrollView.contentOffset.y {
            // down
            currentDistanceMoved = scrollView.contentOffset.y - lastContentOffset
            createOutfitButton.frame.origin.y += currentDistanceMoved
        }

        lastContentOffset = scrollView.contentOffset.y
        
        // ensuring the createOutfitButton show/hides when navbar show/hides
        if lastNavOffset > self.navigationController!.navigationBar.frame.origin.y {
            // up
            
            currentNavMoved = lastNavOffset - self.navigationController!.navigationBar.frame.origin.y
            createOutfitButton.frame.origin.y += currentNavMoved * 1.5
        } else if lastNavOffset < self.navigationController!.navigationBar.frame.origin.y {
            // down
            
            currentNavMoved =  self.navigationController!.navigationBar.frame.origin.y - lastNavOffset
            createOutfitButton.frame.origin.y -= currentNavMoved * 1.5
        }
        
        lastNavOffset = self.navigationController!.navigationBar.frame.origin.y
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return outfits.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:SprubixFeedCell = sprubixFeedTableView.dequeueReusableCellWithIdentifier("SprubixFeedCell") as SprubixFeedCell
        
        cell.outfit = outfits[indexPath.row]
        cell.initOutfit()
        
        cell.delegate = self
        cell.navController = self.navigationController
        
        indexCellHeight.append(cell.outfitHeight)
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let outfit = outfits[indexPath.row]
        
        let h = outfit["height"] as CGFloat
        let w = outfit["width"] as CGFloat
        let height = h * screenWidth / w
        
        return height
    }

    func initButtons() {
        // create outfit button at bottom right
        createOutfitButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        createOutfitButton.frame = CGRect(x: screenWidth - 50, y: screenHeight - 50, width: 40, height: 40)
        createOutfitButton.backgroundColor = UIColor.whiteColor()
        createOutfitButton.setImage(UIImage(named: "main-cta-add"), forState: UIControlState.Normal)
        createOutfitButton.addTarget(self, action: "createOutfit", forControlEvents: UIControlEvents.TouchUpInside)
        
        // circle mask
        createOutfitButton.layer.cornerRadius = createOutfitButton.frame.size.width / 2
        createOutfitButton.clipsToBounds = true
        createOutfitButton.layer.borderWidth = 1.0
        createOutfitButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        createOutfitButton.userInteractionEnabled = true
        
        view.addSubview(createOutfitButton)
    }
    
    func createOutfit() {
        println("create outfit button pressed")
    }
    
    // SprubixFeedCellProtocol
    func displayCommentsView(selectedOutfit: NSDictionary) {
        if sprubixCommentsController == nil {
            sprubixCommentsController = SprubixFeedCommentsController()
            // prepare the view below the screen for animation
            sprubixCommentsController?.view.frame = CGRect(x: 0, y: screenHeight, width: screenWidth, height: screenHeight)
            sprubixCommentsController?.delegate = self
            
            self.navigationController?.view.insertSubview(sprubixCommentsController!.view, atIndex: 1)
            //self.navigationController?.addChildViewController(sprubixCommentsController!)
            //sprubixCommentsController?.didMoveToParentViewController(self.navigationController)
            
            UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.sprubixCommentsController!.view.frame.origin.y = 0
                }, completion: nil)
        }
    }
    
    func dismissCommentsView() {
        if sprubixCommentsController != nil {
            UIView.animateWithDuration(0.8, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.sprubixCommentsController!.view.frame.origin.y = screenHeight
                }, completion: { finished in
                    if finished {
                        self.sprubixCommentsController?.view.removeFromSuperview()
                        self.sprubixCommentsController = nil
                    }
            })
        }
    }
    
    // SpruceViewProtocol
    func spruceOutfit(selectedOutfit: NSDictionary) {
        if spruceViewController == nil {
            spruceViewController = SpruceViewController()
            spruceViewController?.outfit = selectedOutfit
            spruceViewController?.delegate = self
            
            self.navigationController?.pushViewController(self.spruceViewController!, animated: true)
            
            //self.navigationController?.pushViewController(spruceViewController!, animated: true)
            //self.navigationController?.presentViewController(spruceViewController!, animated: true, completion: nil)
        }
    }
    
    func dismissSpruceView() {
        spruceViewController?.view.removeFromSuperview()
        spruceViewController = nil
    }
}