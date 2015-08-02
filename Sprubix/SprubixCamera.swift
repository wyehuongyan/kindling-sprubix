//
//  SprubixCamera.swift
//  Sprubix
//
//  Created by Yan Wye Huong on 22/4/15.
//  Copyright (c) 2015 Sprubix. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol SprubixCameraDelegate {
    func cameraSessionConfigurationDidComplete()
    func cameraSessionDidBegin()
    func cameraSessionDidStop()
}

class SprubixCamera: NSObject {
    weak var delegate: SprubixCameraDelegate?
    
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var stillImageOutput: AVCaptureStillImageOutput?
    
    init(sender: AnyObject, front: Bool) {
        super.init()
        self.delegate = sender as? SprubixCameraDelegate
        self.setObservers()
        self.initializeSession(front)
    }
    
    deinit {
        self.removeObservers()
    }
    
    // MARK: Session
    
    func initializeSession(front: Bool) {
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetPhoto
        self.sessionQueue = dispatch_queue_create("camera session", DISPATCH_QUEUE_SERIAL)
        
        dispatch_async(self.sessionQueue) {
            self.session.beginConfiguration()

            front ? self.addVideoInputFront() : self.addVideoInputBack()
            self.addStillImageOutput()
            self.session.commitConfiguration()
            
            dispatch_async(dispatch_get_main_queue()) {
                NSLog("Session initialization did complete")
                self.delegate?.cameraSessionConfigurationDidComplete()
            }
        }
    }
    
    func startCamera() {
        dispatch_async(self.sessionQueue) {
            self.session.startRunning()
        }
    }
    
    func stopCamera() {
        dispatch_async(self.sessionQueue) {
            self.session.stopRunning()
        }
    }
    
    func captureStillImage(completed: (image: UIImage?) -> Void) {
        if let imageOutput = self.stillImageOutput {
            dispatch_async(self.sessionQueue, { () -> Void in
                
                var videoConnection: AVCaptureConnection?
                for connection in imageOutput.connections {
                    let c = connection as! AVCaptureConnection
                    
                    for port in c.inputPorts {
                        let p = port as! AVCaptureInputPort
                        if p.mediaType == AVMediaTypeVideo {
                            videoConnection = c;
                            break
                        }
                    }
                    
                    if videoConnection != nil {
                        break
                    }
                }
                
                if videoConnection != nil {
                    var error: NSError?
                    imageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (imageSampleBuffer: CMSampleBufferRef!, error) -> Void in
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        let image: UIImage? = UIImage(data: imageData!)!
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            completed(image: image)
                        }
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        completed(image: nil)
                    }
                }
            })
        } else {
            completed(image: nil)
        }
    }
    
    
    // MARK: Configuration
    
    func addVideoInputBack() {
        var error: NSError?
        var device: AVCaptureDevice = self.deviceWithMediaTypeWithPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
        var input: AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as! AVCaptureDeviceInput
        
        if error == nil {
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
        }
    }
    
    func addVideoInputFront() {
        var error: NSError?
        var device: AVCaptureDevice = self.deviceWithMediaTypeWithPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Front)
        var input: AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as! AVCaptureDeviceInput
        
        if error == nil {
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
        }
    }
    
    func addStillImageOutput() {
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        if self.session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
    }
    
    func focus(point: CGPoint, preview: AVCaptureVideoPreviewLayer) {
        var device: AVCaptureDevice = self.deviceWithMediaTypeWithPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
    
        if(device.focusPointOfInterestSupported && device.isFocusModeSupported(AVCaptureFocusMode.AutoFocus)) {
            let focusPoint:CGPoint = preview.captureDevicePointOfInterestForPoint(point)
            
            if(device.lockForConfiguration(nil)) {
                device.focusPointOfInterest = CGPointMake(focusPoint.x, focusPoint.y)
                device.focusMode = AVCaptureFocusMode.AutoFocus
                
                if (device.isExposureModeSupported(AVCaptureExposureMode.AutoExpose)) {
                    device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
                }
                
                device.unlockForConfiguration()
            }
        }
    }
    
    func deviceWithMediaTypeWithPosition(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        var devices: NSArray = AVCaptureDevice.devicesWithMediaType(mediaType as String)
        var captureDevice: AVCaptureDevice = devices.firstObject as! AVCaptureDevice
        for device in devices {
            let d = device as! AVCaptureDevice
            if d.position == position {
                captureDevice = d
                break;
            }
        }
        return captureDevice
    }
    
    // MARK: Observers
    
    func setObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidStart:", name: AVCaptureSessionDidStartRunningNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionDidStop:", name: AVCaptureSessionDidStopRunningNotification, object: nil)
    }
    
    func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func sessionDidStart(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("Session did start")
            self.delegate?.cameraSessionDidBegin()
        }
    }
    
    func sessionDidStop(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLog("Session did stop")
            self.delegate?.cameraSessionDidStop()
        }
    }
}
