import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SelectTemplateView : View {
    @ObservedObject var templates = RideTemplates.instance
    @Environment(\.presentationMode) private var presentationMode
    var loadTemplate : (String) -> Void

    var body: some View {
        VStack {
            Text("Select Template").font(.title2).foregroundColor(Color.blue)
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(templates.list, id: \.self.name) { template in
                            HStack {
                                VStack {
                                Button(action: {
                                    self.loadTemplate(template.name)
                                    self.presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Text(template.name)
                                })
                                    Text("\(template.list.count) riders")
                                }
                                //.padding()
                            }
                            Text("")
                        }
                    }
                }
            }
            .border(Color.black)
            .padding()
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            Spacer()
        }
     }
}

