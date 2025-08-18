import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct AddGuestView: View {
    var addRider : (Rider, Bool) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var enteredGuestNameFirst: String = ""
    @State var enteredGuestNameLast: String = ""
    @State var enteredPhone: String = ""
    @State var enteredEmergency: String = ""
    @State var enteredEmail: String = ""
    @State var maxText: CGFloat = 200
    @State var dataMissing: Bool = false

    var body: some View {
        VStack {
            if keyboardHeightHelper.keyboardHeight == 0  {
                VStack {
                    Text("Add a Guest Rider").font(.title2)
                    Text("Use this form to enter a guest rider\nwho is not a club member")
                    .font(.footnote).padding()
                    .multilineTextAlignment(.center)
                }
            }
            
            HStack {
                Spacer()
                Text("First Name").multilineTextAlignment(.trailing)
                TextField("first name", text: $enteredGuestNameFirst).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Last Name").multilineTextAlignment(.trailing)
                TextField("last name", text: $enteredGuestNameLast).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Cell Phone").multilineTextAlignment(.trailing)
                TextField("cell phone", text: $enteredPhone).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                    .keyboardType(.decimalPad)
                Spacer()
            }
            HStack {
                Spacer()
                Text("Emergency").multilineTextAlignment(.trailing)
                TextField("emergency phone", text: $enteredEmergency).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                    .keyboardType(.decimalPad)
                Spacer()
            }
            HStack {
                Spacer()
                Text("        EMail").multilineTextAlignment(.trailing)
                TextField("email", text: $enteredEmail).frame(width: 150)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: maxText)
                    .keyboardType(.emailAddress)
                Spacer()
            }
            Spacer()
            
            HStack {
                Spacer()
                Button("Add") {
                    if enteredGuestNameFirst.isEmpty || enteredGuestNameLast.isEmpty {
                        self.dataMissing = true
                    }
                    else {
                        addRider(Rider(id: String(SignedInRiders.instance.getGuestId(firstName: enteredGuestNameFirst, lastName: enteredGuestNameLast)),
                                       nameFirst: enteredGuestNameFirst, nameLast: enteredGuestNameLast, phone: enteredPhone, emrg: enteredEmergency, email: enteredEmail, isGuest:true), false)
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                
                .alert(isPresented: $dataMissing) { () -> Alert in
                    Alert(title: Text("The guest's names must be entered"))
                }

                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                })
                Spacer()
            }
            Spacer()

        }
        
        .border(Color.blue)
        .padding()
        .scaledToFit()
    }
}
