//
//  ProvideFeedbackViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 17/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import MessageUI
import TSMessages

class ProvideFeedbackViewController: UIViewController, MFMailComposeViewControllerDelegate {

    var mailCompose: MFMailComposeViewController = MFMailComposeViewController()
    let emailTitle: String = "Feedback"
    let messageBody: String = "Hi Team Sprubix!\n\n"
    let emailRecipient: String = "hello@sprubix.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if MFMailComposeViewController.canSendMail() {
            mailCompose.mailComposeDelegate = self
            mailCompose.setSubject(emailTitle)
            mailCompose.setMessageBody(messageBody, isHTML: false)
            mailCompose.setToRecipients([emailRecipient])
            
            self.presentViewController(mailCompose, animated: true, completion: nil)
            
        } else {
            println("No email account found")
            
            let delay: NSTimeInterval = 2
            
            // error exception
            TSMessage.showNotificationInViewController(
                TSMessage.defaultViewController(),
                title: "No mail accounts found",
                subtitle: "Please set up your mail account",
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
            
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        
        let delay: NSTimeInterval = 2
        
        switch result.value {
            
        case MFMailComposeResultCancelled.value:
            println("Mail cancelled")
        
        case MFMailComposeResultSaved.value:
            println("Mail saved")
            
        case MFMailComposeResultSent.value:
            println("Mail sent")
            
            // success
            TSMessage.showNotificationInViewController(
                TSMessage.defaultViewController(),
                title: "Email Sent!",
                subtitle: "Thanks for speaking to us.\nWe'll get back to you real quick!",
                image: UIImage(named: "filter-check"),
                type: TSMessageNotificationType.Success,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
            
        case MFMailComposeResultFailed.value:
            println("Mail failed")
            
            // error exception
            TSMessage.showNotificationInViewController(
                TSMessage.defaultViewController(),
                title: "Error, Email not Sent",
                subtitle: "Something went wrong.\nPlease try again.",
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
            
        default:
            break
        }
        
        self.dismissViewControllerAnimated(false, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }

}
