import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

class KeyboardHeightHelper: ObservableObject {
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

struct RideInfoView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @ObservedObject var signedInRiders:SignedInRiders

    @State var rating: String = ""
    @State var miles: String = ""
    @State var climbed: String = ""
    @State var avgSpeed: String = ""
    @State var notes: String = ""
    @State var notesInFocus = false
    @State var maxText:CGFloat = 200
    
    var body: some View {
        VStack {
            Text(signedInRiders.rideData.ride?.name ?? "").font(.title2).foregroundColor(Color.blue)
            if !notesInFocus {
                Text("Ride info for this ride")
                .font(.footnote).padding()
                HStack {
                    Text("Total miles")
                    Spacer()
                    TextField("miles", text: $miles)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: maxText)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 20)
                HStack {
                    Text("Climbed")
                    Spacer()
                    TextField("climbed", text: $climbed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: maxText)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 20)
                HStack {
                    Text("Average Speed")
                    Spacer()
                    TextField("avg speed", text: $avgSpeed)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: maxText)
                        .keyboardType(.decimalPad)
                    }
                .padding(.horizontal, 20)
                if signedInRiders.levels?.count ?? [].count > 1 {
                    Text("Check the level(s) you are leading")
                    .font(.footnote).padding()

                    HStack {
                        ForEach(signedInRiders.levels ?? [], id: \.self.name) { level in
                            HStack {
                                Image(systemName: (level.selected ? "checkmark.square" : "square"))
                                .onTapGesture {
                                    signedInRiders.toggleLevel(level: level)
                                }
                                Text(level.name)
                                Text(" ")
                            }
                        }
                    }
                }
            }
            Text(" ")
            Text("Notes")
            TextEditor(text: $notes)
                .multilineTextAlignment(.leading)
                .border(Color.black)
                .padding()
            .onTapGesture {
                self.notesInFocus = true
            }

            if keyboardHeightHelper.keyboardHeight > 0 {
                HStack {
                    Spacer()
                    Button("Hide Keyboard") {
                        self.notesInFocus = false
                        self.hideKeyboard()
                    }
                    Spacer()
                }
                Spacer()
            }
            else {
                if keyboardHeightHelper.keyboardHeight == 0 {
                    Button(action: {
                        signedInRiders.rideData.totalMiles = miles
                        signedInRiders.rideData.totalClimb = climbed
                        signedInRiders.rideData.avgSpeed = avgSpeed
                        signedInRiders.rideData.notes = notes
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Ok")
                    })
                    Spacer()
//                    Text("")
//                    Button(action: {
//                        self.presentationMode.wrappedValue.dismiss()
//                    }, label: {
//                        Text("Cancel")
//                    })
                    Spacer()
                    Text("")
                }
            }
        }
        .onAppear() {
            miles = signedInRiders.rideData.totalMiles ?? ""
            climbed = signedInRiders.rideData.totalClimb ?? ""
            avgSpeed = signedInRiders.rideData.avgSpeed ?? ""
            notes = signedInRiders.rideData.notes ?? ""
            notesInFocus = false
        }

    }
}
