import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Fetch or create single settings object
    @Query private var settingsList: [AppSettings]

    private var settings: AppSettings {
        if let existing = settingsList.first { return existing }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        Form {
            Section("Default Server Options") {
                HStack {
                    Text("Host/IP")
                    Spacer()
                    TextField("e.g. 192.168.1.2 or my.domain.com", text: Binding(
                        get: { settings.host },
                        set: { settings.host = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                }
                Toggle("Use HTTPS", isOn: Binding(
                    get: { settings.useHTTPS },
                    set: { settings.useHTTPS = $0 }
                ))
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [AppSettings.self], inMemory: true)
    }
}
