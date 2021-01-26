//
//  CameraView.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/1.
//

import SwiftUI
import AppKit
import Vision
import AVFoundation


struct CameraView: NSViewRepresentable {
    typealias NSViewType = DetectReceiptNumberCameraView
    
    @Binding var receiptNumber: String?
    
    private let width = 640
    private let height = 480
    
    func makeNSView(context: Self.Context) -> Self.NSViewType {
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        let cameraView = DetectReceiptNumberCameraView(frame: rect)
        cameraView.delegate = context.coordinator
        return cameraView
    }
        
    func updateNSView(_ nsView: Self.NSViewType, context: Self.Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator($receiptNumber)
    }
    
    // MARK: - Coordinator
        
    class Coordinator: NSObject, DetectReceiptNumberCameraViewDelegate {
        var receiptNumber: Binding<String?>
        
        init(_ receiptNumber: Binding<String?>) {
            self.receiptNumber = receiptNumber
        }
        
        func detectedReceiptNumber(_ receiptNumber: String?) {
            self.receiptNumber.wrappedValue = receiptNumber
        }
    }
}


/*
 * - DetectReceiptNumberCameraViewDelegate
 */
protocol DetectReceiptNumberCameraViewDelegate: AnyObject {
    func detectedReceiptNumber(_ receiptNumber: String?)
}


/*
 * - DetectReceiptNumberCameraView
 */
