import DueMateCore
import SwiftUI

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @State private var newCategoryName = ""

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: appearance) {
                        Text("System").tag(AppearanceMode.system)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                }
                Section("Notifications") {
                    Toggle("Enable notifications", isOn: notifications)
                    Picker("Default reminder", selection: reminder) {
                        Text("On due date").tag(0)
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("7 days before").tag(7)
                    }
                    Button("Request permission") {
                        Task {
                            let allowed = await NotificationScheduler.shared.requestPermission()
                            var settings = session.snapshot.settings
                            settings.notificationsEnabled = allowed
                            try? await session.store.updateSettings(settings)
                            await session.refresh()
                        }
                    }
                }
                Section("Currency") {
                    LabeledContent("Currency", value: session.snapshot.settings.currencyCode)
                }
                Section("Week start") {
                    Picker("Week start", selection: weekStart) {
                        Text("Device default").tag(WeekStart.deviceDefault)
                        Text("Monday").tag(WeekStart.monday)
                        Text("Sunday").tag(WeekStart.sunday)
                    }
                }
                Section("Widgets") {
                    Toggle("Hide amounts on widgets", isOn: hideAmounts)
                }
                Section("Data") {
                    LabeledContent("Sync", value: syncLabel)
                    Button("Sync now") {
                        Task { await session.refreshSync() }
                    }
                }
                Section("Categories") {
                    ForEach(session.snapshot.categories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                        Label(category.name, systemImage: category.icon)
                            .foregroundStyle(AppColors.token(category.colorToken))
                    }
                    HStack {
                        TextField("Custom category", text: $newCategoryName)
                        Button("Add") {
                            Task { await addCategory() }
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("DueMate stores obligations, occurrences, and payments on this device. Cloud APIs are isolated behind a protocol and default to a mock client.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appearance: Binding<AppearanceMode> {
        binding(\.appearance)
    }

    private var notifications: Binding<Bool> {
        binding(\.notificationsEnabled)
    }

    private var weekStart: Binding<WeekStart> {
        binding(\.weekStart)
    }

    private var hideAmounts: Binding<Bool> {
        binding(\.widgetHideAmounts)
    }

    private var reminder: Binding<Int> {
        Binding(
            get: { session.snapshot.settings.defaultReminderDaysBefore.first ?? 1 },
            set: { value in
                var settings = session.snapshot.settings
                settings.defaultReminderDaysBefore = [value]
                Task { try? await session.store.updateSettings(settings); await session.refresh() }
            }
        )
    }

    private var syncLabel: String {
        switch session.syncStatus {
        case .synced: "Synced"
        case .syncing: "Syncing…"
        case .offline: "Offline"
        case .failed: "Sync failed"
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { session.snapshot.settings[keyPath: keyPath] },
            set: { value in
                var settings = session.snapshot.settings
                settings[keyPath: keyPath] = value
                Task { try? await session.store.updateSettings(settings); await session.refresh() }
            }
        )
    }

    private func addCategory() async {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let category = ObligationCategory(
            name: name,
            icon: "star.fill",
            colorToken: "blue",
            sortOrder: session.snapshot.categories.count
        )
        try? await session.store.addCategory(category)
        newCategoryName = ""
        await session.refresh()
    }
}

struct OnboardingView: View {
    @Environment(AppSession.self) private var session
    @State private var page = 0

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            TabView(selection: $page) {
                onboardingPage("Welcome to DueMate", "calendar.badge.checkmark", "Track bills, EMIs, and recurring payments without duplicating calendar reminders.", 0)
                onboardingPage("What DueMate does", "checkmark.circle", "Each obligation generates occurrences. Mark paid, keep history, and see what is still due.", 1)
                onboardingPage("Reminders", "bell", "DueMate can notify you before due dates. You can skip this and enable it later in Settings.", 2)
            }
            #if os(iOS)
            .tabViewStyle(.page)
            #endif
            HStack {
                Button("Skip") {
                    Task { await session.completeOnboarding() }
                }
                Spacer()
                if page < 2 {
                    Button("Next") { page += 1 }
                } else {
                    Button("Get started") {
                        Task {
                            _ = await NotificationScheduler.shared.requestPermission()
                            session.showAddSheet = true
                            await session.completeOnboarding()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(AppSpacing.large)
        }
    }

    private func onboardingPage(_ title: String, _ image: String, _ message: String, _ tag: Int) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: image)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(title)
                .font(.title.weight(.semibold))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.large)
        }
        .tag(tag)
    }
}
