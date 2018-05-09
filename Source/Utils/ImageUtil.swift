//
//  ImageUtil.swift
//  SwiftySync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import Photos

public typealias AssetID = String

class ImageUtil {
    
    static var originalsAlbumName = "Fobo Originals"
    static var defaultAlbumName = "Fobo"
    static var videosAlbumName = "Fobo Videos"
    static var printsAlbumName = "Fobo Prints"
    static var slideshowAlbumName = "Fobo Slideshow"
    static var assetsAlbumName = "Fobo Assets"
    
    static func saveFileToCameraRoll(fromPath: String) {
        var albumName = ImageUtil.defaultAlbumName
        var isVideo: Bool = false
        
        if fromPath.localizedStandardContains("mp4") {
            albumName = ImageUtil.videosAlbumName
            isVideo = true
        }
        
        let fromURL = URL(fileURLWithPath: fromPath)
        
        guard let album = ImageUtil.findOrCreateFoboAlbum(named: albumName) else {
            assert(false, "Could not find or create album")
            return;
        }
        
        DispatchQueue.global(qos: .utility).async {
            PHPhotoLibrary.shared().performChanges({
                var assetReq: PHAssetChangeRequest?
                
                if isVideo {
                    assetReq = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fromURL)
                } else {
                    assetReq = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fromURL)
                }
                
                if let asset = assetReq?.placeholderForCreatedAsset {
                    let request = PHAssetCollectionChangeRequest(for: album)
                    request?.addAssets([asset] as NSArray)
                }
                
                
            }) { (done, err) in
                if err != nil {
                    print("Error creating video file in library")
                    print(err.debugDescription)
                } else {
                    print("Done writing asset to the user's photo library")
                }
            }
        }
    }
    
    static func save(_ image: UIImage, toAlbumNamed albumName: String, andThen: @escaping (AssetID?) -> ()) {
        DispatchQueue.global().async {
            if let album = ImageUtil.findOrCreateFoboAlbum(named: albumName) {
                var localIdentifier: String? = nil
                PHPhotoLibrary.shared().performChanges({
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let asset = assetChangeRequest.placeholderForCreatedAsset
                    localIdentifier = asset?.localIdentifier
                    let request = PHAssetCollectionChangeRequest(for: album)
                    request?.addAssets([asset!] as NSArray)
                }, completionHandler: { (success, error) in
                    if success {
                        andThen(localIdentifier)
                    }
                })
            }
        }
    }
    
    static func saveVideo(atURL url: URL, toAlbumNamed albumName: String, andThen: @escaping (String?) -> ()) {
        guard FileUtil.fileExists(url.path) else {
            assert(false, "Trying to save a video file to the camera roll but it ain't existin")
            return
        }
        
        if let album = ImageUtil.findOrCreateFoboAlbum(named: albumName) {
            var localIdentifier: String? = nil
            PHPhotoLibrary.shared().performChanges({
                if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) {
                    let asset = assetChangeRequest.placeholderForCreatedAsset
                    localIdentifier = asset?.localIdentifier
                    let request = PHAssetCollectionChangeRequest(for: album)
                    request?.addAssets([asset!] as NSArray)
                } else {
                    print("Creation request for video failed")
                }
            }, completionHandler: { (success, error) in
                if success {
                    andThen(localIdentifier)
                } else {
                    print(error?.localizedDescription ?? "None")
                }
            })
        }
    }
    
    static func findOrCreateFoboAlbum(named albumName: String) -> PHAssetCollection? {
        if let album = ImageUtil.findFoboAlbum(named: albumName) {
            return album
        } else {
            do {
                try PHPhotoLibrary.shared().performChangesAndWait({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                })
            } catch {
                print("Problem finding/creating album: ".appending(albumName))
                print(error)
            }
            
            return ImageUtil.findFoboAlbum(named: albumName)
        }
    }
    
    static func findFoboAlbum(named albumName: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", albumName)
        let findFoboAlbumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        return findFoboAlbumResult.firstObject
    }
    
    static func clearCameraRoll() {
        let options = PHFetchOptions()
        
        let fetch: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: options)
        
        var assets: [PHAsset] = []
        
        fetch.enumerateObjects({ (asset, index, test) in
            assets.append(asset)
        })
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }) { (result, error) in
            // done
        }
    }
    
    static func assetExists(_ assetID: AssetID) -> Bool {
        let options = PHFetchOptions()
        let request = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: options)
        return request.count > 0
    }
    
    static func images(forAssetIDs assetIDs: [AssetID], andThen: @escaping ([AssetID: UIImage]) -> ()) {
        let imageRequests = DispatchGroup()
        
        let options = PHFetchOptions()
        
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: options)
        
        var results: [AssetID: UIImage] = [:]
        
        fetch.enumerateObjects({ (asset, index, test) in
            imageRequests.enter()
            
            let options = PHImageRequestOptions()
            
            PHCachingImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (maybeData, _, orientation, _) in
                if let data = maybeData, let image = UIImage(data: data) {
                    results[asset.localIdentifier] = image
                }
                
                imageRequests.leave()
            })
        })
        
        var sortedResults: [AssetID: UIImage] = [:]
        imageRequests.notify(queue: DispatchQueue.main, execute: {
            // The PHAsset fetch gives results in random order
            // So we sort them here back to the order which was requested
            
            for eachAssetID in assetIDs {
                if let image = results[eachAssetID] {
                    sortedResults[eachAssetID] = image
                }
            }
            
            andThen(sortedResults)
        })
    }
}



