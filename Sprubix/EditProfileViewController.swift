//
//  EditProfileViewController.swift
//  Sprubix
//
//  Created by Shion Wah on 15/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AFNetworking
import TSMessages
import PermissionScope
import MRProgress

enum SelectedPhotoType {
    case Profile
    case Cover
}

class EditProfileViewController: UITableViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CroppedImageProtocol {
    
    // custom nav bar
    var newNavBar: UINavigationBar!
    var newNavItem: UINavigationItem!
    
    // Profile details
    @IBOutlet var profileImage: UIImageView! = UIImageView()
    @IBOutlet var profileCoverImage: UIImageView! = UIImageView()
    @IBOutlet var profileName: UITextField!
    @IBOutlet var profileDescription: UITextView!
    let profileDescriptionDefault = "Tell us more about yourself!"

    // photo
    let cameraPscope = PermissionScope()
    let photoPscope = PermissionScope()
    let imagePicker = UIImagePickerController()
    var currentPhotoType: SelectedPhotoType = .Profile
    
    var profileImageDirty = false
    var coverImageDirty = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUserInfo()
        initPhotoLibrary()
        
        view.backgroundColor = sprubixGray
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initNavBar()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func initUserInfo() {
        let userData: NSDictionary? = NSUserDefaults.standardUserDefaults().dictionaryForKey("userData")
        
        if userData != nil {
            // Get info from local
            let userThumbnailURL = NSURL(string: userData!["image"] as! String)
            let userCoverURL = NSURL(string: userData!["cover"] as! String)
            let userName = userData!["name"] as! String
            let userDescription = userData!["description"] as! String
            
            // Set profile image
            profileImage.setImageWithURL(userThumbnailURL)
            profileImage.backgroundColor = sprubixGray
            profileImage.contentMode = UIViewContentMode.ScaleAspectFit
            profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
            profileImage.clipsToBounds = true
            profileImage.layer.borderWidth = 0.5
            profileImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            
            // Set cover image
            profileCoverImage.setImageWithURL(userCoverURL)
            profileCoverImage.backgroundColor = sprubixGray
            profileCoverImage.contentMode = UIViewContentMode.ScaleAspectFit
            profileCoverImage.layer.cornerRadius = 5
            profileCoverImage.clipsToBounds = true
            profileCoverImage.layer.borderWidth = 0.5
            profileCoverImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            
            // Set name
            profileName.textColor = sprubixColor
            profileName.returnKeyType = UIReturnKeyType.Next
            
            if (userName != "") {
                profileName.text = userName
            }
            
            // Set description
            profileDescription.textColor = sprubixColor
            profileDescription.delegate = self
            profileDescription.textContainer.maximumNumberOfLines = 3
            
            if (userDescription != "") {
                profileDescription.text = userDescription
            } else {
                profileDescription.text = profileDescriptionDefault
            }
        }
    }
    
