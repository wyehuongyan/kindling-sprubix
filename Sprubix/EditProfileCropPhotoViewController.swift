//
//  EditProfileCropPhotoViewController.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 31/7/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit

protocol CroppedImageProtocol {
    func profilePhotoCropped(croppedImage: UIImage)
    func coverPhotoCropped(croppedImage: UIImage)
}

class EditProfileCropPhotoViewController: UIViewController, UIScrollViewDelegate {
    
    var delegate: CroppedImageProtocol?
    
    let coverImageHeight: CGFloat = 250
    
    var editProfilePhotoScrollView: UIScrollView!
    var photoImageView: UIImageView = UIImageView()
    var borderedView: UIView!
    
    var photoType: SelectedPhotoType = SelectedPhotoType.Profile
    var fromSnapPhotoView: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        
        initScrollView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        initToolBar()
        
        var scaleWidth: CGFloat = screenWidth / editProfilePhotoScrollView.contentSize.width
        var scaleHeight: CGFloat = screenHeight / editProfilePhotoScrollView.contentSize.height
        var minScale: CGFloat = min(scaleWidth, scaleHeight)
        editProfilePhotoScrollView.minimumZoomScale = minScale
        
        editProfilePhotoScrollView.minimumZoomScale = minScale
        editProfilePhotoScrollView.maximumZoomScale = 4.0
        editProfilePhotoScrollView.zoomScale = minScale
        
        // convert contentsize to points
        var imageHeight = photoImageView.frame.height / photoImageView.frame.width * screenWidth
        
        // if image height (in points) is longer than the height of the scrollview (in points)
        if imageHeight > editProfilePhotoScrollView.frame.height {
            editProfilePhotoScrollView.setContentOffset(CGPointMake(0, (imageHeight - editProfilePhotoScrollView.frame.height) / 2), animated: false)
        }

