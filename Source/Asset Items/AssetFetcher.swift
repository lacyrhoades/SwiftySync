//
//  AssetFetcher.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 11/30/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Photos

public struct AssetInfo {
    var createDate: Date
    var type: AssetSyncItemType
}

public class AssetFetcher {
    static func info(forAssetID assetID: String) -> AssetInfo? {
        let options = PHFetchOptions()
        let request = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: options)
        
        guard let info = request.firstObject else {
            return nil
        }
        
        let date = info.creationDate ?? info.modificationDate ?? Date.distantPast
        
        var type: AssetSyncItemType
        
        switch info.mediaType {
        case .image:
            type = .image
        case .video:
            type = .video
        default:
            return nil
        }
        
        return AssetInfo(createDate: date, type: type)
    }
    
    public static func fetchThumbnail(forID assetID: String, size: CGSize?, andThen: @escaping (_: UIImage?, _: Date?) -> ()) -> PHImageRequestID? {

        let options = PHFetchOptions()
        let request = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: options)
        
        guard let asset = request.firstObject else {
            DispatchQueue.main.async {
                andThen(nil, nil)
            }
            return nil
        }
        
        let size = size ?? CGSize(width: 100, height: 100)
        
        let fetchOptions = PHImageRequestOptions()
        fetchOptions.isNetworkAccessAllowed = true
        fetchOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic
        fetchOptions.isSynchronous = false
        
        let imageRequest = PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: fetchOptions) { (maybeImage, info) in
            DispatchQueue.main.async {
                andThen(maybeImage, asset.creationDate)
            }
        }
        
        return imageRequest
    }
    
    public static func syncFetchOriginalData(forID assetID: String) -> DataFetchResult {
        let options = PHFetchOptions()
        let request = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: options)
        
        guard let asset = request.firstObject else {
            return DataFetchResult(error: "Initial fetch failed")
        }
        
        switch asset.mediaType {
        case .image:
            return AssetFetcher.syncFetchImageData(forAsset: asset)
        case .video:
            return AssetFetcher.syncFetchVideoData(forAsset: asset)
        default:
            return DataFetchResult(error: "Unknown media type")
        }
    }
    
    static func syncFetchImageData(forAsset asset: PHAsset) -> DataFetchResult {
        var result = DataFetchResult()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        //        options.progressHandler = {  (progress, error, stop, info) in
        //            print("progress: \(progress)")
        //            print(error)
        //        }
        
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        
        let compress = true
        
        if compress {
            PHImageManager.default().requestImage(for: asset, targetSize: maxSize, contentMode: .aspectFit, options: options) { (maybeImage, info) in
                if let d = info?[PHImageResultIsDegradedKey] as? NSNumber, d != 0 {
                    return
                }
                
                if let image = maybeImage {
                    result.data = image.jpegData(compressionQuality: 0.5)
                }
                
                result.error = result.isEmpty ? "Fetch failed" : nil
                
                waitGroup.leave()
            }
        } else {
            PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (data, str, orientation, info) in
                
                result.data = data
                result.error = result.isEmpty ? "Fetch failed" : nil
                
                waitGroup.leave()
            })
        }
        
        waitGroup.wait()
        return result
    }
    
    static func syncFetchVideoData(forAsset asset: PHAsset) -> DataFetchResult {
        var result = DataFetchResult()
        
        let options = PHVideoRequestOptions()
        options.deliveryMode = PHVideoRequestOptionsDeliveryMode.highQualityFormat
        options.isNetworkAccessAllowed = true
        
        let waitGroup = DispatchGroup()
        waitGroup.enter()
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (avAsset, mix, info) in
            
            guard let urlAsset = avAsset as? AVURLAsset else {
                result.error = "No AVAsset"
                waitGroup.leave()
                return
            }
            
            result.data = try? Data(contentsOf: urlAsset.url)
            
            result.error = result.isEmpty ? "Fetch failed" : nil
            
            waitGroup.leave()
        })
        
        waitGroup.wait()
        
        return result
    }
    
    public static func image(forAssetID assetID: AssetID, andThen: @escaping (UIImage?) -> ()) {
        let options = PHFetchOptions()
        let request = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: options)
        
        guard let asset = request.firstObject else {
            DispatchQueue.main.async {
                andThen(nil)
            }
            return
        }
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isSynchronous = false
        requestOptions.isNetworkAccessAllowed = true
        
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        PHImageManager.default().requestImage(for: asset, targetSize: maxSize, contentMode: .aspectFit, options: requestOptions) { (maybeImage, info) in
            if let d = info?[PHImageResultIsDegradedKey] as? NSNumber, d != 0 {
                return
            }
            andThen(maybeImage)
        }
    }
}
