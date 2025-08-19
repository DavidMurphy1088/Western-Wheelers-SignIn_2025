import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI

struct SelectRide : View {
    @ObservedObject var rides = ClubRides.instance
    @Environment(\.presentationMode) private var presentationMode
    var addRide : (ClubRide) -> Void

    var body: some View {
        VStack {
            Text("Select Ride").font(.title2).foregroundColor(Color.blue)
            ScrollView {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(rides.listPublished, id: \.self.id) { ride in
                            HStack {
                                VStack {
                                Button(action: {
                                    self.addRide(ride)
                                    self.presentationMode.wrappedValue.dismiss()
                                }, label: {
                                    Text(ride.name)
                                })
                                Text(ride.dateDisplay())
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
        }
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
        Spacer()

     }
}

