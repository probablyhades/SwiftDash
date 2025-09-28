import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct SymbolPickerView: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private let popularSymbols: [String] = [
        "globe", "bolt.fill", "server.rack", "cloud.fill", "lock.fill", "key.fill",
        "antenna.radiowaves.left.and.right", "network", "wifi", "wifi.router.fill",
        "laptopcomputer", "desktopcomputer", "display", "terminal.fill", "link",
        "cube.box.fill", "shippingbox.fill", "tray.full.fill",
        "circle.grid.2x2.fill", "square.grid.2x2.fill", "rectangle.stack.fill",
        "gearshape.fill", "wrench.and.screwdriver.fill", "hammer.fill",
        "paperplane.fill", "bookmark.fill", "doc.text.fill", "folder.fill",
        "shield.lefthalf.fill", "checkmark.seal.fill", "exclamationmark.triangle.fill",
        "power", "play.circle.fill", "pause.circle.fill", "stop.circle.fill",
        "bell.fill", "bell.badge.fill", "clock.fill"
    ]

    private var filteredPopular: [String] {
        guard !searchText.isEmpty else { return popularSymbols }
        return popularSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private var customSearchIsValid: Bool {
        let name = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        #if canImport(UIKit)
        return UIImage(systemName: name) != nil
        #elseif canImport(AppKit)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        return true
        #endif
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 88), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(filteredPopular, id: \.self) { symbol in
                    symbolCell(symbol)
                }

                if !searchText.isEmpty, customSearchIsValid, !popularSymbols.contains(searchText) {
                    Section {
                        symbolCell(searchText, isCustom: true)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Choose Icon")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search SF Symbols")
        .searchSuggestions {
            ForEach(filteredPopular.prefix(10), id: \.self) { suggestion in
                Text(suggestion).searchCompletion(suggestion)
            }
        }
    }

    @ViewBuilder
    private func symbolCell(_ name: String, isCustom: Bool = false) -> some View {
        Button {
            selectedSymbol = name
            dismiss()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: name)
                    .font(.system(size: 28, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(name))
    }
}

#Preview {
    NavigationStack {
        SymbolPickerView(selectedSymbol: .constant("globe"))
    }
}
