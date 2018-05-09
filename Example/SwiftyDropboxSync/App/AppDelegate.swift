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
        if let dropboxClient = DropboxClientsManager.authorizedClient {
            let syncClient = DropboxSyncClient(dropboxClient: dropboxClient)
            sync = SyncManager<AssetSyncItem>(client: syncClient)
        }
        
        if let mainVC = (self.window?.rootViewController as? ViewController) {
            mainVC.sync = sync
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        DropboxUtil.handleAuthURL(url)
        
        return true
    }

}
