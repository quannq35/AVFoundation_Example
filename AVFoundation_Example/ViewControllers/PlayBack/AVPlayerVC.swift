//
//  AVPlayerViewController.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 18/3/25.
//

import UIKit
import AVKit
import AVFoundation
class AVPlayerVC: UIViewController {
    
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var lbTotalTime: UILabel!
    @IBOutlet weak var lbCurrentTime: UILabel!
    @IBOutlet weak var containerVideoView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var pauseButton: UIImageView!
    @IBOutlet weak var forwardButton: UIImageView!
    @IBOutlet weak var backwardButton: UIImageView!
    let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    private var player: AVPlayer? = nil
    private var playerLayer: AVPlayerLayer? = nil
    
    var isPlayer = false
    private var isThumbSeek : Bool = false


    override func viewDidLoad() {
        super.viewDidLoad()
        setupAction()
        setupVideoPlayer()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = containerVideoView.bounds
    }
    
    private func setupAction() {
        backwardButton.isUserInteractionEnabled = true
        backwardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (bacwardButtonPressed)))
        
        pauseButton.isUserInteractionEnabled = true
        pauseButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pauseButtonPressed)))
        
        forwardButton.isUserInteractionEnabled = true
        forwardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forwardButtonPressed)))
        
        seekSlider.addTarget(self, action: #selector(onTapToSlider), for: .valueChanged)
    }
    
    private func setupVideoPlayer() {
        guard let videoURL = URL(string: videoURL) else { return }
        if self.player == nil {
            self.player = AVPlayer(url: videoURL)
            self.playerLayer = AVPlayerLayer(player: player)
            self.playerLayer?.videoGravity = .resizeAspectFill
            self.playerLayer?.frame = self.containerVideoView.bounds
            if let playerLayer = self.playerLayer {
                self.videoView.layer.addSublayer(playerLayer)
            }
        }
        setObserverToPlayer()
    }
    
    @objc private func bacwardButtonPressed() {
        print("backward")
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10sec = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
        
    }
    
    @objc private func pauseButtonPressed() {
        isPlayer = !isPlayer
        if isPlayer {
            self.player?.play()
            self.pauseButton.image = UIImage(systemName: "pause.circle")
        } else {
            self.pauseButton.image = UIImage(systemName: "play.circle")
            player?.pause()
        }
    }
    
    @objc private func forwardButtonPressed() {
        print("forward")
        guard let currentTime = self.player?.currentTime() else { return }
        let seekTime10sec = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(seekTime10sec), timescale: 1)
        self.player?.seek(to: seekTime, completionHandler: { completed in
        })
    }
    
    private var timeObserver: Any? = nil
    private func setObserverToPlayer() {
        let interval = CMTime(seconds: 0.3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsed in
            self.updatePlayerTime()
        })
    }
    
    private func updatePlayerTime() {
        guard let currentTime = self.player?.currentTime() else { return } // Lấy thời gian hiện tại của video dưới dạng CMTime
        guard let duration = self.player?.currentItem?.duration else { return } // Lấy tổng thời gian của video dưới dạng CMTime
        
        let currentTimeInSecond = CMTimeGetSeconds(currentTime) // Chuyển đổi CMTime thành số giây Double
        let durationTimeInSecond = CMTimeGetSeconds(duration)
        
        // Nếu người dùng không kéo thanh trượt thì update lại giá trị của Slider
        if !self.isThumbSeek {
            self.seekSlider.value = Float(currentTimeInSecond / durationTimeInSecond)
        }
        
        // update lbCurrentTime
        
        let value = Float64(self.seekSlider.value) * CMTimeGetSeconds(duration) // Lấy giá trị hiện tại đã chạy được
        
        let hours = value / 3600 // Tính số giờ
        
        // truncationgRemaider: Hiểu đơn giản phép chia lấy phần dư.. vế đầu là số bị chia  , dividingBy là số chia
        let mins = (value / 60).truncatingRemainder(dividingBy: 60)
        let secs = value.truncatingRemainder(dividingBy: 60)
        
        let timeFormater = NumberFormatter()
        timeFormater.minimumIntegerDigits = 2 // Luôn hiển thị ít nhất 2 chữ số 01, 02
        timeFormater.minimumFractionDigits = 0 // Không hiển thị phần thập phân
        timeFormater.roundingMode = .down   // làm tròn xuống (tránh lỗi hiển thị 60s)
        guard let hourStr = timeFormater.string(from: NSNumber(value: hours)),
              let minStr = timeFormater.string(from: NSNumber(value: mins)),
              let secStr = timeFormater.string(from: NSNumber(value: secs)) else { return }
        
        self.lbCurrentTime.text = "\(hourStr):\(minStr):\(secStr)"
        
        // update lbTotalTime
        
        let hoursRemaining = (durationTimeInSecond / 3600) - hours
        let minsRemaining = (durationTimeInSecond / 60).truncatingRemainder(dividingBy: 60) - mins
        let secsRemaining = durationTimeInSecond.truncatingRemainder(dividingBy: 60) - secs
    
        timeFormater.minimumIntegerDigits = 2
        timeFormater.maximumFractionDigits = 0
        timeFormater.roundingMode = .down
        
        guard let hourStrTotal = timeFormater.string(from: NSNumber(value: hoursRemaining)),
              let minStrTotal = timeFormater.string(from: NSNumber(value: minsRemaining)),
              let secStrTotal = timeFormater.string(from: NSNumber(value: secsRemaining)) else { return }
        self.lbTotalTime.text = "\(hourStrTotal):\(minStrTotal):\(secStrTotal)"
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
}
