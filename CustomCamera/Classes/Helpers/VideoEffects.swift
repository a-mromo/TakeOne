//
//  VideoEffects.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/11/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import AVFoundation
import UIKit
import Photos

extension CameraViewController {
    
    func applyVideoEffects(to composition: AVMutableVideoComposition, size: CGSize, currentLabel: UILabel) {
        
        let overlayLayer = CALayer()
        var overlayImage: UIImage? = nil
        overlayImage = UIImage.createTransparentImageFrom(label: currentLabel, imageSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        overlayLayer.contents = overlayImage?.cgImage
        overlayLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        overlayLayer.masksToBounds = true
        
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
    }
    
    func videoOutput(videoAsset: AVAsset, label: UILabel) {
        
        let mixComposition = AVMutableComposition()
        
        guard let videoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
        do {
            try videoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: AVMediaType.video)[0], at: CMTime.zero)
        } catch {
            print("Error selecting video track !!")
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
        
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
        let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video)[0]
        var videoAssetOrientation = UIImage.Orientation.up
        var isVideoAssetPortrait = false
        let videoTransform = videoAssetTrack.preferredTransform
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation = .right
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation = .left
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation = .up
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation = .down
        }
        
        videoLayerInstruction.setTransform(videoAssetTrack.preferredTransform, at: CMTime.zero)
        videoLayerInstruction.setOpacity(0.0, at: videoAsset.duration)
        
        mainInstruction.layerInstructions = [videoLayerInstruction]
        let mainCompositionInst = AVMutableVideoComposition()
        let naturalSize : CGSize!
        if isVideoAssetPortrait {
            naturalSize = CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width)
        } else {
            naturalSize = videoAssetTrack.naturalSize
        }
        
        let renderWidth = naturalSize.width
        let renderHeight = naturalSize.height
        
        mainCompositionInst.renderSize = CGSize(width: renderWidth, height: renderHeight)
        mainCompositionInst.instructions = [mainInstruction]
        mainCompositionInst.frameDuration = CMTime(value: 1, timescale: 30)
        
        self.applyVideoEffects(to: mainCompositionInst, size: naturalSize, currentLabel: label)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let outputPath = documentsURL?.appendingPathComponent("newVideoWithLabel.mp4")
        if FileManager.default.fileExists(atPath: (outputPath?.path)!) {
            do {
                try FileManager.default.removeItem(atPath: (outputPath?.path)!)
            }
            catch {
                print ("Error deleting file")
            }
        }
        
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = outputPath
        exporter?.outputFileType = AVFileType.mov
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = mainCompositionInst
        exporter?.exportAsynchronously(completionHandler: {
            self.exportDidFinish(session: exporter!)
        })
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        if session.status == .completed {
            let outputURL: URL? = session.outputURL
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL!)
            }) { saved, error in
                if saved {
                    // Needs refactor: setVideoThumbnail...
                    
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                    let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                    PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                        let newObj = avurlAsset as! AVURLAsset
//                        print(newObj.url)
                        DispatchQueue.main.async(execute: {
//                            print(newObj.url.absoluteString)
                            self.setVideoThumbnailFromURL(newObj.url)
                        })
                    })
                    print (fetchResult!)
                }
            }
        }
    }
}

