//
//  CameraService.swift
//  FilterCam
//
//  Created by TING YEN KUO on 2024/3/11.
//

import UIKit
import CoreImage
import AVFoundation

protocol PhotoFilterPreviewDelegate {
    func previewFilteredImage(image: UIImage)
}

class CameraService: NSObject {
    typealias Delegate = PhotoFilterPreviewDelegate
    
    enum CameraControllerError: Swift.Error {
        case noCamerasAvailable
        case unknown
    }
    
    enum CameraPosition {
        case front
        case rear
    }
    
    static let shared = CameraService()
    private override init() { }
    
    let session = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    #warning("Make it to default")
    var filter: CIFilter = CIFilter(name: "CIColorMatrix")!
    
    var currentCameraPosition: CameraPosition?
    var frontDeviceInput: AVCaptureDeviceInput?
    var backDeviceInput: AVCaptureDeviceInput?
    let videoOutput = AVCaptureVideoDataOutput()
    
    var delegate: Delegate?
    let context = CIContext()
    
    func setupInputIfAuthorized() {
        guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized else { return }
        
        AVCaptureDevice.requestAccess(
            for: AVMediaType.video,
            completionHandler: { (authorized) in
                DispatchQueue.main.async {
                    if authorized { self.setupInputOutput() }
                }
            }
        )
    }
    
    // Session(device)
    // Device(Input) -> Output
    func setupDevice() throws {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.unspecified
        )
        
        for device in session.devices {
            switch device.position {
            case .back:
                backCamera = device
                backDeviceInput = try AVCaptureDeviceInput(device: backCamera!)
            case .front:
                frontCamera = device
                frontDeviceInput = try AVCaptureDeviceInput(device: frontCamera!)
            default:
                throw CameraControllerError.noCamerasAvailable
            }
        }
        currentCamera = backCamera
        currentCameraPosition = CameraPosition.rear
    }
    
    func setupInputOutput() {
//        do {
            setupHighQualityFramerate(currentCamera: currentCamera!)
            
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
//        session.sessionPreset = .photo
            
            if session.canAddInput(backDeviceInput!) {
                session.addInput(backDeviceInput!)
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
//        } catch {
//            print(error)
//        }
    }
    
    #warning("Why we need to set frame rate here?")
    func setupHighQualityFramerate(currentCamera: AVCaptureDevice) {
        for formats in currentCamera.formats {
            var ranges = formats.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = formats as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        connection.videoOrientation = .portrait // hotcode here
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        let filteredImage = PhotoFilterManager.shared.filtered(ciImage: cameraImage)
        
        let cgImage = context.createCGImage(
            filteredImage!,
            from: cameraImage.extent
        )!
        
        delegate?.previewFilteredImage(image: UIImage(cgImage: cgImage))
    }
}
