//
//  ProfileView+MainMenu.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/6/22.
//  Copyright (c) 2022 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import PassepartoutCore

extension ProfileView {
    struct MainMenu: View {
        enum ActionSheetType: Int, Identifiable {
            case uninstallVPN
            
            case deleteProfile
            
            var id: Int {
                rawValue
            }
        }
        
        @ObservedObject private var profileManager: ProfileManager
        
        @ObservedObject private var vpnManager: VPNManager
        
        @ObservedObject private var currentProfile: ObservableProfile
        
        private var header: Profile.Header {
            currentProfile.value.header
        }
        
        @Binding private var modalType: ModalType?
        
        @State private var actionSheetType: ActionSheetType?
        
        private let uninstallVPNTitle = L10n.Global.Strings.uninstall
        
        private let deleteProfileTitle = L10n.Global.Strings.delete
        
        private let cancelTitle = L10n.Global.Strings.cancel
        
        init(currentProfile: ObservableProfile, modalType: Binding<ModalType?>) {
            profileManager = .shared
            vpnManager = .shared
            self.currentProfile = currentProfile
            _modalType = modalType
        }

        var body: some View {
            Menu {
                ShortcutsButton(
                    modalType: $modalType
                )
                Divider()
                RenameButton(
                    modalType: $modalType
                )
                // should contextually set duplicate as current profile
//                DuplicateButton(
//                    header: currentProfile.value.header
//                )
                uninstallVPNButton
                Divider()
                deleteProfileButton
            } label: {
                themeSettingsMenuImage.asSystemImage
            }.actionSheet(item: $actionSheetType) {
                switch $0 {
                case .uninstallVPN:
                    return ActionSheet(
                        title: Text(L10n.Profile.Alerts.UninstallVpn.message),
                        message: nil,
                        buttons: [
                            .destructive(Text(uninstallVPNTitle), action: uninstallVPN),
                            .cancel(Text(cancelTitle))
                        ]
                    )
                    
                case .deleteProfile:
                    return ActionSheet(
                        title: Text(L10n.Organizer.Alerts.RemoveProfile.message(header.name)),
                        message: nil,
                        buttons: [
                            .destructive(Text(deleteProfileTitle), action: removeProfile),
                            .cancel(Text(cancelTitle))
                        ]
                    )
                }
            }
        }
        
        private var uninstallVPNButton: some View {
            Button {
                actionSheetType = .uninstallVPN
            } label: {
                Label(uninstallVPNTitle, systemImage: themeUninstallImage)
            }
        }
        
        private var deleteProfileButton: some View {
            DestructiveButton {
                actionSheetType = .deleteProfile
            } label: {
                Label(deleteProfileTitle, systemImage: themeDeleteImage)
            }
        }

        private func uninstallVPN() {
            Task {
                await vpnManager.uninstall()
            }
        }

        private func removeProfile() {
            profileManager.removeProfiles(withIds: [header.id])
        }
    }
    
    struct ShortcutsButton: View {
        @ObservedObject private var productManager: ProductManager
        
        @Binding private var modalType: ModalType?
        
        init(modalType: Binding<ModalType?>) {
            productManager = .shared
            _modalType = modalType
        }

        private var isEligibleForSiri: Bool {
            productManager.isEligible(forFeature: .siriShortcuts)
        }
        
        var body: some View {
            Button {
                presentShortcutsOrPaywall()
            } label: {
                Label(Unlocalized.Other.siri, systemImage: themeShortcutsImage)
            }
        }

        private func presentShortcutsOrPaywall() {

            // eligibility: enter Siri shortcuts or present paywall
            if isEligibleForSiri {
                modalType = .shortcuts
            } else {
                modalType = .paywallShortcuts
            }
        }
    }
    
    struct RenameButton: View {
        @Binding private var modalType: ModalType?
        
        init(modalType: Binding<ModalType?>) {
            _modalType = modalType
        }
        
        var body: some View {
            Button {
                modalType = .rename
            } label: {
                Label(L10n.Global.Strings.rename, systemImage: themeRenameProfileImage)
            }
        }
    }

    struct DuplicateButton: View {
        @ObservedObject private var profileManager: ProfileManager
        
        let header: Profile.Header
        
        init(header: Profile.Header) {
            profileManager = .shared
            self.header = header
        }
        
        var body: some View {
            Button {
                duplicateProfile(withId: header.id)
            } label: {
                Label(L10n.Global.Strings.duplicate, systemImage: themeDuplicateImage)
            }
        }

        private func duplicateProfile(withId id: UUID) {
            profileManager.duplicateProfile(withId: id)
        }
    }
}
