//
//  ContentView.swift
//  SwiftDash
//
//  Created by Harry Lewandowski on 27/9/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    // Fetch or create single settings object
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor<Service>(\Service.createdAt, order: .reverse)]) private var services: [Service]

    @State private var showingAddService = false
    @State private var newServiceName = ""
    @State private var newServicePort = ""
    @State private var newServiceHost = ""
    @State private var newServiceUseHTTPS: Bool = false
    @State private var newServiceSymbol = "globe"
    @State private var newServiceCategory = ""
    @State private var showingSettings = false
    @State private var showingEditService = false
    @State private var editServiceName = ""
    @State private var editServicePort = ""
    @State private var editServiceHost = ""
    @State private var editServiceUseHTTPS: Bool = false
    @State private var editServiceSymbol = "globe"
    @State private var editServiceCategory = ""
    @State private var serviceToEdit: Service?

    private var settings: AppSettings {
        if let existing = settingsList.first { return existing }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }

    private var groupedServices: [(category: String, services: [Service])] {
        let groups = Dictionary(grouping: services) { service in
            let raw = service.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? "Uncategorized" : raw
        }
        let sortedKeys = groups.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return sortedKeys.map { key in
            let sortedServices = (groups[key] ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return (category: key, services: sortedServices)
        }
    }

    private let defaultCategories: [String] = [
        "Entertainment",
        "Financial",
        "Creative",
        "AI",
        "Productivity",
        "Developer",
        "Utilities",
        "Security",
        "Monitoring",
        "Networking",
        "Storage",
        "Home",
        "Education",
    ]

    private var existingCategories: [String] {
        let serviceCategories = services
            .compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let all = Set(serviceCategories).union(Set(defaultCategories))
        return Array(all).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if services.isEmpty {
                    Section("Services") {
                        ContentUnavailableView(
                            "No Services",
                            systemImage: "square.stack.3d.up.slash",
                            description: Text("Tap + to create your first service, or open Settings to create your categories.")
                        )
                    }
                } else {
                    ForEach(groupedServices, id: \.category) { group in
                        Section(group.category) {
                            ForEach(group.services) { service in
                                Button {
                                    open(service)
                                } label: {
                                    HStack {
                                        Image(systemName: service.symbolName?.isEmpty == false ? service.symbolName! : "globe")
                                            .foregroundStyle(.tint)
                                        VStack(alignment: .leading) {
                                            Text(service.name)
                                                .font(.headline)
                                            Text(urlString(for: service))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button { beginEdit(service) } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button { open(service) } label: {
                                        Label("Open", systemImage: "safari")
                                    }
                                    Button(role: .destructive) { delete(service) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { delete(service) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button { beginEdit(service) } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .onDelete { offsets in
                                let items = group.services
                                for index in offsets { delete(items[index]) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("SwiftDash")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddService = true
                        newServiceName = ""
                        newServicePort = ""
                        newServiceHost = ""
                        newServiceUseHTTPS = settings.useHTTPS
                        newServiceSymbol = "globe"
                        newServiceCategory = ""
                    } label: {
                        Label("Add Service", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack(spacing: 16) {
                Image(systemName: "globe") // Default icon remains globe when no selection
                    .font(.system(size: 56, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                Text("Select or add a service")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showingAddService) {
            NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Service name", text: $newServiceName)
                        Picker("Category", selection: $newServiceCategory) {
                            Text("Uncategorized").tag("")
                            ForEach(existingCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        TextField("Host/IP (optional)", text: $newServiceHost)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        Toggle("Use HTTPS (override)", isOn: $newServiceUseHTTPS)
                        NavigationLink {
                            SymbolPickerView(selectedSymbol: $newServiceSymbol)
                        } label: {
                            HStack {
                                Text("Icon")
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: newServiceSymbol.isEmpty ? "globe" : newServiceSymbol)
                                        .foregroundStyle(.tint)
                                    Text(newServiceSymbol.isEmpty ? "globe" : newServiceSymbol)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        TextField("Port", text: $newServicePort)
                            .keyboardType(.numberPad)
                    }
                    Section("Preview") {
                        Text(previewURLString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .navigationTitle("New Service")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddService = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addService() }
                            .disabled(!canAddService)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack { SettingsView() }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingEditService) {
            NavigationStack {
                Form {
                    Section("Details") {
                        TextField("Service name", text: $editServiceName)
                        Picker("Category", selection: $editServiceCategory) {
                            Text("Uncategorized").tag("")
                            ForEach(existingCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        TextField("Host/IP (optional)", text: $editServiceHost)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        Toggle("Use HTTPS (override)", isOn: $editServiceUseHTTPS)
                        NavigationLink {
                            SymbolPickerView(selectedSymbol: $editServiceSymbol)
                        } label: {
                            HStack {
                                Text("Icon")
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: editServiceSymbol.isEmpty ? "globe" : editServiceSymbol)
                                        .foregroundStyle(.tint)
                                    Text(editServiceSymbol.isEmpty ? "globe" : editServiceSymbol)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        TextField("Port", text: $editServicePort)
                            .keyboardType(.numberPad)
                    }
                    Section("Preview") {
                        Text(editPreviewURLString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .navigationTitle("Edit Service")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEditService = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveEditedService() }
                            .disabled(!canSaveEditedService)
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Actions

    private func addService() {
        guard let port = Int(newServicePort.trimmingCharacters(in: .whitespaces)), port > 0 && port < 65536 else { return }
        withAnimation {
            let service = Service(name: newServiceName.isEmpty ? "Service :\(port)" : newServiceName, port: port)
            // Persist per-service overrides if provided
            let trimmedHost = newServiceHost.trimmingCharacters(in: .whitespacesAndNewlines)
            service.customHost = trimmedHost.isEmpty ? nil : trimmedHost
            service.customUseHTTPS = newServiceUseHTTPS
            service.symbolName = newServiceSymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newServiceSymbol
            let trimmedCategory = newServiceCategory.trimmingCharacters(in: .whitespacesAndNewlines)
            service.category = trimmedCategory.isEmpty ? nil : trimmedCategory
            modelContext.insert(service)
            showingAddService = false
        }
    }

    private func delete(at offsets: IndexSet) {
        withAnimation {
            for index in offsets { modelContext.delete(services[index]) }
        }
    }

    private func delete(_ service: Service) { withAnimation { modelContext.delete(service) } }

    private func beginEdit(_ service: Service) {
        serviceToEdit = service
        editServiceName = service.name
        editServicePort = String(service.port)
        editServiceHost = service.customHost ?? ""
        editServiceUseHTTPS = service.customUseHTTPS ?? settings.useHTTPS
        editServiceSymbol = service.symbolName ?? "globe"
        editServiceCategory = service.category ?? ""
        showingEditService = true
    }

    private func open(_ service: Service) {
        guard let url = URL(string: urlString(for: service)) else { return }
        openURL(url)
    }

    private func saveEditedService() {
        guard let service = serviceToEdit else { return }
        guard let port = Int(editServicePort.trimmingCharacters(in: .whitespaces)), port > 0 && port < 65536 else { return }
        withAnimation {
            service.name = editServiceName.isEmpty ? "Service :\(port)" : editServiceName
            service.port = port
            service.customHost = editServiceHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editServiceHost
            service.customUseHTTPS = editServiceUseHTTPS
            let trimmedSymbol = editServiceSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
            service.symbolName = trimmedSymbol.isEmpty ? nil : trimmedSymbol
            let trimmedCategory = editServiceCategory.trimmingCharacters(in: .whitespacesAndNewlines)
            service.category = trimmedCategory.isEmpty ? nil : trimmedCategory
            showingEditService = false
            serviceToEdit = nil
        }
    }

    // MARK: - URL helpers

    private func scheme(for service: Service? = nil) -> String {
        let https = service?.customUseHTTPS ?? settings.useHTTPS
        return https ? "https" : "http"
    }

    private func urlString(for service: Service) -> String {
        let host = (service.customHost?.isEmpty == false) ? service.customHost! : settings.host
        return "\(scheme(for: service))://\(host):\(service.port)"
    }

    private var previewURLString: String {
        let port = Int(newServicePort) ?? 0
        let name = newServiceName.isEmpty ? "Service :\(port)" : newServiceName
        let host = newServiceHost.isEmpty ? settings.host : newServiceHost
        let base = "\(newServiceUseHTTPS ? "https" : "http")://\(host)"
        return port > 0 ? "\(name) — \(base):\(port)" : "\(name) — \(base)"
    }

    private var editPreviewURLString: String {
        let port = Int(editServicePort) ?? 0
        let name = editServiceName.isEmpty ? "Service :\(port)" : editServiceName
        let host = editServiceHost.isEmpty ? settings.host : editServiceHost
        let base = "\(editServiceUseHTTPS ? "https" : "http")://\(host)"
        return port > 0 ? "\(name) — \(base):\(port)" : "\(name) — \(base)"
    }

    private var canAddService: Bool {
        let hasPort = Int(newServicePort) != nil
        let customHost = newServiceHost.trimmingCharacters(in: .whitespaces)
        let defaultHost = settings.host.trimmingCharacters(in: .whitespaces)
        return hasPort && (!customHost.isEmpty || !defaultHost.isEmpty)
    }

    private var canSaveEditedService: Bool {
        Int(editServicePort) != nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Service.self, AppSettings.self], inMemory: true)
}
