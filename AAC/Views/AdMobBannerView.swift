import SwiftUI
import GoogleMobileAds
import UIKit

/// SwiftUI wrapper for Google AdMob banner ads
struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    let adSize: GADAdSize

    init(adUnitID: String = Secrets.adMobBannerID, adSize: GADAdSize = GADAdSizeBanner) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()

        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator

        // Find the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        // Configure banner view
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bannerView)

        // Center the banner view in the container
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bannerView.widthAnchor.constraint(equalToConstant: adSize.size.width),
            bannerView.heightAnchor.constraint(equalToConstant: adSize.size.height)
        ])

        // Load the ad
        bannerView.load(GADRequest())

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("✅ AdMob banner ad loaded successfully")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("⚠️ AdMob banner ad failed to load: \(error.localizedDescription)")
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print("🔍 AdMob banner ad will present screen")
        }

        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            print("🔍 AdMob banner ad will dismiss screen")
        }

        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print("🔍 AdMob banner ad did dismiss screen")
        }
    }
}

/// SwiftUI view that displays an AdMob banner with proper sizing
struct AdBannerContainer: View {
    let adSize: GADAdSize

    init(adSize: GADAdSize = GADAdSizeBanner) {
        self.adSize = adSize
    }

    var body: some View {
        AdMobBannerView(adSize: adSize)
            .frame(width: adSize.size.width, height: adSize.size.height)
    }
}
