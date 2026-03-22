//
//  AppDelegate.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 20/03/26.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UNUserNotificationCenter.current().delegate = self

                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]) { granted, _ in
                    print("Push permission:", granted)
                }

                application.registerForRemoteNotifications()

        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication,
                         didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

            let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            UserDefaults.standard.set(token, forKey: "Protecta_fcmToken")

            //WebService().sendTokenToServer(token: token)
        }

        // Deep link from push
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {

            let userInfo = response.notification.request.content.userInfo

            if let url = userInfo["url"] as? String {
                NotificationCenter.default.post(name: .openDeepLink, object: url)
            }

            completionHandler()
        }

}

