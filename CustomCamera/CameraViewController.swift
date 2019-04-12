//
//  ViewController.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/4/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

import UIKit
import AVFoundation
import Photos
import MobileCoreServices

class CameraViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var activeInput: AVCaptureDeviceInput!
    private let imageOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    
    private let locationManager = CLLocationManager()
    private var currentUserLocation: CLLocation?
    
    private var focusMarker: UIImageView!
    private var exposureMarker: UIImageView!
    
    private var colorPalette = [ColorSwatch]()
    private var weatherData: WeatherData?
    
    private lazy var bottomControlsBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        view.clipsToBounds = true
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        return view
    }()
    
    @IBOutlet weak var thumbnailButton: UIButton!
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBOutlet weak var colorPaletteButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: CopyableLabel!
    @IBOutlet weak var botomControlsStackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var adjustingExposureContext: String = ""
    fileprivate var updateTimer: Timer!
    
    private let dataManager = DataManager(baseURL: API.authenticatedBaseURL)
    
    private func setupSessionAndPreview() {
        captureSession.sessionPreset = .high
        let camera = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        }
        catch {
            print("Error setting up", error)
        }
        imageOutput.isHighResolutionCaptureEnabled = true
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone!)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return
        }
        
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
        
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraPreview.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreview.layer.addSublayer(previewLayer)
        
        let tapForFocus = UITapGestureRecognizer(target: self, action: #selector(tapToFocus(_:)))
        tapForFocus.numberOfTapsRequired = 1
        cameraPreview.addGestureRecognizer(tapForFocus)
        
        let tapForExposure = UITapGestureRecognizer(target: self, action: #selector(tapToExpose(_:)))
        tapForExposure.numberOfTapsRequired = 2
        cameraPreview.addGestureRecognizer(tapForExposure)
        
        tapForFocus.require(toFail: tapForExposure)
        
        focusMarker = UIImageView(image: UIImage(named:"Focus_Point"))
        focusMarker.isHidden = true
        cameraPreview.addSubview(focusMarker)
        
        exposureMarker = UIImageView(image: UIImage(named:"Exposure_Point"))
        exposureMarker.isHidden = true
        cameraPreview.addSubview(exposureMarker)
    }
    
    private func setupCollectionView(){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isHidden = true
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getColorPalette()
        setupCollectionView()
        setupSessionAndPreview()
        startSession()
//        getWeatherData()
        pinBackground(bottomControlsBackgroundView, to: botomControlsStackView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraPreview.bounds
        
        let connection = imageOutput.connection(with: AVMediaType.video)
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = currentVideoOrientation()
        }
    }
    
    deinit {
        stopSession()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func cameraToggleTapped(_ sender: Any) {
        toggleCameras()
    }
    
    @IBAction func thumbnailTapped(_ sender: Any) {
        startMediaBrowserFromViewController(viewController: self, usingDelegate: self)
    }
    
    @IBAction func captureTapped(_ sender: Any) {
        captureMovie()
    }
    
    @IBAction func colorPaletteTapped(_ sender: UIButton) {
        guard !movieOutput.isRecording else { return }
        collectionView.isHidden = !collectionView.isHidden
        colorPaletteButton.setImage(collectionView.isHidden ? UIImage(named: "ColorPalette-Inactive") : UIImage(named: "ColorPalette-Active"), for: .normal)
    }
    
}

extension CameraViewController {
    // MARK: Helpers
    private func pinBackground(_ view: UIView, to stackView: UIStackView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        stackView.insertSubview(view, at: 0)
        view.pin(to: stackView)
    }
}

extension CameraViewController {
    func toggleCameras() {
        
        guard !movieOutput.isRecording else {
            return
        }
        
        let discoverySession =
            AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                             mediaType: AVMediaType.video,
                                             position: AVCaptureDevice.Position.unspecified)
        
        let newPosition: AVCaptureDevice.Position
        switch activeInput.device.position {
        case .back:
            newPosition = .front
            toggleCameraButton.setImage(UIImage(named: "CameraSwitch-Active"), for: .normal)
        case .front:
            newPosition = .back
            toggleCameraButton.setImage(UIImage(named: "CameraSwitch-Inactive"), for: .normal)
        case .unspecified:
            newPosition = .back
            toggleCameraButton.setImage(UIImage(named: "CameraSwitch-Inactive"), for: .normal)
        }
        
        guard let newCamera = discoverySession.devices
            .first(where: { $0.position == newPosition }) else {
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: newCamera)
            captureSession.beginConfiguration()
            
            captureSession.removeInput(activeInput)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            } else {
                captureSession.addInput(activeInput)
            }
            captureSession.commitConfiguration()
        } catch {
            print("Error switching cameras: \(error)")
        }
    }
}


