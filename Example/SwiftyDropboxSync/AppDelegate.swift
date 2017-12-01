//
//  AppDelegate.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/29/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import UIKit
import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let dropboxAppKey = "fxaicvo4dyfuzkj"

    var window: UIWindow?

    var sync: SyncManager<AssetSyncItem>?
    
    var assetIDs: [String] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        DropboxUtil.setupClient(withKey: self.dropboxAppKey)
        
        self.setupSync()
        
        return true
    }
    
    func setupSync() {
        if let client = DropboxClientsManager.authorizedClient {
            sync = SyncManager<AssetSyncItem>(client: client)
        }
        
        if let mainVC = (self.window?.rootViewController as? ViewController) {
            sync?.basePath = mainVC.defaultBasePath ?? ""
            
            mainVC.sync = sync
            
            sync?.collection = {
                return AssetSyncItem.items(forAssetIDs: mainVC.assetBackend.selectedAssetIDs)
            }
            
            sync?.beginSyncing()
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        DropboxUtil.handleAuthURL(url)
        
        return true
    }

}
