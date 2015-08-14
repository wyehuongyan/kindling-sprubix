//
//  DashboardViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 8/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import Charts
import AFNetworking

enum DashboardMonth {
    case Current, Previous
}

class DashboardViewController: UIViewController, UITableViewDataSource, ChartViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    var monthButton:UIButton!
    
    var dashboardOverlay: DashboardOverlay!
    let dashboardItemCellIdentifier: String = "DashboardItemCell"
    
    var popularItemsViewHeight: CGFloat = 230
    var popularItemsView: UIView!
    var activityView: UIActivityIndicatorView!
    
    @IBOutlet var popularItemsTableView: UITableView!
    @IBOutlet var popularItemsTopConstraint: NSLayoutConstraint!
    @IBOutlet var popularItemsBotConstraint: NSLayoutConstraint!
    
    var revenueChartView: BarChartView!
    let revenueChartY: CGFloat = navigationHeight + 40
    
    var revenueByDays: [Double] = []
    var monthIncrement: Int = 0
    var dashboardMonth: DashboardMonth = .Current
    var popularPieces: [NSDictionary] = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initDashboard()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
        refreshDashboardData()
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // 2. create new nav bar and style it
        newNavBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.bounds.width, navigationHeight))
        newNavBar.barTintColor = UIColor.whiteColor()
        
        // 3. add a new navigation item w/title to the new nav bar
        newNavItem = UINavigationItem()
        newNavItem.title = "This Month"
        
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
        
        // 5. create a last month buton
        monthButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        monthButton.setTitle("last month", forState: UIControlState.Normal)
        monthButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        monthButton.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        monthButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        monthButton.addTarget(self, action: "monthSwitchTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var monthButtonItem:UIBarButtonItem = UIBarButtonItem(customView: monthButton)
        newNavItem.rightBarButtonItem = monthButtonItem
        
        newNavBar.setItems([newNavItem], animated: false)
        
        // 6. add the nav bar to the main view
        self.view.addSubview(newNavBar)
    }
    
    func backTapped(sender: UIBarButtonItem) {
        // reset view
        newNavItem.title = "This Month"
        monthButton.setTitle("last month", forState: UIControlState.Normal)
        monthIncrement = 0
        dashboardMonth = .Current
        dashboardOverlay.showFooter()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func monthSwitchTapped(sender: UIBarButtonItem) {
        dashboardMonth = ((dashboardMonth == .Current) ? .Previous : .Current)
        
        if dashboardMonth == .Current {
            newNavItem.title = "This Month"
            monthButton.setTitle("last month", forState: UIControlState.Normal)
            monthIncrement = 0
            
            dashboardOverlay.showFooter()
            popularItemsBotConstraint.constant = dashboardOverlay.getFooterHeight()
        } else {
            newNavItem.title = "Last Month"
            monthButton.setTitle("this month", forState: UIControlState.Normal)
            monthIncrement = -1
            
            dashboardOverlay.hideFooter()
            popularItemsBotConstraint.constant = 0
        }
        
        revenueChartView.clear()
        self.refreshDashboardData()
    }
    
    func initDashboard() {
        // Overlay info
        dashboardOverlay = DashboardOverlay()
        dashboardOverlay.showFooter()
        self.view.addSubview(dashboardOverlay)
        
        // Revenue chart
        let revenueChartHeight = dashboardOverlay.headerViewHeight + navigationHeight - revenueChartY
        revenueChartView = BarChartView(frame: CGRectMake(-10, revenueChartY, screenWidth+20, revenueChartHeight))
        
        self.view.addSubview(revenueChartView)
        
        revenueChartView.noDataText = "We're fetching the data..."
        revenueChartView.infoTextColor = UIColor.lightGrayColor()
        revenueChartView.descriptionText = ""
        revenueChartView.xAxis.labelPosition = .Bottom
        revenueChartView.dragEnabled = true
        revenueChartView.scaleXEnabled = false
        revenueChartView.scaleYEnabled = false
        revenueChartView.pinchZoomEnabled = false
        revenueChartView.doubleTapToZoomEnabled = false
        revenueChartView.highlightEnabled = false
        revenueChartView.legend.enabled = false
        revenueChartView.leftAxis.enabled = false
        revenueChartView.rightAxis.enabled = false
        revenueChartView.drawBordersEnabled = false
        revenueChartView.drawGridBackgroundEnabled = false
        revenueChartView.leftAxis.drawGridLinesEnabled = false
        revenueChartView.xAxis.drawGridLinesEnabled = false
        revenueChartView.xAxis.labelTextColor = UIColor.lightGrayColor()

        // set popular items position and size
        let popularItemsY = dashboardOverlay.getPopularItemsY()
        let popularItemsHeight = dashboardOverlay.getFooterHeight()
        
        popularItemsTopConstraint.constant = popularItemsY
        popularItemsBotConstraint.constant = popularItemsHeight
        
        popularItemsTableView.backgroundColor = sprubixGray
        popularItemsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        popularItemsTableView.emptyDataSetSource = self
        popularItemsTableView.emptyDataSetDelegate = self
        
        // spinner for popular items
        let activityViewWidth: CGFloat = 50
        activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
        activityView.color = sprubixColor
        activityView.frame = CGRect(x: screenWidth / 2 - activityViewWidth / 2, y: (popularItemsHeight / 2 - activityViewWidth / 2) + popularItemsY, width: activityViewWidth, height: activityViewWidth)
        
        view.addSubview(activityView)
        
        // set month to show, default is current
        monthIncrement = 0
    }
    
    func refreshDashboardData() {
        
        revenueChartView.clear()
        activityView.startAnimating()
        
        let currentTime = localDate
        
        // REST call to server to retrieve shop orders
        manager.POST(SprubixConfig.URL.api + "/dashboard/report",
            parameters: [
                "currentTime" : currentTime,
                "monthIncrement" : monthIncrement
            ],
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let response = responseObject["data"] as! NSDictionary
                self.activityView.stopAnimating()
                
                // update numbers
                if let revenue = response["revenue"] as? Double, customers = response["customers"] as? Int, orders = response["orders"] as? Int, activeOrders = response["activeOrders"] as? Int, fulfilledOrders = response["fulfilledOrders"] as? Int, refundedOrders = response["refundedOrders"] as? Int {
                    self.updateNumbers(revenue, orders: orders, customers: customers, activeOrders: activeOrders, fulfilledOrders: fulfilledOrders, refundedOrders: refundedOrders)
                }
                
                // update chart
                if let currentDay = response["currentDay"] as? Int, monthSelected = response["monthSelected"] as? Int, revenueByDays = response["revenueByDays"] as? [Double] {
                    self.setChart(currentDay, monthSelected: monthSelected, revenueByDays: revenueByDays)
                }
                
                // update popular items
                if let popularItems = response["popular_items"] as? [NSDictionary] {
                    self.popularPieces = popularItems
                    
                    self.popularItemsTableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
                    self.popularItemsTableView.reloadData()
                }
            },
            failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    // MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return popularPieces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(dashboardItemCellIdentifier, forIndexPath: indexPath) as! DashboardItemCell
        
        if indexPath.row < popularPieces.count {
            if let itemName = popularPieces[indexPath.row]["name"] as? String {
                cell.itemName.text = itemName
            }
            
            if let itemSold = popularPieces[indexPath.row]["sold"] as? Int {
                cell.itemSold.text = "\(itemSold) sold"
            }
            
            if let image = popularPieces[indexPath.row]["images"] as? String {
                let thumbnail = NSURL(string: image)
                cell.itemImageView.setImageWithURL(thumbnail)
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 70
    }
    
    func updateNumbers(revenue: Double, orders: Int, customers: Int, activeOrders: Int, fulfilledOrders: Int, refundedOrders: Int) {
        self.dashboardOverlay.numRevenue.text = String(format: "$%.2f", revenue)
        self.dashboardOverlay.numOrders.text = "\(orders)"
        self.dashboardOverlay.numCustomers.text = "\(customers)"
        self.dashboardOverlay.numActiveOrders.text = "\(activeOrders)"
        self.dashboardOverlay.numFulfilledOrders.text = "\(fulfilledOrders)"
        self.dashboardOverlay.numRefundedOrders.text = "\(refundedOrders)"
    }

    // Chart Delegate
    func setChart(currentDay: Int, monthSelected: Int, revenueByDays: [Double]) {
        var axisPoints: [String] = []
        var values: [Double] = revenueByDays
        
        for i in 1...values.count {
            axisPoints.append("\(i)/\(monthSelected)")
        }

        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<axisPoints.count {
            let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Revenue")
        let chartData = BarChartData(xVals: axisPoints, dataSet: chartDataSet)
        
        chartDataSet.colors = [sprubixColor]
        chartDataSet.valueTextColor = UIColor.darkGrayColor()
        chartDataSet.valueFont = UIFont.systemFontOfSize(12.0)
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        chartDataSet.valueFormatter = numberFormatter
        
        self.revenueChartView.data = chartData
        self.revenueChartView.setVisibleXRangeMaximum(7)
        self.revenueChartView.centerViewTo(xIndex: currentDay-1, yValue: 0, axis: revenueChartView.leftAxis.axisDependency)
        self.revenueChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
    }
    
    // DZNEmptyDataSetSource
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = "Your best selling items"
        
        let attributes: NSDictionary = [
            NSFontAttributeName: UIFont.boldSystemFontOfSize(18.0),
            NSForegroundColorAttributeName: UIColor.darkGrayColor()
        ]
        
        let attributedString: NSAttributedString = NSAttributedString(string: text, attributes: attributes as [NSObject : AnyObject])
        
        return attributedString
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var text: String = "When you sell an item, you'll see it here."
        
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
    
    /*func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var image: UIImage!
        
        switch(currentFavoriteState) {
        case .Outfits:
            image = UIImage(named: "emptyset-favorites-outfit")
        case .Pieces:
            image = UIImage(named: "emptyset-favorites-piece")
        }
        
        return image
    }*/
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return sprubixGray
    }
}
