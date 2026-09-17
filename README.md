# DueMate

Personal finance app for bills, EMIs, due dates, payments, and recurring obligations.

Each obligation is a persistent entity with a recurrence rule and dated occurrences. Marking something paid records a payment. It does not create another calendar event.

This README is for humans and AI coding agents. Read **Current repo state** before changing project files or assuming an Xcode/iOS target already exists.

---

## Current repo state

This repository is a **Swift Package**, not an Xcode iOS app project.

| What exists today | What does not exist yet |
| --- | --- |
| `Package.swift` | `DueMate.xcodeproj` / `.xcworkspace` |
| `DueMateCore` domain + offline JSON store | WidgetKit extension target |
| `DueMateUI` SwiftUI screens | App icons / asset catalog |
| `DueMateApp` executable | Signing, bundle ID, entitlements in-repo |
| `swift run DueMate` on **macOS** | Ready-to-submit App Store binary |

Local Mac development works with the Swift toolchain only. Putting the app on an iPhone or the App Store requires **Xcode** and an **Apple Developer** account. That is an Apple requirement, not a project dependency to install into this repo.

Suggested identifiers (use these unless the team has already registered different ones):

- Bundle ID: `com.pradeepjadhav.DueMate`
- Display name: `DueMate`
- URL scheme: `duemate`
- Deployment: iOS 18+, macOS 15+ (package platforms)

---

## Who this app is for

DueMate tracks recurring financial obligations: credit cards, EMIs, utilities, insurance, subscriptions, rent, tax.

It is **not** a bank aggregator, budget app, or net-worth tracker.

---

## Architecture (short)

```
Sources/
  DueMateCore/     domain models, recurrence, payments, EMI, dashboard math,
                   JSON snapshot store, API protocols
  DueMateUI/       SwiftUI: Home, Calendar, Tasks, Obligations, Settings
  DueMateApp/      @main entry — currently a macOS executable
```

- **Persistence:** `~/Library/Application Support/DueMate/snapshot.json` (macOS). Offline-first. Mutations are queued for sync.
- **API:** Isolated behind `APIClientProtocol`. Default client is `MockAPIClient`. `LiveAPIClient` is written for `https://www.pradeepjadhav.com/api/` but those routes are not assumed to exist.
- **Auth:** `AuthenticationService` / `MockAuthenticationService`. No tokens or secrets in source.
- **Dates:** Due dates are civil `CalendarDate` values (year-month-day), not UTC midnights.
- **Overdue:** Derived at display time from date + status. Not stored as a permanent status.
- **EMI counts:** Derived from paid occurrences (idempotent).

Do not add third-party Swift packages unless there is no Apple API for the job. Prefer SwiftUI, Foundation, UserNotifications, WidgetKit.

---

## Prerequisites

### Run on this Mac (package executable)

- A Mac
- Swift 6 (Xcode Command Line Tools are enough for `swift run`)
- macOS 15 or later (see `Package.swift` platforms)

Check:

```bash
swift --version
```

### Run on iPhone Simulator, a physical iPhone, TestFlight, or App Store

All of the following:

1. **Xcode** from the Mac App Store (latest stable). Command Line Tools alone cannot sign or install an iPhone app.
2. A **free Apple ID** is enough for a 7-day personal-device install. **Apple Developer Program** ($99/year) is required for TestFlight and App Store, and for devices that need a longer-lived profile.
3. An iPhone on **iOS 18+** for device installs.
4. USB cable or the same Wi-Fi network (wireless debugging after the first paired install).

Agents: do not install Homebrew packages, CocoaPods, Fastlane, or other tooling unless the human explicitly asks. This repo has **zero** third-party SPM dependencies.

---

## Setup the repo

```bash
git clone <repo-url> DueMate
cd DueMate
```

No `npm install`, `bundle install`, or `swift package resolve` of extra libraries is required.

Useful paths:

| Path | Purpose |
| --- | --- |
| `Package.swift` | Package manifest |
| `Sources/DueMateApp/DueMateApp.swift` | App entry (`AppSession.live()`) |
| `Sources/DueMateUI/AppSession.swift` | DI, persistence URL, mock API wiring |
| `Sources/DueMateCore/Networking/API.swift` | Base URL, endpoints, live/mock clients |
| `~/Library/Application Support/DueMate/snapshot.json` | Local data after first Mac run |

Build artifacts (`.build/`, `.swiftpm/`) are gitignored. Do not commit them.

---

## Run locally on Mac

From the repo root:

```bash
swift build
swift run DueMate
```