        centerScrollViewContents()
    }
    
    func initScrollView() {
        var image = photoImageView.image
        
        if image != nil {
            
            if photoType == SelectedPhotoType.Cover {
                editProfilePhotoScrollView = UIScrollView(frame: CGRectMake(0, screenHeight / 2 - coverImageHeight / 2, screenWidth, coverImageHeight))
                
            } else {
                editProfilePhotoScrollView = UIScrollView(frame: CGRectMake(0, screenHeight / 2 - screenWidth / 2, screenWidth, screenWidth))
            }
            
            editProfilePhotoScrollView.backgroundColor = UIColor.blackColor()
            editProfilePhotoScrollView.scrollEnabled = true
            editProfilePhotoScrollView.clipsToBounds = false
            editProfilePhotoScrollView.bounces = true
            editProfilePhotoScrollView.showsHorizontalScrollIndicator = false
            editProfilePhotoScrollView.showsVerticalScrollIndicator = false
            editProfilePhotoScrollView.delegate = self
            
            view.addSubview(editProfilePhotoScrollView)
            
            photoImageView.frame.origin = CGPointMake(0, 0)
            photoImageView.frame.size = image!.size
            
            editProfilePhotoScrollView.contentSize = image!.size
            editProfilePhotoScrollView.addSubview(photoImageView)
        }
        
        switch photoType {
        case SelectedPhotoType.Profile:
            // with circular mask
            borderedView = UIView(frame: editProfilePhotoScrollView.frame)
            borderedView.layer.cornerRadius = editProfilePhotoScrollView.frame.width / 2
            
        case SelectedPhotoType.Cover:
            // with rectangle mask
            borderedView = UIView(frame: CGRectMake(0, screenHeight / 2 - coverImageHeight / 2, screenWidth, coverImageHeight))
            
        default:
            fatalError("Error: Invalid Photo State in EditProfileViewController.")
        }
        
        borderedView.layer.borderColor = sprubixColor.CGColor
        borderedView.layer.borderWidth = 2.0
        borderedView.alpha = 0.8
        borderedView.userInteractionEnabled = false
        
        view.addSubview(borderedView)
    }
    
    func initToolBar() {
        // create tool bar
        let editPhotoToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, screenHeight - navigationHeight, screenWidth, navigationHeight))
        editPhotoToolbar.barTintColor = UIColor.blackColor()
        editPhotoToolbar.tintColor = sprubixColor
        
        // cancel button
        let cancelButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        cancelButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.setTitleColor(sprubixColor, forState: UIControlState.Highlighted)
        cancelButton.addTarget(self, action: "cancelButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.tintColor = sprubixColor
        
        let cancelBarButton = UIBarButtonItem(customView: cancelButton)
        
        // flexible space
        let flexibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        
        // choose
        let chooseButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        chooseButton.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
        chooseButton.setTitle("Choose", forState: UIControlState.Normal)
        chooseButton.setTitleColor(sprubixColor, forState: UIControlState.Highlighted)
        chooseButton.addTarget(self, action: "chooseButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        chooseButton.tintColor = sprubixColor
        
        let chooseBarButton = UIBarButtonItem(customView: chooseButton)
        
        editPhotoToolbar.setItems([cancelBarButton, flexibleSpace, chooseBarButton], animated: true)
        
        view.addSubview(editPhotoToolbar)
    }
    
    func centerScrollViewContents() {
        var boundsSize: CGSize = editProfilePhotoScrollView.bounds.size
        var contentsFrame: CGRect = photoImageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2
        } else {
            contentsFrame.origin.x = 0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2
        } else {
            contentsFrame.origin.y = 0
        }
        
        photoImageView.frame = contentsFrame
    }
    
    // MARK: UIScrollViewDelegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerScrollViewContents()
    }
    
    // toolbar button callbacks
    func cancelButtonPressed(sender: UIButton) {
        // go back to edit profile
        self.navigationController!.delegate = nil
        
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
        
        if fromSnapPhotoView {
            // pop twice
            self.navigationController!.popToViewController(self.navigationController?.childViewControllers[self.navigationController!.childViewControllers.count - 3] as! UIViewController, animated: false)
        } else {
            self.navigationController!.popViewControllerAnimated(false)
        }
    }
    
    func chooseButtonPressed(sender: UIButton) {
        var scale: CGFloat = 1.0 / editProfilePhotoScrollView.zoomScale
        
        var visibleRect: CGRect = CGRect()
        visibleRect.origin.x = editProfilePhotoScrollView.contentOffset.x * scale
        visibleRect.origin.y = editProfilePhotoScrollView.contentOffset.y * scale
        visibleRect.size.width = editProfilePhotoScrollView.bounds.size.width * scale
        visibleRect.size.height = editProfilePhotoScrollView.bounds.size.height * scale
        
        // crop image in scrollview
        var croppedImage = cropImage(fixOrientation(photoImageView.image!), rect: visibleRect)
        
        // delegate call to EditProfileViewController
        switch photoType {
        case SelectedPhotoType.Profile:
            delegate?.profilePhotoCropped(croppedImage)
            
        case SelectedPhotoType.Cover:
            delegate?.coverPhotoCropped(croppedImage)
            
        default:
            fatalError("Error: Invalid Photo State in EditProfileViewController.")
        }
        
        cancelButtonPressed(UIButton())
    }
    
    private func cropImage(srcImage: UIImage, rect: CGRect) -> UIImage {
        var cr: CGImageRef = CGImageCreateWithImageInRect(srcImage.CGImage, rect)
        var cropped: UIImage = UIImage(CGImage: cr)!
        
        return cropped;
    }
    
    private func fixOrientation(img: UIImage) -> UIImage {
        if (img.imageOrientation == UIImageOrientation.Up) {
            return img;
        }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale);
        let rect = CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        img.drawInRect(rect)
        
        var normalizedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return normalizedImage;
    }
}