    func initNavBar() {
        // 1. hide existing nav bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        self.navigationItem.title = "Edit Profile"
        
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
        
        self.navigationItem.setLeftBarButtonItem(backBarButtonItem, animated: false)
        
        // 5. create a done buton
        var nextButton:UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        nextButton.setTitle("save", forState: UIControlState.Normal)
        nextButton.setTitleColor(sprubixColor, forState: UIControlState.Normal)
        nextButton.frame = CGRect(x: 0, y: 0, width: 50, height: 20)
        nextButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        nextButton.addTarget(self, action: "saveTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        
        var nextBarButtonItem:UIBarButtonItem = UIBarButtonItem(customView: nextButton)
        self.navigationItem.setRightBarButtonItem(nextBarButtonItem, animated: false)
        
        self.navigationController?.navigationBar.tintColor = UIColor.lightGrayColor()
    }
    
    func initPhotoLibrary() {
        // initialized permissions
        cameraPscope.addPermission(PermissionConfig(type: .Camera, demands: .Required, message: "We need this so you can snap\r\nawesome pictures of your items!", notificationCategories: .None))
        
        cameraPscope.tintColor = sprubixColor
        cameraPscope.headerLabel.text = "Hey there,"
        cameraPscope.headerLabel.textColor = UIColor.darkGrayColor()
        cameraPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        
        photoPscope.addPermission(PermissionConfig(type: .Photos, demands: .Required, message: "We need this so you can import\r\nawesome pictures of your items!", notificationCategories: .None))
        
        photoPscope.tintColor = sprubixColor
        photoPscope.headerLabel.text = "Hey there,"
        photoPscope.headerLabel.textColor = UIColor.darkGrayColor()
        photoPscope.bodyLabel.textColor = UIColor.lightGrayColor()
        
        imagePicker.delegate = self
        imagePicker.navigationBar.translucent = true
        imagePicker.navigationBar.barTintColor = sprubixGray
    }
    
    // MARK: PhotoLibrary Delegates
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        var chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismissViewControllerAnimated(true, completion: nil)
        
        let editProfilePhotoViewController = EditProfilePhotoViewController()
        
        switch currentPhotoType {
        case .Profile:
            // show edit photo view controller
            // // with square mask
            editProfilePhotoViewController.photoType = .Profile
            
        case .Cover:
            // show edit photo view controller
            // // with rectangle mask
            editProfilePhotoViewController.photoType = .Cover
            
        default:
            fatalError("Error: Invalid Photo State in EditProfileViewController.")
        }
        
        editProfilePhotoViewController.photoImageView.image = chosenImage
        editProfilePhotoViewController.delegate = self
        
        self.navigationController?.pushViewController(editProfilePhotoViewController, animated: false)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // nav bar button callbacks
    func backTapped(sender: UIBarButtonItem) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func saveTapped(sender: UIBarButtonItem) {
        
        // Hide keyboard
        self.view.endEditing(true)
        
        let validateResult = self.validateInputs()
        let delay: NSTimeInterval = 2
        let viewDelay: Double = 2.5
        
        if validateResult.valid {
            let profileInfo: NSMutableDictionary = NSMutableDictionary()
            
            if profileName.text != "" {
                profileInfo.setObject(profileName.text, forKey: "name")
            }
            
            if profileDescription.text != "" {
                profileInfo.setObject(profileDescription.text, forKey: "description")
            }
            
            // convert image into data for upload
            var profileImageData: NSData? = profileImageDirty ?  UIImageJPEGRepresentation(profileImage.image, 0.5) : nil
            
            var profileCoverImageData: NSData? = coverImageDirty ?  UIImageJPEGRepresentation(profileCoverImage.image, 0.5) : nil
            
            var requestOperation: AFHTTPRequestOperation = manager.POST(SprubixConfig.URL.api + "/update/profile",
                parameters: profileInfo,
                constructingBodyWithBlock: { formData in
                    let data: AFMultipartFormData = formData
                    
                    // append profile image
                    if profileImageData != nil {
                        data.appendPartWithFileData(profileImageData!, name: "profile", fileName: "profile.jpg", mimeType: "image/jpeg")
                    }
                    
                    if profileCoverImageData != nil {
                        // append cover image
                        data.appendPartWithFileData(profileCoverImageData!, name: "cover", fileName: "cover.jpg", mimeType: "image/jpeg")
                    }
                },
                success: { (operation: AFHTTPRequestOperation!, responseObject:
                    AnyObject!) in
                    var response = responseObject as! NSDictionary
                    var status = response["status"] as! String
                    var message = response["message"] as! String
                    
                    // Print reply from server
                    println(message + " " + status)
                    
                    if status == "200" {
                        var data = response["user"] as! NSDictionary
                        
                        // success
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Success!",
                            subtitle: "Profile updated",
                            image: UIImage(named: "filter-check"),
                            type: TSMessageNotificationType.Success,
                            duration: delay,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                        
                        // update cache
                        var cleanData = self.cleanDictionary(data as! NSMutableDictionary)
                        defaults.setObject(cleanData["id"], forKey: "userId")
                        defaults.setObject(cleanData, forKey: "userData")
                        defaults.synchronize()
                        
                        Delay.delay(viewDelay) {
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                        
                        println(data)
                        
                    } else if status == "500" {
                        var exception = response["exception"] as! String
                        
                        // error exception
                        TSMessage.showNotificationInViewController(
                            TSMessage.defaultViewController(),
                            title: "Error",
                            subtitle: "Something went wrong.\nPlease try again.",
                            image: UIImage(named: "filter-cross"),
                            type: TSMessageNotificationType.Error,
                            duration: delay,
                            callback: nil,
                            buttonTitle: nil,
                            buttonCallback: nil,
                            atPosition: TSMessageNotificationPosition.Bottom,
                            canBeDismissedByUser: true)
                        
                        println(exception)
                    }

                },
                failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
                    println("Error: " + error.localizedDescription)
                    
                    // error exception
                    TSMessage.showNotificationInViewController(
                        TSMessage.defaultViewController(),
                        title: "Error",
                        subtitle: "Something went wrong.\nPlease try again.",
                        image: UIImage(named: "filter-cross"),
                        type: TSMessageNotificationType.Error,
                        duration: delay,
                        callback: nil,
                        buttonTitle: nil,
                        buttonCallback: nil,
                        atPosition: TSMessageNotificationPosition.Bottom,
                        canBeDismissedByUser: true)
            })
            
            if profileImageDirty || coverImageDirty {
                // upload progress only if there's an image
                requestOperation.setUploadProgressBlock { (bytesWritten: UInt, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void in
                    var percentDone: Double = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                    
                    println("percentage done: \(percentDone)")
                }
                
                // overlay indicator
                var overlayView: MRProgressOverlayView = MRProgressOverlayView.showOverlayAddedTo(self.view, animated: true)
                overlayView.setModeAndProgressWithStateOfOperation(requestOperation)
                
                overlayView.tintColor = sprubixColor
            }
        
        } else {
            // Validation failed
            TSMessage.showNotificationInViewController(
                self,
                title: "Error",
                subtitle: validateResult.message,
                image: UIImage(named: "filter-cross"),
                type: TSMessageNotificationType.Error,
                duration: delay,
                callback: nil,
                buttonTitle: nil,
                buttonCallback: nil,
                atPosition: TSMessageNotificationPosition.Bottom,
                canBeDismissedByUser: true)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.section {
        // Photo
        case 0:
            showPhotoMenu(indexPath.section)
        // Cover
        case 1:
            showPhotoMenu(indexPath.section)
            
        default:
            break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView == profileDescription {
            if profileDescription.text == profileDescriptionDefault {
                profileDescription.text = ""
            }
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView == profileDescription {
            if profileDescription.text == "" {
                profileDescription.text = profileDescriptionDefault
            }
        }
    }
    
    func validateInputs() -> (valid: Bool, message: String) {
        var valid: Bool = true
        var message: String = ""
        
        // If description is placeholder text, remove it
        if profileDescription.text == profileDescriptionDefault {
            profileDescription.text = ""
        }
        
        // Display name cannot be empty
        if profileName.text == "" {
            message += "Please enter a name\n"
            valid = false
        }
        else if count(profileName.text) > 30 {
            message += "The name must be under 30 characters\n"
            valid = false
        }
        
        if count(profileDescription.text) > 255 {
            message += "The description is too long\n"
            valid = false
        }
        
        return (valid, message)
    }
    
    func showPhotoMenu(section: Int) {
        
        switch section {
        case 0:
            currentPhotoType = .Profile
        case 1:
            currentPhotoType = .Cover
        default:
            fatalError("Error: Invalid Photo Type in EditProfileViewController.")
        }
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheetController.view.tintColor = sprubixColor

        let takePictureAction: UIAlertAction = UIAlertAction(title: "Take Photo", style: UIAlertActionStyle.Default) { action -> Void in
            println("Take Photo")
        }
        
        let choosePictureAction: UIAlertAction = UIAlertAction(title: "Choose from Library", style: UIAlertActionStyle.Default) { action -> Void in

            self.photoPscope.show(authChange: { (finished, results) -> Void in
                //println("got results \(results)")
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
                }, cancelled: { (results) -> Void in
                    //println("thing was cancelled")
            })
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { action -> Void in
            // Dismiss the action sheet, do nothing
        }
        
        actionSheetController.addAction(takePictureAction)
        actionSheetController.addAction(choosePictureAction)
        actionSheetController.addAction(cancelAction)
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func cleanDictionary(dict: NSMutableDictionary)->NSMutableDictionary {
        var mutableDict: NSMutableDictionary = dict.mutableCopy() as! NSMutableDictionary
        mutableDict.enumerateKeysAndObjectsUsingBlock { (key, obj, stop) -> Void in
            if (obj.isKindOfClass(NSNull.classForCoder())) {
                mutableDict.setObject("", forKey: (key as! NSString))
            } else if (obj.isKindOfClass(NSDictionary.classForCoder())) {
                mutableDict.setObject(self.cleanDictionary(obj as! NSMutableDictionary), forKey: (key as! NSString))
            }
        }
        return mutableDict
    }
    
    // CroppedImageProtocol
    func profilePhotoCropped(croppedImage: UIImage) {
        profileImage.image = croppedImage
        profileImageDirty = true
    }
    
    func coverPhotoCropped(croppedImage: UIImage) {
        profileCoverImage.image = croppedImage
        coverImageDirty = true
    }
}
