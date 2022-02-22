//
//  DefaultTheme.swift
//
//  Copyright (c) 2021 Secret, Inc. All rights reserved.
//  Copyright (c) 2018 Chris Ballinger. All rights reserved.
//
//  This is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This software is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this software. If not, see <http://www.gnu.org/licenses/>
//

import Foundation

@objc public class GlobalTheme: NSObject {
    @objc public static var shared: AppTheme = DefaultTheme()
}

@objc public class DefaultTheme: NSObject, AppTheme {
    
    public var labelColor: UIColor {
        if #available(iOS 13, *) {
            return .label
        }
        return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
    
    public var secondaryLabelColor: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }
        return UIColor(red: 60.0, green: 60.0, blue: 67.0, alpha: 0.6)
    }
    
    public func setupAppearance() {
        
    }
    
    private var connections: DatabaseConnections? {
        return OTRDatabaseManager.shared.connections
    }
    
    public func conversationViewController() -> UIViewController {
        return OTRConversationViewController()
    }
    
    public func messagesViewController() -> UIViewController {
        return OTRMessagesHoldTalkViewController()
    }
    
    public func settingsViewController() -> UIViewController {
        return OTRSettingsViewController()
    }
    
    public func composeViewController() -> UIViewController {
        return OTRComposeViewController()
    }
    
    public func inviteViewController(account: OTRAccount) -> UIViewController {
        return OTRInviteViewController(account: account)
    }
    
    public func accountDetailViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections,
            let xmpp = OTRProtocolManager.shared.xmppManager(for: account) else {
            return UIViewController()
        }
        
        let detail = AccountDetailViewController(account: account, xmpp: xmpp, longLivedReadConnection: connections.longLivedRead, readConnection: connections.ui, writeConnection: connections.write)
        return detail
    }
    
    public func keyManagementViewController(account: OTRXMPPAccount) -> UIViewController {
        guard let connections = self.connections else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(account, buddies: [], connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: account.uniqueId, connections: connections, form: form)
        return verify
    }
    
    public func keyManagementViewController(buddy: OTRXMPPBuddy) -> UIViewController {
        guard let connections = self.connections else {
            return UIViewController()
        }
        let account = connections.ui.fetch {
            buddy.account(with: $0) as? OTRXMPPAccount
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(account, buddies: [buddy], connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: buddy.accountUniqueId, connections: connections, form: form)
        return verify
    }
    
    public func groupKeyManagementViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        guard let connections = self.connections,
            let accountId = buddies.first?.accountUniqueId else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(nil, buddies: buddies, connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: accountId, connections: connections, form: form)
        return verify
    }
    
    public func newUntrustedKeyViewController(buddies: [OTRXMPPBuddy]) -> UIViewController {
        guard let connections = self.connections,
            let accountId = buddies.first?.accountUniqueId else {
            return UIViewController()
        }
        let form = KeyManagementViewController.profileFormDescriptorForAccount(nil, buddies: buddies, connection: connections.ui)
        let verify = KeyManagementViewController(accountKey: accountId, connections: connections, form: form)
        return verify
    }
}
