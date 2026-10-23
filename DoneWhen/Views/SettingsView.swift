import SwiftUI

struct SettingsView: View {
    @AppStorage(Anonymization.preferenceKey) private var anonymizeData = false

    var body: some View {
        Form {
            Section {
                Toggle("Anonymize data", isOn: Binding(
                    get: { anonymizeData && Anonymization.isAvailable },
                    set: { anonymizeData = $0 }
                ))
                .disabled(!Anonymization.isAvailable)
            } footer: {
                Text("Replace protected words in displayed event names. Saved data stays unchanged. Editing and creation screens show original names.")
            }

            if !Anonymization.isAvailable {
                Section {
                    Text("Anonymization is unavailable because its dictionary is empty, missing, or invalid.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
