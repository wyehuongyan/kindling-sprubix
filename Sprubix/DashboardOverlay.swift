//
//  DashboardHeader.swift
//  Sprubix
//
//  Created by Shion Wah on 8/8/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import Charts

class DashboardOverlay: UIView {
    
    var revenueView: UIView!
    var ordersView: UIView!
    var popularItemsTitleView: UIView!
    var customersView: UIView!
    var activeOrdersView: UIView!
    var fufilledOrdersView: UIView!
    var refundedOrdersView: UIView!
    
    let headerViewHeight: CGFloat = 180
    let subheaderViewHeight: CGFloat = 60
    let popularItemsTextViewHeight: CGFloat = 30
    let footerViewHeight: CGFloat = 60
    var popularItemsViewHeight: CGFloat!
    
    var numRevenue: UILabel!
    var numOrders: UILabel!
    var numCustomers: UILabel!
    var numRevenueText: UILabel!
    var numOrdersText: UILabel!
    var numCustomersText: UILabel!
    var popularItemsTitleText: UILabel!
    
    var numActiveOrders: UILabel!
    var numFulfilledOrders: UILabel!
    var numRefundedOrders: UILabel!
    var numActiveOrdersText: UILabel!
    var numFulfilledOrdersText: UILabel!
    var numRefundedOrdersText: UILabel!
    