class DetectReceiptNumberCameraView: NSView, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var delegate : DetectReceiptNumberCameraViewDelegate?
    
    var cameraDevices : [AVCaptureDevice]!
    var currentCameraDevice : AVCaptureDevice!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoSession : AVCaptureSession!
    
    var camerasPopUpButton : NSPopUpButton!
    var imageView : NSImageView!
    
    
    var hasCameraDevice = false
    var rectangleLayers = [CAShapeLayer]()
    
    let regionOfInterestHeight : CGFloat = 64
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    
    var checkTimer : Timer?
    var lastRefreshDate : Date?
    
    
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        // get camera devices
        cameraDevices = getCameraDevices()

        // setup UI components
        setupUIComponents()

        // setup camera
        setupDefaultCamera()
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Setup
    
    func setupUIComponents() {
        setupMaskView()
        setupCamerasUIComponents()
        setupImageView()
    }
    
    func setupMaskView() {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        
        let topView = NSView()
        topView.wantsLayer = true
        topView.layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.5).cgColor
        stackView.addView(topView, in: .top)
        
        let centerView = NSView()
        centerView.wantsLayer = true
        centerView.layer?.backgroundColor = NSColor.clear.cgColor
        stackView.addView(centerView, in: .center)
        
        let bottomView = NSView()
        bottomView.wantsLayer = true
        bottomView.layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.5).cgColor
        stackView.addView(bottomView, in: .bottom)

        self.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            centerView.heightAnchor.constraint(equalToConstant: regionOfInterestHeight)
        ])
    }
    
    func setupCamerasUIComponents() {
        setupCamerasPopUpButton()
        
        let stackView = NSStackView()
        stackView.edgeInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        stackView.addView(camerasPopUpButton, in: .trailing)
        self.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 32),
            camerasPopUpButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }
        
    func setupCamerasPopUpButton() {
        camerasPopUpButton = NSPopUpButton()
                
        if cameraDevices.count <= 0 {
            camerasPopUpButton.addItem(withTitle: "No Camera Device")
            hasCameraDevice = false
            return
        }
        
        for device in cameraDevices {
            camerasPopUpButton.addItem(withTitle: "\(device.localizedName)")
        }
        hasCameraDevice = true
        
        camerasPopUpButton.target = self
        camerasPopUpButton.action = #selector(onSelectCamerasPopUpButton)
    }
    
    func setupImageView() {
        imageView = NSImageView()
        imageView.frame = CGRect(x: 10, y: 5, width: 120, height: 50)
        self.addSubview(imageView)
    }
    
    func setupDefaultCamera() {
        if cameraDevices.count > 0 {
            if let device = cameraDevices.first {
                startUpCameraDevice(device)
            }
        }
    }
    
    
    // MARK: - Camera Devices
            
    func getCameraDevices() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                                                mediaType: .video,
                                                                position: .unspecified)
        return discoverySession.devices
    }
    
    func startUpCameraDevice(_ device: AVCaptureDevice) {
        if prepareCamera(device) {
            startSession()
        }
    }
    
    func prepareCamera(_ device: AVCaptureDevice) -> Bool {
        setCameraFrameRate(20, device: device)
        currentCameraDevice = device
        
        videoSession = AVCaptureSession()
        videoSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if videoSession.canAddInput(input) {
                videoSession.addInput(input)
            }
            
            if let previewLayer = self.previewLayer {
                if let isVideoMirroringSupported = previewLayer.connection?.isVideoMirroringSupported,
                   isVideoMirroringSupported == true
                {
                    previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                    previewLayer.connection?.isVideoMirrored = false
                }
                
                previewLayer.frame = self.bounds
                self.layer = previewLayer
                self.wantsLayer = true
            }
        } catch {
            print(error.localizedDescription)
            return false
        }
            
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        
        if videoSession.canAddOutput(videoOutput) {
            videoSession.addOutput(videoOutput)
        }
        return true
    }
    
    func setCameraFrameRate(_ frameRate: Float64, device: AVCaptureDevice) {
        print("Video Supported Frame Rate Ranges: \(device.activeFormat.videoSupportedFrameRateRanges)")
        
        for frameRateRange in device.activeFormat.videoSupportedFrameRateRanges.reversed() {
            if frameRateRange.minFrameRate == frameRateRange.maxFrameRate {
                if Int(frameRate) == Int(frameRateRange.minFrameRate) {
                    do {
                        try device.lockForConfiguration()
                        device.activeVideoMinFrameDuration = frameRateRange.minFrameDuration
                        device.activeVideoMaxFrameDuration = frameRateRange.maxFrameDuration
                        device.unlockForConfiguration()
                        print("setCameraFrameRate: \(Int(frameRate))")
                        return
                    } catch {
                        print("LockForConfiguration failed with error: \(error.localizedDescription)")
                        break
                    }
                }
            } else if frameRate >= frameRateRange.minFrameRate && frameRate <= frameRateRange.maxFrameRate {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
                    device.unlockForConfiguration()
                    print("setCameraFrameRate: \(Int(frameRate))")
                    return
                } catch {
                    print("LockForConfiguration failed with error: \(error.localizedDescription)")
                    break
                }
            }
        }
        print("Requested FPS is not supported by the device's activeFormat!")
    }
    
    
    // MARK: - Video Session
            
    func startSession() {
        if let videoSession = videoSession {
            if !videoSession.isRunning {
                videoSession.startRunning()
            }
        }
    }
                
    func stopSession() {
        if let videoSession = videoSession {
            if videoSession.isRunning {
                videoSession.stopRunning()
            }
        }
    }
    
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
            
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection)
    {
        guard let result = detectText(sampleBuffer: sampleBuffer)  else {
            DispatchQueue.main.async {
                self.removeAllRectangleLayers()
            }
            return
        }
        
        let (string, rect) = result
        DispatchQueue.main.async {
            self.removeAllRectangleLayers()
            self.drawRectangle(rect)
            self.delegate?.detectedReceiptNumber(string)
            self.lastRefreshDate = Date()
            
            if self.checkTimer == nil {
                self.startUpCheckTimer()
            }
        }
    }
    
    
    // MARK: - Action
        
    @objc func onSelectCamerasPopUpButton(_ sender: NSPopUpButton) {
        if !hasCameraDevice { return }
        
        print("\(sender.indexOfSelectedItem) : \(sender.titleOfSelectedItem ?? "")")
        
        if sender.indexOfSelectedItem < cameraDevices.count {
            let device = cameraDevices[sender.indexOfSelectedItem]
            startUpCameraDevice(device)
        }
    }
    
    
    // MARK: - Detect Text
    
    func detectText(sampleBuffer: CMSampleBuffer) -> (String, CGRect)? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return nil
        }
        
        let request = VNDetectTextRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        try? handler.perform([request])
                
        guard let observations = request.results as? [VNTextObservation] else {
            return nil
        }
        
        if let observation = observationsOfRegionOfInterest(observations).first {
            let ciImage = ciImageOfText(observation, from: pixelBuffer)
            if let resultString = recognizedText(ciImage: ciImage) {
                let rectangleRect = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
                return (resultString, rectangleRect)
            }
        }
        return nil
    }
    
    func observationsOfRegionOfInterest(_ observations: [VNTextObservation]) -> [VNTextObservation] {
        var results = [VNTextObservation]()
        for observation in observations {
            let rectangleRect = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            if chectInRegionOfInterest(rectangleRect: rectangleRect) {
                results.append(observation)
            }
        }
        return results
    }
    
    func drawRectangle(_ rectangleRect: CGRect) {
        let shape = CAShapeLayer()
        shape.frame = rectangleRect
        shape.cornerRadius = 5
        shape.opacity = 0.75
        shape.borderColor = NSColor.red.cgColor
        shape.borderWidth = 2
        
        previewLayer.addSublayer(shape)
        rectangleLayers.append(shape)
    }
    
    func textImage(_ observation: VNTextObservation, from buffer: CVImageBuffer) -> NSImage? {
        let ciImage = ciImageOfText(observation, from: buffer)
        
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return NSImage(cgImage: cgImage, size: .zero)
        }
        return nil
    }
    
    func ciImageOfText(_ observation: VNTextObservation, from buffer: CVImageBuffer) -> CIImage {
        let ciImage = CIImage(cvImageBuffer: buffer)
        
        let rect = CGRect(x: (observation.boundingBox.origin.x * ciImage.extent.size.width),
                          y: (observation.boundingBox.origin.y * ciImage.extent.size.height),
                          width: (observation.boundingBox.width * ciImage.extent.size.width),
                          height: (observation.boundingBox.height * ciImage.extent.size.height))
        
        return ciImage.cropped(to: rect)
    }
    
    
    // MARK: - Text Recognition
    
    func recognizedText(ciImage: CIImage) -> String? {
        let request = VNRecognizeTextRequest()
        request.revision = VNRecognizeTextRequestRevision2
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        try? handler.perform([request])
                
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return nil
        }
        
        for observation in observations {
            if let candidate = observation.topCandidates(1).first {
                print(">>> \(candidate.string)")
                return candidate.string.extractReceiptNumberString()
            }
        }
        return nil
    }
    
    func removeAllRectangleLayers() {
        if rectangleLayers.count <= 0 { return }
        
        for layer in rectangleLayers {
            layer.removeFromSuperlayer()
        }
        rectangleLayers.removeAll()
    }
    
    
    // MARK: - Calculate Region of Interest
    
    func chectInRegionOfInterest(rectangleRect: CGRect) -> Bool {
        if regionOfInterestHeight < previewLayer.frame.height {
            let y1 = (previewLayer.frame.height - regionOfInterestHeight) / 2
            let y2 = y1 + regionOfInterestHeight
            
            if rectangleRect.origin.y >= y1 &&
                rectangleRect.origin.y <= y2 &&
                rectangleRect.size.height <= regionOfInterestHeight
            {
                return true
            }
        }
        return false
    }
    
    
    // MARK: - Check Timer
    
    func startUpCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] (timer) in
            self?.clearReceiptNumber()
        }
    }
    
    func clearReceiptNumber() {
        if let lastDate = lastRefreshDate {
            let timeInterval = Date().timeIntervalSince(lastDate)
            if timeInterval >= 2.5 {
                self.delegate?.detectedReceiptNumber(nil)
            }
        } else {
            lastRefreshDate = Date()
        }
    }
}

