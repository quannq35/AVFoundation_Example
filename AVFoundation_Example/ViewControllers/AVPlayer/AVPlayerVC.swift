//
//  AVPlayerViewController.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 18/3/25.
//

import UIKit
import AVKit
import AVFoundation
import SnapKit
import Photos


class AVPlayerVC: UIViewController {
    
    @IBOutlet weak var speedButton: UIImageView!
    @IBOutlet weak var soundOffButton: UIImageView!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var lbTotalTime: UILabel!
    @IBOutlet weak var lbCurrentTime: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var pauseButton: UIImageView!
    @IBOutlet weak var forwardButton: UIImageView!
    @IBOutlet weak var backwardButton: UIImageView!
    
    private var player: AVPlayer? = nil
    private var playerLayer: AVPlayerLayer? = nil
    private var speedSelectionView: SpeedSelectionView?
    private var isSoundOff: Bool = false
    private var isThumbSeek : Bool = false
    private var timeObserver: Any? = nil
    let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    
    private lazy var trimButton: UIButton = {
        let button = UIButton()
        button.setTitle("Trim Video", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    private func setupUI() {
        self.view.addSubview(trimButton)
        setupAction()
        setupVideo()
        setupContraints()
        NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        if let url = URL(string: videoURL) {
            let asset = AVURLAsset(url: url)
            Task {
                let duration = try? await asset.load(.duration)
                lbTotalTime.text = convertTime(value: Float64(duration?.seconds ??  0))
            }
        }
    }
    
    private func setupAction() {
        backwardButton.isUserInteractionEnabled = true
        backwardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (bacwardButtonPressed)))
        
        pauseButton.isUserInteractionEnabled = true
        pauseButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pauseButtonPressed)))
        
        forwardButton.isUserInteractionEnabled = true
        forwardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forwardButtonPressed)))
        
        soundOffButton.isUserInteractionEnabled = true
        soundOffButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(soundOffButtonPress)))
        
        speedButton.isUserInteractionEnabled = true
        speedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(speedButtonButtonPress)))
        seekSlider.addTarget(self, action: #selector(onTapToSlider), for: .valueChanged)
        
        trimButton.addTarget(self, action: #selector(trimButtonTapped), for: .touchUpInside)
    }

    private func setupContraints() {
        trimButton.snp.makeConstraints { make in
            make.top.equalTo(videoView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(44)
        }
    }
    
    
    private func setupVideo() {
        guard let videoURL = URL(string: videoURL) else { return }
        if self.player == nil {
            self.player = AVPlayer(url: videoURL)
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.videoView.bounds
            if let playerLayer = self.playerLayer {
                self.videoView.layer.insertSublayer(playerLayer, at: 0)
            }
        }
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsed in
            self.updateVideoTime()
        })
    }
    
    private func updateVideoTime() {
        guard let currentTime = self.player?.currentTime() else { return } // Lấy thời gian hiện tại của video dưới dạng CMTime
        guard let duration = self.player?.currentItem?.duration else { return } // Lấy tổng thời gian của video dưới dạng CMTime
        
        let currentTimeInSecond = CMTimeGetSeconds(currentTime) // Chuyển đổi CMTime thành số giây Double
        let durationTimeInSecond = CMTimeGetSeconds(duration)
        
        // Nếu người dùng không kéo thanh trượt thì update lại giá trị của Slider
        if !self.isThumbSeek {
            self.seekSlider.value = Float(currentTimeInSecond / durationTimeInSecond)
        }
                
        let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration) // Lấy giá trị hiện tại đã chạy được
        
        let hours = value / 3600 // Tính số giờ
        
        // truncationgRemaider: Hiểu đơn giản phép chia lấy phần dư.. vế đầu là số bị chia  , dividingBy là số chia
        let mins = (value / 60).truncatingRemainder(dividingBy: 60)
        let secs = value.truncatingRemainder(dividingBy: 60)
        
        let timeFormater = NumberFormatter()
        timeFormater.minimumIntegerDigits = 2 // Luôn hiển thị ít nhất 2 chữ số 01, 02
        timeFormater.minimumFractionDigits = 0 // Không hiển thị phần thập phân
        timeFormater.roundingMode = .down   // làm tròn xuống (tránh lỗi hiển thị 60s)
        guard let _ = timeFormater.string(from: NSNumber(value: hours)),
              let minStr = timeFormater.string(from: NSNumber(value: mins)),
              let secStr = timeFormater.string(from: NSNumber(value: secs)) else { return }
        
        self.lbCurrentTime.text = "\(minStr):\(secStr)"
        
        // update lbTotalTime
        
        let hoursRemaining = (durationTimeInSecond / 3600) - hours
        let minsRemaining = (durationTimeInSecond / 60).truncatingRemainder(dividingBy: 60) - mins
        let secsRemaining = durationTimeInSecond.truncatingRemainder(dividingBy: 60) - secs
    
        timeFormater.minimumIntegerDigits = 2
        timeFormater.maximumFractionDigits = 0
        timeFormater.roundingMode = .down
        
        guard let _ = timeFormater.string(from: NSNumber(value: hoursRemaining)),
              let minStrTotal = timeFormater.string(from: NSNumber(value: minsRemaining)),
              let secStrTotal = timeFormater.string(from: NSNumber(value: secsRemaining)) else { return }
        self.lbTotalTime.text = "\(minStrTotal):\(secStrTotal)"
    }

    
    @objc private func bacwardButtonPressed() {
        print("backward")
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10sec = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10sec), timescale: 1)
        self.player?.seek(to: seekTime)
    }
    
    @objc private func pauseButtonPressed() {
    
        if player?.timeControlStatus == .playing {
            player?.pause()
            self.pauseButton.image = UIImage(systemName: "play.circle")
        } else {
            player?.play()
            self.pauseButton.image = UIImage(systemName: "pause.circle")
        }
    }
    
    @objc func trimButtonTapped() {
        self.trimButton.setTitle("Trim Video... 0%", for: .normal)

        trimVideo(percent: { percent, url in
            let loadingAlert = UIAlertController(title: nil, message: "Trimming video... \(percent)", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            loadingAlert.view.addSubview(loadingIndicator)
//            self.present(loadingAlert, animated: true)
//            print(percent)
            self.trimButton.setTitle("Trim Video... \(Int(percent * 100))%", for: .normal)
            if percent == 1 {
//                self.saveVideoToPhotos(url)
            }
        })

    }
    
    @objc private func forwardButtonPressed() {
        print("forward")
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10sec = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10sec), timescale: 1)
        self.player?.seek(to: seekTime)
    }
    
    @objc private func videoDidFinishPlaying() {
        player?.seek(to: .zero)
        pauseButton.image = UIImage(systemName: "play.circle")
    }
    
    @objc private func speedButtonButtonPress(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: view)

        UIView.animate(withDuration: 0.1, animations: {
            self.speedButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        }) { finished in
            if finished {
                self.speedButton.transform = .identity
            }
        }
        if let existinPopup = speedSelectionView {
            existinPopup.removeFromSuperview()
            self.speedSelectionView = nil
            return
        }
        
        let popupWidth: CGFloat = 100
        let popupHeight: CGFloat = 120
        let margin: CGFloat = 8
        var popupY = tapLocation.y - popupHeight - margin - 16
        
        if popupY < self.view.safeAreaInsets.top {
            popupY = tapLocation.y + margin
        }
        let speedView = SpeedSelectionView(frame: CGRect(x: tapLocation.x - popupWidth / 2, y: popupY, width: popupWidth, height: popupHeight))
        speedView.alpha = 0
        speedView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        self.view.addSubview(speedView)
        self.speedSelectionView = speedView
        
        self.speedSelectionView?.speedSelected = { [weak self] rate in
            self?.player?.rate = rate
            UIView.animate(withDuration: 0.5, animations: {
                self?.speedSelectionView?.alpha = 0
            }) { finished in
                if finished {
                    speedView.removeFromSuperview()
                    self?.speedSelectionView = nil
                }
            }
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            speedView.alpha = 1
            speedView.transform = .identity
        }
    }
    
    @objc private func soundOffButtonPress() {
        isSoundOff.toggle()
        if isSoundOff {
            soundOffButton.image = UIImage(systemName: "speaker.slash")
            player?.isMuted = true
        } else {
            soundOffButton.image = UIImage(systemName: "speaker.2")
            player?.isMuted = false
        }
    }
    
    @objc private func onTapToSlider() {
        self.isThumbSeek = true
        guard let duration = player?.currentItem?.duration else { return }
        let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration)
        if value.isNaN == false {
            let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
            self.player?.seek(to: seekTime) { completion in
                self.isThumbSeek = false
            }
        }
    }
    
    private func trimVideo(percent: @escaping ((Float, URL) -> Void)) {
        guard let videoURL = URL(string: videoURL) else { return }
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        // Load Video trach
        let videoTrack = asset.tracks(withMediaType: .video)
        guard let assetTrack = videoTrack.first, let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        
        let startTime = CMTime(seconds: 5, preferredTimescale: 600)
        let endTime = CMTime(seconds: 50, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        try? compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentPath.appendingPathComponent("trimmed_video.mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else { return }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            print("Progress: \(exportSession.progress * 100)%")
            
            // Cập nhật UI, ví dụ: progress bar
            percent(exportSession.progress, outputURL)

            if exportSession.status == .completed || exportSession.status == .failed {
                timer.invalidate() // Dừng timer nếu export xong hoặc thất bại
            }
        }
        
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                print(outputURL)
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    private func saveVideoToPhotos(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("❌ Không có quyền truy cập thư viện ảnh")
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
//                request?.isFavorite = true // Tuỳ chọn: đánh dấu video là yêu thích
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Video đã được lưu vào thư viện ảnh")
                    } else {
                        print("❌ Lỗi khi lưu video: \(error?.localizedDescription ?? "Không rõ lỗi")")
                    }
                }
            }
        }
    }
    
    private func convertTime(value: Float64) -> String {
        let hours = value / 3600 // Tính số giờ
        // truncationgRemaider: Hiểu đơn giản phép chia lấy phần dư.. vế đầu là số bị chia  , dividingBy là số chia
        let mins = (value / 60).truncatingRemainder(dividingBy: 60)
        let secs = value.truncatingRemainder(dividingBy: 60)
        let timeFormater = NumberFormatter()
        timeFormater.minimumIntegerDigits = 2 // Luôn hiển thị ít nhất 2 chữ số 01, 02
        timeFormater.minimumFractionDigits = 0 // Không hiển thị phần thập phân
        timeFormater.roundingMode = .down   // làm tròn xuống (tránh lỗi hiển thị 60s)
        guard let _ = timeFormater.string(from: NSNumber(value: hours)),
              let minStr = timeFormater.string(from: NSNumber(value: mins)),
              let secStr = timeFormater.string(from: NSNumber(value: secs)) else { return ""}
        
        return "\(minStr):\(secStr)"
    }
}
