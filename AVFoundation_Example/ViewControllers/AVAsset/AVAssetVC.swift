//
//  AVAssetViewController.swift
//  AVFoundation_Example
//
//  Created by Quân Nguyễn on 18/3/25.
//

import UIKit
import AVFoundation

class AVAssetVC: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    let videoURL = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    var asset: AVAsset?
    var playerItem: AVPlayerItem?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPlayer()
        
    }
    
    private func setupVideoPlayer() {
        guard let assetURL = URL(string: videoURL) else { return }
        asset = AVURLAsset(url: assetURL)
        guard let asset = asset else { return }
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        if let playerLayer = self.playerLayer {
            playerLayer.frame = self.containerView.frame
            playerLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(playerLayer)
            player?.play()
        }
        updateTimePlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = containerView.frame
    }
    
    private func updateTimePlayer() {
       // Lấy thời lượng video
        Task {
            do {
                let duration = try await asset?.load(.duration)
                print(CMTimeGetSeconds(duration ?? CMTime(value: 0, timescale: 1)))
            } catch {
                
            }
        }
        
        // Lấy kích thước video
        Task {
            do {
                if let track = try await asset?.loadTracks(withMediaType: .video) {
                    let size = try await track.first?.load(.naturalSize)
                    print("Kích thước của video là: \(size?.width) x \(size?.height)")
                }
            }
        }
        
        Task {
            do {
                let metadata = try await asset?.load(.commonMetadata)
                for item in metadata ?? [] {
                    if let key = item.commonKey?.rawValue, let value = try await item.load(.value) {
                        print("\(key): \(value)")
                    }
                }
            }
        }
        
    }
    
    
    
    @IBAction func cutVideo(_ sender: Any) {
        
        handleCutVideo()
    }
    
    func handleCutVideo() {
        Task {
            do {
                let exportSession = AVAssetExportSession(asset: asset!, presetName: AVAssetExportPresetLowQuality)!
                let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("output.mp4")
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mp4
                exportSession.timeRange = CMTimeRange(start: CMTime(value: 5, timescale: 600), duration: CMTime(value: 10, timescale: 600))
                
                try await exportSession.export(to: outputURL, as: .mp4)
                print("✅ Xuất video thành công tại: \(outputURL.path)")
            } catch {
                print("Lỗi")
            }
        }
        
    }
    
}
