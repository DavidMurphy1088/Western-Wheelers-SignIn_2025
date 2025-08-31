import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

struct MembersView: View {
    @ObservedObject var memberList = ClubMembers.instance
    @State var enteredNameStr: String = ""

    var body: some View {
        VStack {
            Text("Club Members").font(.title2).font(.callout).foregroundColor(.blue)
            VStack {
                let enteredName = Binding<String>(get: {
                    self.enteredNameStr
                }, set: {
                    self.enteredNameStr = $0.lowercased()
                    memberList.filter(name: enteredNameStr)
                })

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
            }

            ScrollView {
                ForEach(memberList.clubList, id: \.self) { member in
                    if member.selected() || self.enteredNameStr.isEmpty {
                        HStack {
                            Text(" ")
                            Text(member.getDisplayName())
                            Spacer()
                            Text(member.phone)
                            Text(" ")
                        }
                    }
                }
            }
            .padding()
            .borderedBackground()
            .padding()
            
            Spacer()
        }
    }
}
