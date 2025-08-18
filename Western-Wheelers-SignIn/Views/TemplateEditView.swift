import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct TemplateEditView: View {
    @State var template:RideTemplate
    var saveTemplate : (RideTemplate) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()

    @State var activeSheet: ActiveSheet?
    @State var scrollToRiderId:String = ""
    @State var notesInFocus = false
    
    enum ActiveSheet: Identifiable {
        case addRider
        var id: Int {
            hashValue
        }
    }
    
    func addRider(rider:Rider, clubMember:Bool = false) {
        rider.setSelected(true)
        if ClubMembers.instance.getByName(displayName: rider.getDisplayName()) != nil {
            rider.inDirectory = true
        }
        template.add(rider: rider)
        self.scrollToRiderId = rider.id
        template.setAdded(id: rider.id)

        ClubMembers.instance.clearSelected()
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Template\nName:")
                    TextField("name", text: $template.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                HStack {
                    Text("Notes:")
                    TextEditor(text: $template.notes)
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .border(Color.gray)
                        .padding()
                        .frame(maxHeight: 100.0)
                        .onTapGesture {
                            self.notesInFocus = true
                    }
                }
                
                if keyboardHeightHelper.keyboardHeight == 0 {
                    RidersView(riderList: template, deleteNeedsConfirm: true, scrollToRiderId: $scrollToRiderId, showSelect: false)
                }

                HStack {
                    Spacer()
                    if notesInFocus {
                        Button(action: {
                            self.hideKeyboard()
                            self.notesInFocus = false
                        }, label: {
                            Text("Hide Keyboard")
                        })
                    }
                    else {
                        Button(action: {
                            activeSheet = ActiveSheet.addRider
                        }, label: {
                            Text("Add Rider")
                        })
                    }
                    Spacer()
                }
                //Text("")
                HStack {
                    Spacer()
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                        saveTemplate(template)
                    }, label: {
                        Text("Ok")
                    })
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
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:), usingTemplate: false)
            }
        }
    }
}
