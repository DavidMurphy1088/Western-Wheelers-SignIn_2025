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
            Text("Select A Ride").font(.title2).foregroundColor(Color.blue)

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
                           Text("")
                       }
                   }
                   .padding()
                   //.background(Color.gray.opacity(0.1))
               }
            }
            .borderedBackground()
        }
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
        })
        Spacer()

     }
}

