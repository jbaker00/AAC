import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct AACApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Delay slightly so the app's first view is visible before the
                    // ATT prompt appears — Apple requires this prompt for apps that
                    // show personalized ads.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
