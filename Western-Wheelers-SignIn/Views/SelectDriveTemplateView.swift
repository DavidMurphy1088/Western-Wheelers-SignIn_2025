import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

struct RideTemplateCell: View {
    var template: DriveRideTemplate
    var isSelected: Bool 
    var Action: () -> Void

    init(template: DriveRideTemplate, isSelected: Bool, action: @escaping () -> Void) {
        UITableViewCell.appearance().backgroundColor = .clear
        self.template = template
        self.isSelected = isSelected  // Added this
        self.Action = action
    }

    var body: some View {
        Button(template.name, action: {
            self.Action()
        })
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        //.foregroundColor(isSelected ? .blue : .black)
        Text("")
    }
}

struct SelectDriveTemplateView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var templates = DriveRideTemplates.instance
    @State var selectedTemplate:String? = nil
    
    var body: some View {
        VStack {
            Text("Ride Templates").font(.title2).foregroundColor(Color.blue)
            Text("Select a ride template to pre-populate your ride. The template can contain any data such as the ride name, ride leader, routes, notes etc. In the template, names followed immediately on the row by check boxes are treated as riders to include for this ride.").font(.callout)
                .padding()
//            if SignedInRiders.instance.getCount() > 0 {
//                Text("The ride sheet already has \(SignedInRiders.instance.getCount()) riders. Selecting another template will clear the ride sheet. Cancel to retain the current ride sheet.")
//                    .foregroundColor(Color.red)
//                    .padding()
//            }

            VStack {
                ForEach(templates.templates, id: \.self) { temp in
                    RideTemplateCell(template: temp,
                                     isSelected: temp.isSelected,
                                     action: {
                                        selectedTemplate = temp.name
                                        templates.setSelected(name: temp.name)
                                        self.presentationMode.wrappedValue.dismiss()
                                        //if let selectedTemplate = selectedTemplate {
                                            //SignedInRiders.instance.loadTempate(name: selectedTemplate)
                                        //}
                                     })
                    
                }
            }
            .border(Color.blue)
            .padding()
            
            VStack {
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                }
                Spacer()
                Button("Sign Out of Google") {
                    //TODO GIDSignIn.sharedInstance()?.signOut()
                    self.presentationMode.wrappedValue.dismiss()
                }
                Spacer()
            }
            Spacer()
        }
        .onAppear() {
            DriveRideTemplates.instance.loadTemplates()
        }
    }
}


