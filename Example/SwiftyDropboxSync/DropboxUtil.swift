//
//  DropboxUtil.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 11/29/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation
import SwiftyDropbox

class DropboxUtil {
    static let authorizationChangedNotificationName = Notification.Name("DropboxAuthorizationChangedNotificationName")
    
    static func setupClient(withKey key: String) {
        URLSessionConfiguration.default.httpMaximumConnectionsPerHost = 1
        let client = DropboxTransportClient(accessToken: "")
        client.manager.startRequestsImmediately = false
        DropboxClientsManager.setupWithAppKey(key, transportClient: client)
    }
    
    static var isLoggedIn: Bool {
        return DropboxClientsManager.authorizedClient != nil
    }
    
    static func logOut() {
        DropboxClientsManager.unlinkClients()
        NotificationCenter.default.post(name: DropboxUtil.authorizationChangedNotificationName, object: nil)
    }
    
    static func doAuth(from: UIViewController) {
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: from,
            openURL: { (url: URL) -> Void in
                UIApplication.shared.open(url, options: [:], completionHandler: { (done) in
                    // done
                })
        }
        )
    }
    
    static func handleAuthURL(_ url: URL) {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success(let accessToken):
                print(String(format: "Success! User is logged into Dropbox with token: %@", accessToken.accessToken))
                NotificationCenter.default.post(name: DropboxUtil.authorizationChangedNotificationName, object: nil)
                break
            case .cancel:
                print("Authorization flow was manually canceled by user!")
                break
            case .error(_, let description):
                print("Error: \(description)")
                break
            }
        }
    }
    
    static var loginEmail: String?
    
    static func getLoginInfo(_ andThen: @escaping (String) -> ()) {
        if let client = DropboxClientsManager.authorizedClient {
            client.users.getCurrentAccount().response(completionHandler: { (account, error) in
                andThen(String(format: "%@ (%@)",
                               account?.name.displayName ?? "Fobo",
                               account?.email ?? "info@fobo.co"))
            })
        }
    }
    
    static func getLoginEmail(_ andThen: @escaping (String) -> ()) {
        if let client = DropboxClientsManager.authorizedClient {
            client.users.getCurrentAccount().response(completionHandler: { (account, error) in
                andThen(account?.email ?? "fobo@fobo.co")
            })
        }
    }
}

