//
//  AppDelegate.swift
//  Messager
//
//  Created by Ngoduc on 6/29/20.
//  Copyright © 2020 com.techmaster.D. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
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
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error)")
            }
            return
        }
        guard let user = user else {
            return
        }
        print("Did sign in with google: \(user)")
        guard let email = user.profile.email,
            let firstName = user.profile.givenName,
            let lassName = user.profile.familyName else {
                return
        }
        UserDefaults.standard.set(email, forKey: "email")
        DataBaseManager.shared.emailExists(with: email, completion: { exists in
            if !exists {
                //insert to database
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lassName,
                                           emailAddress: email)
                DataBaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        //upload Image
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _  in
                                guard let data = data else {
                                    return
                                }
                                let filename = chatUser.profileFictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data,fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("upload error : \(error)")
                                    }
                                })
                                }).resume()
                            
                        }
                        
                    }
                })
            }
        })
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user ")
            return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential) { (authResult, error) in
            guard authResult != nil, error == nil else {
                print("failed to login with google credential")
                return
            }
            print("Successfully signed in with Google Cred. ")
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        }
        
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user war disconnected")
    }
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url)
    }
}

