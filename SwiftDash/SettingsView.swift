import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Fetch or create single settings object
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor<ServiceCategory>(\.name, order: .forward)]) private var categories: [ServiceCategory]
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var categoryToEdit: ServiceCategory?
    @State private var editCategoryName = ""

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
            Section("Manage Categories") {
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Custom Categories",
                        systemImage: "tag.slash",
                        description: Text("Tap the + to add your first category.")
                    )
                } else {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            Button {
                                categoryToEdit = category
                                editCategoryName = category.name
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Rename category")
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteCategory(category)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newCategoryName = ""
                    showingAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                Form {
                    Section("New Category") {
                        TextField("Name", text: $newCategoryName)
                    }
                }
                .navigationTitle("Add Category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddCategory = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addCategory() }
                            .disabled(!canAddCategory)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $categoryToEdit) { cat in
            NavigationStack {
                Form {
                    Section("Rename Category") {
                        TextField("Name", text: $editCategoryName)
                    }
                }
                .navigationTitle("Rename Category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { categoryToEdit = nil } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { renameCategory(cat) }
                            .disabled(!canSaveRenamedCategory)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Category helpers

    private var canAddCategory: Bool {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return !categories.contains { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
    }

    private var canSaveRenamedCategory: Bool {
        let name = editCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        if let current = categoryToEdit, current.name.compare(name, options: .caseInsensitive) == .orderedSame { return false }
        return !categories.contains { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let cat = ServiceCategory(name: name)
        modelContext.insert(cat)
        showingAddCategory = false
    }

    private func renameCategory(_ category: ServiceCategory) {
        let name = editCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        category.name = name
        categoryToEdit = nil
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets { deleteCategory(categories[index]) }
    }

    private func deleteCategory(_ category: ServiceCategory) {
        // If services still reference this category, set them to nil/Uncategorized
        let name = category.name
        let descriptor = FetchDescriptor<Service>(predicate: #Predicate<Service> { $0.category == name })
        if let used = try? modelContext.fetch(descriptor), !used.isEmpty {
            for svc in used { svc.category = nil }
        }
        modelContext.delete(category)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [AppSettings.self, ServiceCategory.self, Service.self], inMemory: true)
    }
}

