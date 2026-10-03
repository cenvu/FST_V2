
//
//  FishSockTransferApp.swift
//  FishSockTransfer
//
//  Created by Cen Vũ on 15/6/26.
//

import SwiftUI

@main
struct FishSockTransferApp: App {
    @StateObject private var languagePreference = AppLanguagePreference()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languagePreference)
                .environment(\.locale, languagePreference.language.locale)
        }

        Settings {
            SettingsView(languagePreference: languagePreference)
                .environment(\.locale, languagePreference.language.locale)
        }
    }
}
