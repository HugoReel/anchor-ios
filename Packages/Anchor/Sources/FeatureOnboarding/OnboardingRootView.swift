import SwiftUI
import AnchorCore
import AnchorDesign

/// The gentle, fully skippable first run. Three questions, all optional; every
/// screen offers a way straight past. Calls `onComplete` once the model has
/// written `onboardingComplete`.
public struct OnboardingRootView: View {
    @Environment(\.anchorTheme) private var theme
    @Environment(\.anchorMotion) private var motion
    @State private var viewModel: OnboardingViewModel
    @State private var page = 0
    private let onComplete: () -> Void

    private let lastPage = 2

    @MainActor
    public init(
        preferences: any PreferencesRepository,
        dateProvider: any DateProviding,
        onComplete: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: OnboardingViewModel(preferences: preferences, dateProvider: dateProvider))
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Spacer()
                Button("Skip") { Task { await viewModel.skip() } }
                    .foregroundStyle(theme.textSecondary.color)
            }
            TabView(selection: $page) {
                themePage.tag(0)
                wakePage.tag(1)
                winsPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            primaryButton
        }
        .padding(Spacing.lg)
        .background(theme.background.color)
        .task { await viewModel.load() }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete { onComplete() }
        }
    }

    // MARK: - Pages

    private var themePage: some View {
        makePage(title: "How would you like it to look?", subtitle: "You can change this any time in settings.") {
            Picker("Theme", selection: themeBinding) {
                ForEach(ThemeChoice.allCases, id: \.self) { choice in
                    Text(title(for: choice)).tag(choice)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var wakePage: some View {
        makePage(title: "When is your day usually awake?", subtitle: "Only used to lay out a day. Nothing is enforced.") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Stepper("Wake around \(hourLabel(viewModel.wakeStartMinutes))",
                        value: startHourBinding, in: 0...23)
                Stepper("Wind down around \(hourLabel(viewModel.wakeEndMinutes))",
                        value: endHourBinding, in: 0...23)
            }
        }
    }

    private var winsPage: some View {
        makePage(title: "Show gentle wins?", subtitle: "Small additive counts that never reset. You can turn these off.") {
            Toggle("Show wins", isOn: winsBinding)
        }
    }

    // MARK: - Building blocks

    private func makePage(title: String, subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .anchorFont(.display)
                .foregroundStyle(theme.textPrimary.color)
            Text(subtitle)
                .anchorFont(.body)
                .foregroundStyle(theme.textSecondary.color)
            content()
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Spacing.lg)
    }

    private var primaryButton: some View {
        Button {
            if page < lastPage {
                withAnimation(AnchorMotion.animation(for: motion)) { page += 1 }
            } else {
                Task { await viewModel.complete() }
            }
        } label: {
            Text(page < lastPage ? "Next" : "Get started")
                .anchorFont(.title)
                .foregroundStyle(theme.accentText.color)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(theme.accent.color, in: RoundedRectangle(cornerRadius: Radius.control))
        }
    }

    // MARK: - Actions

    private var themeBinding: Binding<ThemeChoice> {
        Binding(get: { viewModel.theme }, set: { viewModel.theme = $0 })
    }

    private var winsBinding: Binding<Bool> {
        Binding(get: { viewModel.showWins }, set: { viewModel.showWins = $0 })
    }

    private var startHourBinding: Binding<Int> {
        Binding(get: { viewModel.wakeStartMinutes / 60 }, set: { viewModel.wakeStartMinutes = $0 * 60 })
    }

    private var endHourBinding: Binding<Int> {
        Binding(get: { viewModel.wakeEndMinutes / 60 }, set: { viewModel.wakeEndMinutes = $0 * 60 })
    }

    private func hourLabel(_ minutes: Int) -> String {
        let hour = minutes / 60
        return String(format: "%02d:00", hour)
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
