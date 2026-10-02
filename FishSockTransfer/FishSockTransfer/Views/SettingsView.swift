// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var languagePreference: AppLanguagePreference

    public init(languagePreference: AppLanguagePreference) {
        self.languagePreference = languagePreference
    }

    public var body: some View {
        Form {
            Section("General") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Language")
                        .font(.headline)

                    Picker("Application Language", selection: Binding(
                        get: { languagePreference.language },
                        set: { languagePreference.select($0) }
                    )) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(verbatim: language.endonym).tag(language)
                        }
                    }

                    Text("Changes apply immediately.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
