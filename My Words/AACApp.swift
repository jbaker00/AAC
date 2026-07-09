import SwiftUI
import GoogleMobileAds
import FirebaseCore

@main
struct AACApp: App {
    init() {
        FirebaseApp.configure()
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["b25b3c0304041fc99af04bd474bfcc9a"]
        #endif
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