extension CameraViewController {
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.global(qos: .default)
    }
    
    func startSession() {
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
}


extension CameraViewController {
    
    func showMarkerAtPoint(_ point: CGPoint, marker: UIImageView) {
        marker.center = point
        marker.isHidden = false
        
        UIView.animate(withDuration: 0.15,
                       delay: 0.0,
                       options: [],
                       animations: {
                        marker.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { _ in
            let popTime = DispatchTime.now() + 0.5
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                marker.isHidden = true
                marker.transform = .identity
            })
        }
    }
    
    // MARK: Focus Methods
    @objc func tapToFocus(_ recognizer: UIGestureRecognizer) {
        if activeInput.device.isFocusPointOfInterestSupported {
            let point = recognizer.location(in: cameraPreview)
            let pointOfInterest = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            showMarkerAtPoint(point, marker: focusMarker)
            focusAtPoint(pointOfInterest)
        }
    }
    
    func focusAtPoint(_ point: CGPoint) {
        let device = activeInput.device

        if (device.isFocusPointOfInterestSupported) &&
            (device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus)) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = point
                device.focusMode = AVCaptureDevice.FocusMode.autoFocus
                device.unlockForConfiguration()
            } catch {
                print("Error focusing on POI: \(error)")
            }
        }
    }
    
    // MARK: Exposure Methods
    @objc func tapToExpose(_ recognizer: UIGestureRecognizer) {
        if activeInput.device.isExposurePointOfInterestSupported {
            let point = recognizer.location(in: cameraPreview)
            let pointOfInterest = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            showMarkerAtPoint(point, marker: exposureMarker)
            exposeAtPoint(pointOfInterest)
        }
    }
    
    func exposeAtPoint(_ point: CGPoint) {
        let device = activeInput.device
        if (device.isExposurePointOfInterestSupported) &&
            (device.isExposureModeSupported(.continuousAutoExposure)) {
            do {
                try device.lockForConfiguration()
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
                
                if (device.isExposureModeSupported(.locked)) {
                    device.addObserver(self,
                                       forKeyPath: "adjustingExposure",
                                       options: NSKeyValueObservingOptions.new,
                                       context: &adjustingExposureContext)
                    
                    device.unlockForConfiguration()
                }
            } catch {
                print("Error exposing on POI: \(error)")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        if context == &adjustingExposureContext {
            let device = object as! AVCaptureDevice
            if !device.isAdjustingExposure &&
                device.isExposureModeSupported(AVCaptureDevice.ExposureMode.locked) {
                (object as AnyObject).removeObserver(self,
                                                     forKeyPath: "adjustingExposure",
                                                     context: &adjustingExposureContext)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    do {
                        try device.lockForConfiguration()
                        device.exposureMode = AVCaptureDevice.ExposureMode.locked
                        device.unlockForConfiguration()
                    } catch {
                        print("Error exposing on POI: \(error)")
                    }
                })
                
            }
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }
}

extension CameraViewController {
    // MARK: - Saving photo to photo album
    func savePhotoToLibrary(_ image: UIImage) {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            if success {

                self.setPhotoThumbnail(image)
            } else {
                print("Error writing to photo library: ", String(describing: error))
            }
        }
    }
    
    func setPhotoThumbnail(_ image: UIImage) {
        DispatchQueue.main.async { () -> Void in
            self.thumbnailButton.setBackgroundImage(image, for: .normal)
            self.thumbnailButton.layer.borderColor = UIColor.white.cgColor
            self.thumbnailButton.layer.borderWidth = 1.0
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeRight
        case .unknown, .faceUp, .faceDown:
            orientation = .landscapeRight
        }
        return orientation
    }
    
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("there was an error acquiring", error)
            return
        }
        
        let image = UIImage(data: photo.fileDataRepresentation()!)
        self.savePhotoToLibrary(image!)
    }
    
}



extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func captureMovie() {
        if !movieOutput.isRecording {
            if !collectionView.isHidden {
                collectionView.isHidden = true
                colorPaletteButton.setImage(UIImage(named: "ColorPalette-Inactive"), for: .normal)
            }
            
            guard let connection = movieOutput.connection(with: .video) else {
                return
            }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
            
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
            
            let device = activeInput.device
            if device.isSmoothAutoFocusSupported {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
            }
            let outputURL = temporaryURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
    func setVideoThumbnailFromURL(_ movieURL: URL) {
        videoQueue().async {
            let asset = AVAsset(url: movieURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let imageRef = try imageGenerator.copyCGImage(at: CMTime.zero,
                                                              actualTime: nil)
                let image = UIImage(cgImage: imageRef)
                self.setPhotoThumbnail(image)
            } catch {
                print("Error generating image: \(error)")
            }
        }
    }
    
    func saveMovieToLibrary(_ movieURL: URL) {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: movieURL)
        }) { success, error in
            if success {
                // Set thumbnail
                self.setVideoThumbnailFromURL(movieURL)
            } else {
                print("Error writing to movie library: \(error!.localizedDescription)")
            }
        }
    }
    
    func startTimer() {
        if updateTimer != nil {
            updateTimer.invalidate()
        }
        
        updateTimer = Timer(timeInterval: 0.5,
                            target: self,
                            selector: #selector(updateTimeDisplay(_:)),
                            userInfo: nil,
                            repeats: true)
        
        RunLoop.main.add(updateTimer, forMode: .common)
    }
    
    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func updateTimeDisplay(_ sender: Timer) {
        let time = UInt(CMTimeGetSeconds(movieOutput.recordedDuration))
        timeLabel.text = formattedCurrentTime(time)
    }
    
    func temporaryURL() -> URL {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        return directory.appendingPathComponent("temp.mov")
    }
    
    func formattedCurrentTime(_ time: UInt) -> String {
        let hours = time / 3600
        let minutes = (time / 60) % 60
        let seconds = time % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        captureButton.setImage(UIImage(named: "Capture-Active"), for: .normal)
        startTimer()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error {
            print("Error recording movie:", error)
            return
        }

        let videoAsset = AVAsset.init(url: outputFileURL)
        guard let label = temperatureLabel.copy() as? UILabel else { return }
        videoOutput(videoAsset: videoAsset, label: label)
        captureButton.setImage(UIImage(named: "Capture-Inactive"), for: .normal)
        stopTimer()
    }
}

// MARK: Networking

extension CameraViewController {
    
    func getWeatherData() {
        dataManager.weatherDataForLocation(latitude: Defaults.latitude, longitude: Defaults.longitude) { (response, error)  in
            if let error = error {
                print("Failed to get data from url", error)
                return
            }
            
            guard let response = response else { return }
            self.weatherData = response
            self.updateWeatherLabel(temperature: self.weatherData?.hourData.data.first?.temperature ?? 0)
        }
    }
    
    func parseJSONFile(forResource resource: String)  {
        if let path = Bundle.main.path(forResource: resource, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                colorPalette = try decoder.decode([ColorSwatch].self, from: data)
            } catch let error {
                print("Error: ", error)
            }
        }
    }
    
    func getColorPalette() {
        parseJSONFile(forResource: "ColorData")
        collectionView.reloadData()
    }
    
    func updateWeatherLabel(temperature: Double) {
        self.temperatureLabel.text = "\(Int(round(temperature)))°F"
    }
    
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func startMediaBrowserFromViewController(viewController: UIViewController, usingDelegate delegate: UINavigationControllerDelegate & UIImagePickerControllerDelegate ) -> Bool {
    
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false { return false }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .savedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        mediaUI.allowsEditing = false
        mediaUI.delegate = delegate
        
        present(mediaUI, animated: true, completion: nil)
        return true
    }
    
}

extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colorPalette.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorSwatchCell.identifier, for: indexPath) as? ColorSwatchCell else { return UICollectionViewCell() }
            cell.configure(from: colorPalette[indexPath.row], indexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
            temperatureLabel.textColor = colorPalette[indexPath.row].color
        }
    }
    
}

extension CameraViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 60)
    }
}
