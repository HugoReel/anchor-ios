import SwiftUI
import UIKit
import AnchorCore
import AnchorDesign

/// The settings surface: appearance, feedback, wins, low-demand and your
/// data. All decisions live in `SettingsViewModel`; this view renders them and
/// forwards edits back through the model.
public struct SettingsRootView: View {
    @Environment(\.anchorTheme) private var theme
    @State private var viewModel: SettingsViewModel
    @State private var shareItem: ShareItem?
    @State private var isExporting = false

    @MainActor
    public init(
        preferences: any PreferencesRepository,
        exporter: DataExporter,
        wiper: any DataWiping,
        dateProvider: any DateProviding,
        onPreferencesChanged: (@MainActor () -> Void)? = nil
    ) {
        let model = SettingsViewModel(
            preferences: preferences,
            exporter: exporter,
            wiper: wiper,
            dateProvider: dateProvider
        )
        model.onPreferencesChanged = onPreferencesChanged
        _viewModel = State(initialValue: model)
    }

    public var body: some View {
        Form {
            appearanceSection
            feedbackSection
            winsSection
            lowDemandSection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .task { await viewModel.load() }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert("Delete everything?", isPresented: deleteAlertBinding) {
            Button("Cancel", role: .cancel) { viewModel.cancelDelete() }
            Button("Delete everything", role: .destructive) {
                Task { await viewModel.confirmDelete() }
            }
        } message: {
            Text("This removes all your days, goals, reflections and settings from this device. It cannot be undone.")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: themeBinding) {
                ForEach(ThemeChoice.allCases, id: \.self) { choice in
                    Text(title(for: choice)).tag(choice)
                }
            }
            Picker("Motion", selection: motionBinding) {
                ForEach(MotionLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            Text("Dynamic Type is supported. Text follows your system text size.")
                .anchorFont(.caption)
                .foregroundStyle(theme.textSecondary.color)
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: toggleBinding(\.hapticsEnabled) { await viewModel.setHaptics($0) })
            Toggle("Sound", isOn: toggleBinding(\.soundEnabled) { await viewModel.setSound($0) })
        }
    }

    // MARK: - Wins

    private var winsSection: some View {
        Section("Gentle wins") {
            Toggle("Show wins", isOn: toggleBinding(\.showWins) { await viewModel.setShowWins($0) })
            Toggle("Pause wins", isOn: toggleBinding(\.winsPaused) { await viewModel.setWinsPaused($0) })
            Text("Pausing keeps your counts. They are never reset.")
                .anchorFont(.caption)
                .foregroundStyle(theme.textSecondary.color)
        }
    }

    // MARK: - Low-demand

    private var lowDemandSection: some View {
        Section("Low-demand mode") {
            Toggle("Low-demand mode", isOn: toggleBinding(\.lowDemandMode) { await viewModel.setLowDemand($0) })
            Text("Hides times, timers and reminders. Everything stays; only what is shown changes.")
                .anchorFont(.caption)
                .foregroundStyle(theme.textSecondary.color)
        }
    }

    // MARK: - Your data

    private var dataSection: some View {
        Section("Your data") {
            Button {
                Task { await exportTapped() }
            } label: {
                if isExporting {
                    ProgressView()
                } else {
                    Text("Export a copy")
                }
            }
            .disabled(isExporting)
            Button(role: .destructive) {
                viewModel.armDelete()
            } label: {
                Text("Delete all my data")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            NavigationLink("Licences") {
                LicencesView()
            }
        }
    }

    // MARK: - Actions and bindings

    private func exportTapped() async {
        isExporting = true
        defer { isExporting = false }
        guard let data = await viewModel.exportData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("anchor-export.json")
        do {
            try data.write(to: url, options: .atomic)
            shareItem = ShareItem(url: url)
        } catch {
            // Sharing is best-effort; a write failure simply shows nothing.
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(get: { viewModel.deleteArmed }, set: { armed in if !armed { viewModel.cancelDelete() } })
    }

    private var themeBinding: Binding<ThemeChoice> {
        Binding(get: { viewModel.theme }, set: { newValue in Task { await viewModel.update(theme: newValue) } })
    }

    private var motionBinding: Binding<MotionLevel> {
        Binding(get: { viewModel.motion }, set: { newValue in Task { await viewModel.update(motion: newValue) } })
    }

    private func toggleBinding(
        _ keyPath: KeyPath<SettingsViewModel, Bool>,
        set: @escaping (Bool) async -> Void
    ) -> Binding<Bool> {
        Binding(get: { viewModel[keyPath: keyPath] }, set: { newValue in Task { await set(newValue) } })
    }

    private func title(for choice: ThemeChoice) -> String {
        switch choice {
        case .calm: "Calm"
        case .cool: "Cool"
        case .warm: "Warm"
        case .lowLight: "Low light"
        }
    }
}

/// Identifiable wrapper so the export URL can drive a `.sheet(item:)`.
private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Presents the system share sheet for the exported document.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
