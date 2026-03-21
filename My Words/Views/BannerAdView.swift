import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {

    static var height: CGFloat {
        currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width).size.height
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> BannerAdViewController {
        let vc = BannerAdViewController()
        vc.bannerView.adUnitID = Secrets.admobBannerAdUnitId ?? "ca-app-pub-3940256099942544/2934735716"
        vc.bannerView.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {}

    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[AdMob] ✅ Banner ad loaded")
        }
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdMob] ❌ Banner failed: \(error.localizedDescription)")
        }
    }
}

// Internal UIViewController — gives the BannerView a real rootViewController
// and calls load() only after the VC is fully in the window hierarchy.
class BannerAdViewController: UIViewController {
    let bannerView: BannerView

    init() {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        bannerView = BannerView(adSize: adSize)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        bannerView.rootViewController = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // viewDidAppear guarantees we're in the window hierarchy
        bannerView.load(Request())
    }
}