The first launch seeds **sample data in DEBUG** (HDFC card, EMIs, utilities, etc.) if the store is empty. See `AppSession.bootstrap()` and `SampleData`.

### Reset local Mac data

```bash
rm -rf "$HOME/Library/Application Support/DueMate"
swift run DueMate
```

### Common Mac run issues

| Symptom | What to do |
| --- | --- |
| `swift: command not found` | Install Xcode Command Line Tools: `xcode-select --install` |
| Build fails with iOS-only APIs | You are compiling the package for macOS; keep `#if os(iOS)` around iOS-only APIs |
| App opens with empty data in Release | Sample seed is `#if DEBUG` only |
| Stale UI after pull | `swift package clean` then `swift build` |

This Mac executable is the daily development loop. It is **not** what you submit to the App Store.

---

## Run in Xcode (Mac target from the package)

1. Open Xcode.
2. **File → Open** and select the `DueMate` folder (the one that contains `Package.swift`).
3. Select the **DueMate** scheme (the executable product).
4. Destination: **My Mac**.
5. Press Run (⌘R).

Do not expect an iPhone destination until an iOS app target exists (next section).

---

## Put DueMate on an iPhone (first time)

The package executable is macOS. To install on an iPhone you must wrap `DueMateUI` in an **iOS App** target. Do this once, then commit the Xcode project if the team wants it in git.

### A. Create the iOS app target

1. Install **Xcode** (Mac App Store). Open it and finish first-launch setup (simulator runtimes, license).
2. **File → New → Project → iOS → App**.
3. Product Name: `DueMate`
4. Team: your Apple ID team
5. Organization Identifier: `com.pradeepjadhav` (bundle ID becomes `com.pradeepjadhav.DueMate`)
6. Interface: **SwiftUI**. Language: **Swift**. Storage: **None** (this repo already has a JSON store).
7. Save the project **next to** or **inside** this repo. Preferred layout:

   ```
   DueMate/                 (git root, Package.swift)
     Package.swift
     Sources/
     Apps/
       DueMate.xcodeproj    (new)
   ```

8. In the iOS target: **File → Add Package Dependencies → Add Local…** → select the repo folder with `Package.swift`.
9. Link products **DueMateCore** and **DueMateUI** to the iOS app target.
10. Replace the generated `ContentView` / `*App.swift` so the iOS entry matches `Sources/DueMateApp/DueMateApp.swift`:

    ```swift
    import DueMateUI
    import SwiftUI

    @main
    struct DueMateApp: App {
        @State private var session = AppSession.live()

        var body: some Scene {
            WindowGroup {
                RootView(session: session)
            }
        }
    }
    ```

11. Signing & Capabilities:
    - Automatically manage signing
    - Choose your Team
    - Add **Background Modes** only if you later need them (not required for MVP)
    - Add URL Type `duemate` if you want widget/notification deep links
    - Notifications: the app requests permission in onboarding/Settings; add a usage description in Info if Xcode asks (`NSUserNotificationsUsageDescription` is not used on iOS; user-facing copy lives in the permission system prompt)

12. Set iOS Deployment Target to **18.0**.

13. Run on **iPhone Simulator** first (⌘R, destination iPhone 16 / any iOS 18 simulator).

### B. Install on a physical iPhone (developer install)

1. On the iPhone: **Settings → Privacy & Security → Developer Mode** → On → restart if asked.
2. Unlock the phone, plug it into the Mac, tap **Trust**.
3. In Xcode, destination = your device name.
4. Run (⌘R). The first time, on the phone go to **Settings → General → VPN & Device Management** (or **Device Management**) and trust the developer certificate.
5. Keep the phone unlocked while the debugger attaches.

**Free Apple ID:** the app expires in **7 days**. Re-run from Xcode to refresh.

**Paid Developer Program:** development profiles last longer; you can also use Ad Hoc or TestFlight.

Wireless: after one successful USB install, **Window → Devices and Simulators** → device → **Connect via network**.

### C. Install without a cable (internal / TestFlight)

See **TestFlight** below. That is the usual way to put a build on a phone that is not plugged into the development Mac.

---

## Publish to TestFlight

You need the **Apple Developer Program**.

