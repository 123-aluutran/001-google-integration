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

// Google calendar
import GoogleAPIClientForREST_Calendar

@main
struct MyGoogleSignInApp: App {
    let SRC = "MyGoogleSignInApp"
    
    //=== Local ===
    @State var user: GIDGoogleUser? = nil
    
    var body: some Scene {
        let _ = print("\(SRC): Called")
        
        WindowGroup {
            Text(SRC)
                .onAppear {
                    // https://stackoverflow.com/questions/25897086/obtain-bundle-identifier-programmatically-in-swift.
                    // Trace for informational/diagnostic purpose.
                    if let bundleID = Bundle.main.bundleIdentifier {
                        print("\(SRC): bundleID = \(bundleID)")
                    }

                    restoreSignIn()
                }
                .onOpenURL { url in
                    let SRC = self.SRC + ".onOpenURL"
                    print("\(SRC): Called url = \(url)|")
                    
                    GIDSignIn.sharedInstance.handle(url)
                }
            
            if user != nil {
                let profile = user!.profile!
                Text("Signed in as \(profile.name), \(profile.email)")
                
                HStack {
                    Text("Sign in as different user: ")
                    GoogleSignInButton(action: handleSignInButton)
                }
            }
            else {
                GoogleSignInButton(action: handleSignInButton)
            }
            
            if user != nil {
                List {
                    Section {
                        MyGoogleCalendar(user: user!)
                    }
                }
            }
        } // WindowGroup
    } // body
    
    func handleSignInButton() {
        let SRC = self.SRC + ".handleSignInButton"
        print("\(SRC): Called")
        
        // func signIn(withPresenting presentingViewController: UIViewController, hint: String?, additionalScopes: [String]?) async throws -> GIDSignInResult
        GIDSignIn.sharedInstance.signIn(
            withPresenting: getRootViewController()!, hint: "", additionalScopes: [kGTLRAuthScopeCalendar]) { signInResult, error in
                let SRC = self.SRC + ".signIn"
                print("\(SRC): Called: signInResult = \(String(describing: signInResult))|error = \(String(describing: error))")
                if signInResult == nil {
                    return
                }
                else if error != nil {
                    print("\(SRC): error = \(error!)|")
                    return
                }
                
                // If sign-in succeeded, extract user info.
                user = signInResult!.user
                print("\(SRC): user = <\(MyGoogleSignInApp.printUser(user!))>")
            }
    } // handleSignInButton()
    
    private func restoreSignIn() {
        let SRC = self.SRC + ".restoreSignIn"
        print("\(SRC): Called")
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { tmpUser, error in
            let SRC = self.SRC + ".restorePreviousSignIn"
            user = tmpUser
            
            print("\(SRC): user = \(String(describing: user))|error = \(String(describing: error))")
            
            if user != nil {
                print("\(SRC): user = \(MyGoogleSignInApp.printUser(user!))")
            }
            
            if error != nil {
                print("\(SRC): ERROR = \(error!)|")
            }
        }
        
        print("\(SRC): Done")
    } // restoreSignIn()
    
    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
    
    static func printUser(_ user: GIDGoogleUser) -> String {
        var str = "userid = \(user.userID!)"

        if user.profile != nil {
            let profile = user.profile!
            str += "|profile = <email = \(profile.email)|name = \(profile.name)>"
        }
        
        return str
    } // printUser()
} // MyGoogleSignInApp()

struct MyGoogleCalendar: View {
    let SRC = "MyGoogleCalendar"
    
    //=== Interface ===
    @State var user: GIDGoogleUser
    
    var body: some View {
        let _ = print("\(SRC): Called")
        
        Text(SRC)
        
        Button("Add event to calendar") {
            addEventoToGoogleCalendar(summary: "My summary", description: "My description", startTime: "01/01/2025 08:00", endTime: "01/02/2025 08:00")
        }
        
        Button("Fetch calendar events") {
            fetchGoogleCalendarEvents()
        }
    }
    
    // Create an event to the Google Calendar's user
    func addEventoToGoogleCalendar(summary : String, description :String, startTime : String, endTime : String) {
        let SRC = self.SRC + ".addEventoToGoogleCalendar"
        print("\(SRC): Called")
        
        let calendarEvent = GTLRCalendar_Event()
        
        calendarEvent.summary = "\(summary)"
        calendarEvent.descriptionProperty = "\(description)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let startDate = dateFormatter.date(from: startTime)
        let endDate = dateFormatter.date(from: endTime)
        
        guard let toBuildDateStart = startDate else {
            print("Error getting start date")
            return
        }
        guard let toBuildDateEnd = endDate else {
            print("Error getting end date")
            return
        }
        calendarEvent.start = buildDate(date: toBuildDateStart)
        calendarEvent.end = buildDate(date: toBuildDateEnd)

        let insertQuery = GTLRCalendarQuery_EventsInsert.query(withObject: calendarEvent, calendarId: "primary")
        
        let service = GTLRCalendarService()
        service.authorizer = user.fetcherAuthorizer
        service.executeQuery(insertQuery) { (ticket, object, error) in
            if error == nil {
                print("\(SRC): Event inserted")
            } else {
                print("\(SRC): error = \(error!)|")
            }
        }
        
        // Helper to build date
       func buildDate(date: Date) -> GTLRCalendar_EventDateTime {
           let datetime = GTLRDateTime(date: date)
           let dateObject = GTLRCalendar_EventDateTime()
           dateObject.dateTime = datetime
           return dateObject
       }
    } // addEventoToGoogleCalendar()
    
    func fetchGoogleCalendarEvents() {
        let SRC = self.SRC + ".fetchGoogleCalendarEvents"
        print("\(SRC): Called")
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("User not signed in")
            return
        }

        let accessToken = user.accessToken.tokenString
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                let responseString = String(data: data, encoding: .utf8)
                print("Response: \(responseString ?? "No data")")
            }
        }
        task.resume()
        
        print("\(SRC): Done")
    } // fetchGoogleCalendarEvents()
} // MyGoogleCalendar
