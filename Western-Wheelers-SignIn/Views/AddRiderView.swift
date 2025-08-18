import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SelectScrollView : View {
    @ObservedObject var clubMembers = ClubMembers.instance
    @Environment(\.presentationMode) private var presentationMode
    var addRider : (Rider, Bool) -> Void

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(clubMembers.clubList, id: \.self.id) { rider in
                            if rider.selected() {
                                HStack {
                                    //Text(rider.name)
                                    Button("   "+rider.getDisplayName()+"   ", action: {
                                        self.addRider(Rider(rider: rider), true)
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                    //.padding()
                                }
                                Text("")
                            }
                        }
                    }
                }
            }
            .border(Color.black)
            .padding()
        }
     }
}

struct AddRiderView: View {
    var addRider : (Rider, Bool) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var clubMembers = ClubMembers.instance
    @ObservedObject var appUserDefaults = AppUserDefaults.instance
    @State var usingTemplate:Bool
    @State var scrollToRider:String?
    @State var pickedName: String = "" //nil means the .onChange is never called but idea why ...
    @State var enteredNameStr: String = ""
    @State var changeCount = 0

    var body: some View {
        VStack {
            let enteredName = Binding<String>(get: {
                self.enteredNameStr
            }, set: {
                self.enteredNameStr = $0.lowercased()
                clubMembers.filter(name: enteredNameStr) //, nameFirst: enteredNameFirstStr)
            })

            Text("Add a Rider").font(.title2).foregroundColor(Color.blue)
            HStack {
                Spacer()
                Image(systemName: "magnifyingglass")
                Text("Name")
                TextField("first or last name", text: enteredName)
                    .frame(minWidth: 0, maxWidth: 250)  //, minHeight: 0, maxHeight: 200)
                    .simultaneousGesture(TapGesture().onEnded {
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
            }
            if usingTemplate {
                HStack {
                    Text("Prompt to add riders to template?")
                    Image(systemName: (appUserDefaults.promptAddRiderToTemplate ? "checkmark.square" : "square"))
                    .onTapGesture {
                        appUserDefaults.promptToggle()
                    }
                }
            }
        }
        
        SelectScrollView(addRider: addRider)
        
        Button(action: {
            self.enteredNameStr = ""
            clubMembers.clearSelected()
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
        Spacer()
    }
}
