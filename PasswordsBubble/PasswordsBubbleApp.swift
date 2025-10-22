
import SwiftUI
import AppTrackingTransparency
import AppsFlyerLib
import Firebase
import FirebaseMessaging

@main
struct PasswordsBubbleApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegateApp
    
    var body: some Scene {
        WindowGroup {
            AppLaunchView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    private var analyticsPayload: [AnyHashable: Any] = [:]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        configureAppsFlyer()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()

        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleNotification(notification)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(startAnalytics), name: UIApplication.didBecomeActiveNotification, object: nil)
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleNotification(userInfo)
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleNotification(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotification(response.notification.request.content.userInfo)
        completionHandler()
    }

    private func configureAppsFlyer() {
        AppsFlyerLib.shared().appsFlyerDevKey = AppKeys.devkey
        AppsFlyerLib.shared().appleAppID = AppKeys.appId
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().start()
    }

    private func handleNotification(_ payload: [AnyHashable: Any]) {
        var linkStr: String?
        if let link = payload["url"] as? String {
            linkStr = link
        } else if let info = payload["data"] as? [String: Any], let link = info["url"] as? String {
            linkStr = link
        }
        
        if let linkStr = linkStr {
            UserDefaults.standard.set(linkStr, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(name: NSNotification.Name("LoadTempURL"), object: nil, userInfo: ["tempUrl": linkStr])
            }
        }
    }

    @objc private func startAnalytics() {
        AppsFlyerLib.shared().start()
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }

    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        analyticsPayload = data
        NotificationCenter.default.post(name: .analyticsReceived, object: nil, userInfo: ["analytics": data])
    }

    func onConversionDataFail(_ error: Error) {
        NotificationCenter.default.post(name: .analyticsFailed, object: nil, userInfo: ["analytics": [:]])
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            NotificationCenter.default.post(name: .pushTokenUpdated, object: token)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    
}
