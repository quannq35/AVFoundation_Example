//
//  AVCaptureSessionViewController.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 18/3/25.
//

import UIKit
import AVFoundation
import Photos

class AVCaptureSessionVC: UIViewController {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let captureOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isRecording = false
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        checkPermissions()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.layer.bounds

    }
    
    private func checkPermissions() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupCaptureSession()
                setupPreviewLayer()

                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                    print("Session đã bắt đầu chạy trên background thread")
                }            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            self.setupCaptureSession()
                        }
                    }
                }
            default:
                print("Không có quyền truy cập camera")
            }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            captureSession.commitConfiguration()
            return
        }
        
        guard let audioDevice = AVCaptureDevice.default( for: .audio), let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }
            
        captureSession.commitConfiguration()
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    @IBAction func recordButtonTap(_sender: UIButton) {
        if !isRecording {
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let outputPath = "\(documentPath)/output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            try? FileManager.default.removeItem(at: outputURL)
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            recordButton.setTitle("Stop", for: .normal)
            isRecording.toggle()
        } else {
            recordButton.setTitle( "Record", for: .normal)
            videoOutput.stopRecording()
            isRecording.toggle()
        }
    }
    
    @IBAction func captureButtonTapped(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension AVCaptureSessionVC: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        PHPhotoLibrary.shared().performChanges ({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        }) { success, error in
            if success {
                print("Video đã được lưu vào thư viện ảnh")
                try? FileManager.default.removeItem(at: outputFileURL)
            } else {
                print("Lỗi")
            }
        }
        
    }
}

extension AVCaptureSessionVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Lỗi khi chụp ảnh: \(error)")
            return
        }
        // Xử lý dữ liệu ảnh
        if let imageData = photo.fileDataRepresentation() {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: imageData, options: nil)
                    }) { success, error in
                        if success {
                            print("Đã lưu ảnh vào thư viện!")
                        } else if let error = error {
                            print("Lỗi khi lưu ảnh: \(error)")
                        }
                    }
                } else {
                    print("Không có quyền truy cập thư viện ảnh")
                }
            }
        }
    }
}