1. In [Apple Developer](https://developer.apple.com/account) → Identifiers, register App ID `com.pradeepjadhav.DueMate` (or the bundle ID you actually used).
2. In [App Store Connect](https://appstoreconnect.apple.com) → **My Apps → +** → iOS app. Bundle ID must match Xcode.
3. Xcode → target → **Signing & Capabilities** → Team = paid team. Version `1.0`, build `1`. Increment build for every upload.
4. Menu **Product → Archive** (destination must be **Any iOS Device (arm64)**, not a simulator).
5. Organizer → **Distribute App → App Store Connect → Upload**.
6. Wait for processing (email / App Store Connect → TestFlight).
7. Add internal testers (App Store Connect users) or external testers (Beta App Review for the first external group).
8. Testers install **TestFlight** from the App Store and redeem the invite.

Compliance: export compliance (encryption). HTTPS-only apps typically answer the standard “uses HTTPS” questionnaire; do not claim custom encryption you did not implement.

---

## Publish to the App Store

TestFlight should already work. Then:

1. App Store Connect → the app → **App Store** tab.
2. Fill required metadata:
   - Name, subtitle, description, keywords
   - Privacy policy URL (required)
   - Support URL
   - Category (e.g. Finance)
   - Screenshots for required iPhone sizes (Xcode simulator screenshots are fine if they match current UI)
   - Age rating questionnaire
   - Privacy Nutrition Labels (this app stores financial obligation data **on device**; it should not claim to collect data you do not collect)
3. Select the processed build from TestFlight.
4. **Add for Review** → **Submit to App Review**.
5. After **Ready for Sale**, the app appears on the store according to your release option (manual vs automatic).

Review notes worth including: DueMate is an offline-first obligations tracker; login is mock until the API exists; there is no bank linking.

### App Store checklist (MVP)

- [ ] Unique bundle ID registered
- [ ] Paid Developer Program team in Xcode
- [ ] iOS 18 deployment target
- [ ] App icon (all required slots)
- [ ] Privacy policy URL live
- [ ] No secrets, API keys, or passwords in the git repo
- [ ] Archive from **Any iOS Device**, not Simulator
- [ ] New build number for every upload

---

## Configuration

### API

Defined in `Sources/DueMateCore/Networking/API.swift`:

- Base URL: `https://www.pradeepjadhav.com/api/`
- Endpoints: `APIEndpoint` (`obligations`, `occurrences`, `payments`, `categories`, `sync`, …)

`AppSession.live()` currently wires **`MockAPIClient`**. To use the network client, inject `LiveAPIClient` there and keep tokens in Keychain via `AuthenticationService` — never in source, `.xcconfig` committed secrets, or chat logs.

### Notifications

Scheduled from pending occurrences (~60 day window) in `NotificationScheduler`. Paid occurrences should not keep reminders. Enable in Settings after the system permission prompt.

### Widgets

SwiftUI layouts: `WidgetUpcomingView`, `WidgetTodayView`, `WidgetUpcomingListView`, `WidgetMonthlyView`, `WidgetLoansView` in `DueMateUI`. A WidgetKit **extension target** still needs to be added in the iOS Xcode project. The app writes `widget.json` next to the snapshot after changes.

### Deep links

Scheme `duemate`:

- `duemate://obligation/{uuid}`
- `duemate://occurrence/{uuid}`
- `duemate://calendar/{yyyy-mm-dd}`
- `duemate://tasks/today`

Register the URL type on the iOS target for these to open the app from widgets/notifications.

---

## Data and privacy

- Local snapshot includes obligations, occurrences, payments, categories, settings, and a pending sync queue.
- Do not log amounts, account numbers, tokens, or card digits.
- Never store CVV or full card numbers (the credit-card form only allows last four digits).
- Calendar access (EventKit) is **not** required.

---

## Instructions for AI coding agents

1. Read this README and `Plan.md` before large changes.
2. Prefer extending `DueMateCore` / `DueMateUI`. Do not invent a second data model.
3. Keep the package compiling: `swift build` from repo root.
4. Do not add SPM/CocoaPods/Homebrew dependencies unless the human asks.
5. Do not run `git commit` or `git push` unless the human explicitly asked in that message.
6. Do not put secrets in the repo.
7. Do not assume REST endpoints exist; keep new network calls behind `APIClientProtocol`.
8. iPhone/App Store work needs an iOS Xcode target (see above). Do not claim the package executable is App Store-ready.
9. Sample data is DEBUG-only; production/Release must not silently overwrite user data on launch.
10. Business rules stay out of SwiftUI views: recurrence, payment state, EMI progress, dashboard totals live in Core.

---

## Project map

```
DueMate/
  Package.swift
  README.md
  Plan.md                 product spec
  Sources/DueMateCore/    models, store, API, services
  Sources/DueMateUI/      SwiftUI features
  Sources/DueMateApp/     macOS (and shared) entry
```

---

## License / ownership

Private app unless the repository LICENSE file says otherwise. App Store seller name must match the Apple Developer legal entity.
