//
//  MyGoogleSignInApp.swift
//  MyGoogleSignIn
//
//  Created by An Luu on 2/4/25.
//

import SwiftUI

// Google sign-in
import GoogleSignIn
import GoogleSignInSwift

@main
struct MyGoogleSignInApp: App {
    let SRC = "MyGoogleSignInApp"
    
    var body: some Scene {
        let _ = print("\(SRC): Called")

        WindowGroup {
            Text(SRC)
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        print("\(SRC): user = \(String(describing: user))|error = \(String(describing: error))")
                        
                        if error != nil {
                            print("\(SRC): ERROR = \(error!)|")
                        }
                    }
                }
                .onOpenURL { url in
                    let SRC = self.SRC + ".onOpenURL"
                    print("\(SRC): Called url = \(url)|")
                    
                    GIDSignIn.sharedInstance.handle(url)
                }
            
            GoogleSignInButton(action: handleSignInButton)
        } // WindowGroup
    } // body
    
    func handleSignInButton() {
        let SRC = self.SRC + ".handleSignInButton"
        print("\(SRC): Called")
        
        GIDSignIn.sharedInstance.signIn(
            withPresenting: getRootViewController()!) { signInResult, error in
                let SRC = self.SRC + ".signIn"
                print("\(SRC): Called: signInResult = \(String(describing: signInResult))|error = \(String(describing: error))")
                if signInResult == nil {
                    return
                }
                else if error != nil {
                    print("\(SRC): error = \(error!)|")
                    return
                }
                
                // If sign in succeeded, extract user info.
                let user = signInResult!.user
                print("\(SRC): userid = \(user.userID!)|")

                if user.profile != nil {
                    let profile = user.profile!
                    print("\(SRC): email = \(profile.email)|name = \(profile.name)|")
                }
            }
    } // handleSignInButton()
    
    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
} // MyGoogleSignInApp()
