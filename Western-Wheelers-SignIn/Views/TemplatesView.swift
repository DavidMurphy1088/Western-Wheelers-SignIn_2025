import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import Foundation
import SwiftUI

enum ActiveTemplateSheet: Identifiable {
    case editTemplate
    var id: Int {
        hashValue
    }
}

var templateToEdit:String? //TODO this should be part of view

struct TemplatesView: View {
    @ObservedObject var templates = RideTemplates.instance
    @ObservedObject var messages = Messages.instance

    @State var activeSheet: ActiveTemplateSheet?
    @State var confirmDel:Bool = false
    @State var deleteNotOwner:Bool = false
    @State var delName:String?

    func saveTemplate (template:RideTemplate) {
        if !template.name.isEmpty {
            template.lastUpdate = Date()
            template.lastUpdater = VerifiedMember.instance.username ?? ""
            templates.save(saveTemplate: template)
        }
    }
    
    func editTemplate() -> RideTemplate {
        if let templateForDetail = templateToEdit {
            if let templateForDetail = templates.get(name: templateForDetail) {
                return templateForDetail
            }
        }
        return RideTemplate(name: "", notes: "", riders: [])
    }
    
    func dateStr(template:RideTemplate, created:Bool) -> String {
        if created {
            return Messages.dateDisplay(dateToShow: template.createDate, addDay: false, addTime: false)
        }
        else {
            return Messages.dateDisplay(dateToShow: template.lastUpdate, addDay: false, addTime: false)
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Ride Templates").font(.title2).font(.callout).foregroundColor(.blue)

            ScrollView {
                ForEach(templates.list, id: \.self) { template in
                    HStack {
                        Text(" ")
                        Button(template.name, action: {
                            templateToEdit = template.name
                            activeSheet = ActiveTemplateSheet.editTemplate
                        })
                        Spacer()
                        Text("\(template.list.count) riders")
                        Button(action: {
                            confirmDel = true
                            delName = template.name
                        }, label: {
                            if template.lastUpdater == VerifiedMember.instance.username {
                                Image(systemName: ("minus.circle")).foregroundColor(.purple)
                            }
                            else {
                                Image(systemName: ("minus.circle")).foregroundColor(.gray)
                            }
                        })
                        .alert(isPresented:$confirmDel) {
                            Alert(
                                title: Text("Are you sure you want to delete template \(delName ?? "")?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    if let delName = delName {
                                        templates.deleteTemplate(name: delName)
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .disabled(template.lastUpdater != VerifiedMember.instance.username)
                        Text(" ")
                    }
                    Text("created: \(template.creator) \(dateStr(template: template, created: true))").font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)
                    Text("updated: \(template.lastUpdater) \(dateStr(template: template, created: false))").font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)


                    Text("")
                }
            }
            .padding()
            .borderedBackground()
            .padding()
            Spacer()
            Button(action: {
                templateToEdit = nil
                activeSheet = ActiveTemplateSheet.editTemplate
            }, label: {
                Text("New Ride Template")
            })
            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }
            else {
                Text("")
            }

            //Spacer()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .editTemplate:
                TemplateEditView(template: self.editTemplate(), saveTemplate: saveTemplate(template:))
            }
        }
    }
    
}
