import SwiftUI
import UIKit
import Combine
import os.log

class Keyboard: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    init() {
        self.listenForKeyboardNotifications()
        
    }
    private func listenForKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification,
                                               object: nil,
                                               queue: .main) { [self] (notification) in
                                                guard let userInfo = notification.userInfo,
                                                    let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                                                
                                                self.keyboardHeight = keyboardRect.height
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
                                               object: nil,
                                               queue: .main) { (notification) in
                                                self.keyboardHeight = 0
        }
    }
}

struct SignInView: View {
    @ObservedObject var member = VerifiedMember.instance
    @ObservedObject var keyboard = KeyboardHeightHelper()
    @Environment(\.presentationMode) private var presentationMode
    @State private var username = ""
    @State private var password = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var message: String?

    func loginFailed(msg:String) {
        message = "Sorry, sign into Western Wheelers failed with these credentials"
    }
    func connected() -> Bool {
        return NetworkReachability().checkConnection()
    }
    
    var body: some View {
        VStack  {
            if self.keyboardHeight == 0 {
                Text("Western Wheelers Sign In").font(.title2)
                Text("")
                if keyboard.keyboardHeight == 0 {
                    Text("A one-time Western Wheelers member verification for using this app is needed. Please sign in using the email and password you use to sign into the Western Wheelers site as illustrated.").font(.footnote).padding().fixedSize(horizontal: false, vertical: true)
                    Image("Image_SignIn").resizable().frame(width: 180, height: 180)
                }
            }

            if !self.connected() {
                Text("No internet to check Western Wheelers account").foregroundColor(Color.red)
            }
            else {
                Text("Email")
                TextField("email", text: self.$username, onEditingChanged: {_ in}, onCommit: {})
                    .frame(width: 300, height: nil)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
            
                Text("Password")
                SecureField("Password", text: $password, onCommit: {
                })
                .frame(width: 300, height: nil)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                HStack {
                    Button(action: {
                        Messages.instance.clearError()
                        member.signIn(user: self.username, pwd: self.password, fail: self.loginFailed)
                        //member.signIn(user: "davidmurphy1088@gmail.com", pwd: "WW_AppleApps!01", fail: self.loginFailed)
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack {
                            Text("")
                            Text("")
                            Text("Sign In").font(.title)
                        }
                    }
                }
                if let msg = self.message {
                    Text(msg).foregroundColor(Color.red)
                }
            }
        }
        .padding(.bottom, self.keyboardHeight)
//        .onReceive(Publishers.keyboardHeight) {
//            self.keyboardHeight = 1.0 * $0
//        }
    }
}