    let mainTextColor: UIColor = sprubixColor
    let subTextColor: UIColor = UIColor.lightGrayColor()
    let headerTextFont:UIFont = UIFont.systemFontOfSize(30)
    let subheaderTextFont:UIFont = UIFont.systemFontOfSize(24)
    let footerTextFont:UIFont = UIFont.systemFontOfSize(20)
    let subTextFont:UIFont = UIFont.systemFontOfSize(14)
    let borderColor:CGColor = sprubixGray.CGColor
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initDashboard()
    }
    
    func initDashboard() {
        // Revenue
        let headerY: CGFloat = navigationHeight
        revenueView = UIView(frame: CGRectMake(0, headerY, screenWidth, headerViewHeight))
        revenueView.backgroundColor = UIColor.whiteColor()
        addSubview(revenueView)
        
        numRevenue = UILabel(frame: CGRectMake(0, 5, screenWidth/2-5, 30))
        numRevenue.text = ""
        numRevenue.textColor = mainTextColor
        numRevenue.font = headerTextFont
        numRevenue.textAlignment = NSTextAlignment.Right
        
        numRevenueText = UILabel(frame: CGRectMake(screenWidth/2, 10, screenWidth/2, 30))
        numRevenueText.text = "Total Revenue"
        numRevenueText.font = subTextFont
        numRevenueText.textColor = subTextColor
        numRevenueText.textAlignment = NSTextAlignment.Left
        
        revenueView.addSubview(numRevenue)
        revenueView.addSubview(numRevenueText)
        
        // orders
        let subheaderY: CGFloat = headerY + headerViewHeight
        ordersView = UIView(frame: CGRectMake(-1, subheaderY, screenWidth/2+1, subheaderViewHeight))
        ordersView.layer.borderWidth = 1.0
        ordersView.layer.borderColor = borderColor
        ordersView.backgroundColor = UIColor.whiteColor()
        addSubview(ordersView)
        
        numOrders = UILabel(frame: CGRectMake(0, 5, screenWidth/2, 30))
        numOrders.text = ""
        numOrders.textColor = mainTextColor
        numOrders.font = subheaderTextFont
        numOrders.textAlignment = NSTextAlignment.Center
        
        numOrdersText = UILabel(frame: CGRectMake(0, 25, screenWidth/2, 30))
        numOrdersText.text = "Orders"
        numOrdersText.font = subTextFont
        numOrdersText.textColor = subTextColor
        numOrdersText.textAlignment = NSTextAlignment.Center
        
        ordersView.addSubview(numOrders)
        ordersView.addSubview(numOrdersText)
        
        // customers
        customersView = UIView(frame: CGRectMake(screenWidth/2-1, subheaderY, screenWidth/2+2, subheaderViewHeight))
        customersView.layer.borderWidth = 1.0
        customersView.layer.borderColor = borderColor
        customersView.backgroundColor = UIColor.whiteColor()
        addSubview(customersView)
        
        numCustomers = UILabel(frame: CGRectMake(0, 5, screenWidth/2, 30))
        numCustomers.text = ""
        numCustomers.textColor = mainTextColor
        numCustomers.font = subheaderTextFont
        numCustomers.textAlignment = NSTextAlignment.Center
        
        numCustomersText = UILabel(frame: CGRectMake(0, 25, screenWidth/2, 30))
        numCustomersText.text = "Customers"
        numCustomersText.font = subTextFont
        numCustomersText.textColor = subTextColor
        numCustomersText.textAlignment = NSTextAlignment.Center
        
        customersView.addSubview(numCustomers)
        customersView.addSubview(numCustomersText)
        
        // popular items title
        let popularItemsTitleY = subheaderY + subheaderViewHeight
        popularItemsTitleView = UIView(frame: CGRectMake(0, popularItemsTitleY, screenWidth, popularItemsTextViewHeight))
        popularItemsTitleView.backgroundColor = sprubixLightGray
        addSubview(popularItemsTitleView)
        
        popularItemsTitleText = UILabel(frame: CGRectMake(0, 0, screenWidth, popularItemsTextViewHeight))
        popularItemsTitleText.text = "Popular Items"
        popularItemsTitleText.font = subTextFont
        popularItemsTitleText.textColor = UIColor.darkGrayColor()
        popularItemsTitleText.textAlignment = NSTextAlignment.Center
        
        popularItemsTitleView.addSubview(popularItemsTitleText)
        
        // active orders
        let footerY: CGFloat = screenHeight - footerViewHeight
        activeOrdersView = UIView(frame: CGRectMake(-1, footerY, screenWidth/3+2, footerViewHeight))
        activeOrdersView.layer.borderWidth = 1.0
        activeOrdersView.layer.borderColor = borderColor
        activeOrdersView.backgroundColor = UIColor.whiteColor()
        addSubview(activeOrdersView)
        
        numActiveOrders = UILabel(frame: CGRectMake(0, 5, screenWidth/3, 30))
        numActiveOrders.text = ""
        numActiveOrders.textColor = mainTextColor
        numActiveOrders.font = footerTextFont
        numActiveOrders.textAlignment = NSTextAlignment.Center
        
        numActiveOrdersText = UILabel(frame: CGRectMake(0, 25, screenWidth/3, 30))
        numActiveOrdersText.text = "Active"
        numActiveOrdersText.font = subTextFont
        numActiveOrdersText.textColor = subTextColor
        numActiveOrdersText.textAlignment = NSTextAlignment.Center
        
        activeOrdersView.addSubview(numActiveOrders)
        activeOrdersView.addSubview(numActiveOrdersText)
        
        // fulfilled orders
        fufilledOrdersView = UIView(frame: CGRectMake(screenWidth/3, footerY, screenWidth/3, footerViewHeight))
        fufilledOrdersView.layer.borderWidth = 1.0
        fufilledOrdersView.layer.borderColor = borderColor
        fufilledOrdersView.backgroundColor = UIColor.whiteColor()
        addSubview(fufilledOrdersView)
        
        numFulfilledOrders = UILabel(frame: CGRectMake(0, 5, screenWidth/3, 30))
        numFulfilledOrders.text = ""
        numFulfilledOrders.textColor = mainTextColor
        numFulfilledOrders.font = footerTextFont
        numFulfilledOrders.textAlignment = NSTextAlignment.Center
        
        numFulfilledOrdersText = UILabel(frame: CGRectMake(0, 25, screenWidth/3, 30))
        numFulfilledOrdersText.text = "Fulfilled"
        numFulfilledOrdersText.font = subTextFont
        numFulfilledOrdersText.textColor = subTextColor
        numFulfilledOrdersText.textAlignment = NSTextAlignment.Center
        
        fufilledOrdersView.addSubview(numFulfilledOrders)
        fufilledOrdersView.addSubview(numFulfilledOrdersText)
        
        // refunded orders
        refundedOrdersView = UIView(frame: CGRectMake(screenWidth/3*2-1, footerY, screenWidth/3+1, footerViewHeight))
        refundedOrdersView.layer.borderWidth = 1.0
        refundedOrdersView.layer.borderColor = borderColor
        refundedOrdersView.backgroundColor = UIColor.whiteColor()
        addSubview(refundedOrdersView)
        
        numRefundedOrders = UILabel(frame: CGRectMake(0, 5, screenWidth/3, 30))
        numRefundedOrders.text = ""
        numRefundedOrders.textColor = mainTextColor
        numRefundedOrders.font = footerTextFont
        numRefundedOrders.textAlignment = NSTextAlignment.Center
        
        numRefundedOrdersText = UILabel(frame: CGRectMake(0, 25, screenWidth/3, 30))
        numRefundedOrdersText.text = "Refunding"
        numRefundedOrdersText.font = subTextFont
        numRefundedOrdersText.textColor = subTextColor
        numRefundedOrdersText.textAlignment = NSTextAlignment.Center
        
        refundedOrdersView.addSubview(numRefundedOrders)
        refundedOrdersView.addSubview(numRefundedOrdersText)
    }
    
    func getPopularItemsY() -> CGFloat {
        return navigationHeight + headerViewHeight + subheaderViewHeight + popularItemsTextViewHeight
    }
    
    func getFooterHeight() -> CGFloat {
        return footerViewHeight
    }
    
    func showFooter() {
        
        if activeOrdersView.superview == nil {
            addSubview(activeOrdersView)
        }
        
        if fufilledOrdersView.superview == nil {
            addSubview(fufilledOrdersView)
        }
        
        if refundedOrdersView.superview == nil {
            addSubview(refundedOrdersView)
        }
    }
    
    func hideFooter() {
        
        if activeOrdersView.superview != nil {
            activeOrdersView.removeFromSuperview()
        }
        
        if fufilledOrdersView.superview != nil {
            fufilledOrdersView.removeFromSuperview()
        }
        
        if refundedOrdersView.superview != nil {
            refundedOrdersView.removeFromSuperview()
        }
    }
}