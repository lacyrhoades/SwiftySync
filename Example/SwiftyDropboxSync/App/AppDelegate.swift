//
//  AppDelegate.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/29/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import UIKit
import SwiftyDropbox
import TOSMBClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let dropboxAppKey = "fxaicvo4dyfuzkj"

    var window: UIWindow?

    var sync: SyncManager<AssetSyncItem>?
    
    var assetIDs: [String] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DropboxUtil.setupClient(withKey: self.dropboxAppKey)
        
        self.setupSync()
        
        return true
    }
    
    func setupSync() {
        enum SyncMethod {
            case dropbox
            case smbShare
        }
        
        let syncMethod: SyncMethod = .dropbox
        
        switch syncMethod {
        case .dropbox:
            if let dropboxClient = DropboxClientsManager.authorizedClient {
                let syncClient = DropboxSyncClient(dropboxClient: dropboxClient)
                sync = SyncManager<AssetSyncItem>(client: syncClient)
            }
        case .smbShare:
            let session = TOSMBSession(hostName: "fobo-24", ipAddress: "192.168.2.5")
            session!.setLoginCredentialsWithUserName("fobo24", password: "mvs384")
            let syncClient = SMBSyncClient(session: session!)
            sync = SyncManager<AssetSyncItem>(client: syncClient)
        }
        
        if let mainVC = (self.window?.rootViewController as? ViewController) {
            mainVC.sync = sync
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        DropboxUtil.handleAuthURL(url)
        
        return true
    }

}
