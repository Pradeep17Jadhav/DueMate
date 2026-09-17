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
