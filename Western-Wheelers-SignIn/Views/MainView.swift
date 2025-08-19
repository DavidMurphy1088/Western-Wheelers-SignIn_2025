import SwiftUI
import CoreData
import GoogleSignIn
import MessageUI
import WebKit

var riderForDetail:Rider? = nil //cannot get binding approach to work :(

struct RiderView: View {
    var selectRider : ((Rider) -> Void)!
    @ObservedObject var rider: Rider
    @State var deleteNeedsConfirm:Bool
    @State var checkedAction: () -> Void
    @State var deletedAction: () -> Void
    @State var confirmDelete:Bool = false
    
    var showSelect:Bool
    
    var body: some View {
        VStack {
            HStack {
                Text(" ")
                if showSelect {
                    Image(systemName: (self.rider.selected() ? "checkmark.square" : "square"))
                    .onTapGesture {
                        self.checkedAction()
                    }
                    Text(" ")
                }

                Button(rider.getDisplayName(), action: {
                    riderForDetail = self.rider
                    if selectRider != nil {
                        selectRider(rider)
                    }
                })
                if rider.isAdded {
                    Text("added").font(.footnote).foregroundColor(.gray)
                }
                Spacer()
                if self.rider.isLeader {
                    Text("Leader").italic()
                }
                else {
                    if self.rider.isCoLeader {
                        Text("Co-leader").italic()
                    }
                }
                Image(systemName: ("minus.circle")).foregroundColor(.purple)
                    .onTapGesture {
                        if deleteNeedsConfirm {
                            self.confirmDelete = true
                        }
                        else {
                            self.deletedAction()
                        }
                    }
                    .alert(isPresented:$confirmDelete) {
                        Alert(
                            title: Text("Delete rider?"),
                            primaryButton: .destructive(Text("Delete")) {
                                self.deletedAction()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                Text(" ")
            }
            Text("")
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .id(self.rider.id) 
    }
}

struct RidersView: View {
    var selectRider : ((Rider) -> Void)!
    @ObservedObject var riderList:RiderList
    var deleteNeedsConfirm:Bool

    @Binding var scrollToRiderId:String
    var showSelect:Bool
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: true) {
                ScrollViewReader { proxy in
                    VStack {
                        ForEach(riderList.list, id: \.self.id) { rider in
                            RiderView(selectRider: selectRider, rider: rider, deleteNeedsConfirm: self.deleteNeedsConfirm,
                                      checkedAction: {
                                     DispatchQueue.main.async {
                                         riderList.toggleSelected(id: rider.id)
                                     }
                                 },
                                 deletedAction: {
                                    DispatchQueue.main.async {
                                        riderList.remove(id: rider.id)
                                    }
                                 },
                                 showSelect: showSelect
                            )
                        }
                    }
                    .onChange(of: scrollToRiderId) { target in
                        if scrollToRiderId != "" {
                            withAnimation {
                                proxy.scrollTo(scrollToRiderId)
                            }
                        }
                    }
                }
            }
            .padding()
            .border(riderList.list.count == 0 ? Color.white : Color.gray)
            .padding()
        }
     }
}

enum ActiveSheet: Identifiable {
    case selectTemplate, selectRide, addRider, addGuest, emailStats, riderDetail, rideInfoEdit, showHelp
    var id: Int {
        hashValue
    }
}
enum CommunicationType: Identifiable {
    case phone, text, email, waiverEmail
    var id: Int {
        hashValue
    }
}

extension  CurrentRideView {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
    private class MailComposerDelegate: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }

    private func presentMessageCompose(riders:[Rider], way:CommunicationType, body: String?) {
        guard MFMessageComposeViewController.canSendText() else {
            return
        }
        let vc = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
        if way == CommunicationType.text {
            let composeVC = MFMessageComposeViewController()
            var recips:[String] = []
            for rider in riders {
                if rider.isSelected && !rider.phone.isEmpty {
                    recips.append(rider.phone)
                }
            }
            composeVC.recipients = recips
            if let msg = body {
                composeVC.body = msg
            }
            composeVC.messageComposeDelegate = messageComposeDelegate
            vc?.present(composeVC, animated: true)
        }
        if way == CommunicationType.email || way == CommunicationType.waiverEmail {
            let mailVC = MFMailComposeViewController()
            mailVC.setToRecipients([riders[0].email])
            mailVC.mailComposeDelegate = mailComposeDelegate
            if way == CommunicationType.waiverEmail {
                mailVC.setSubject("Western Wheelers Liability Waiver")
                mailVC.setMessageBody(ClubRide.guestWaiverDoc(ride: signedInRiders.rideData.ride, html: true), isHTML: true)
            }
            vc?.present(mailVC, animated: true)
        }
    }
}

struct HTMLStringView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

struct HelpView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    func doc() -> String {
        var msg = ""
        if let fileURL = Bundle.main.url(forResource: "doc_help", withExtension: "txt") {
            if let fileContents = try? String(contentsOf: fileURL) {
                msg = fileContents
            }
        }
        return msg
    }

    var body: some View {
        
        VStack {
            Spacer()
            Text("Ride Sign In Help")
            Spacer()
            HTMLStringView(htmlContent: doc())
            Spacer()
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Ok")
            })
            Spacer()
        }
    }
}

struct CurrentRideView: View {
    @ObservedObject var signedInRiders = SignedInRiders.instance
    @ObservedObject var rides = ClubRides.instance
    var rideTemplates = RideTemplates.instance
    @State private var selectRideTemplateSheet = false
    @State private var emailShowing = false
    @State var emailResult: MFMailComposeResult? = nil
    @State var scrollToRiderId:String = ""
    @State var confirmClean:Bool = false
    @State var confirmAddTemplate:Bool = false
    @State var emailShowStatus:Bool = false
    @State var confirmEmailWithoutLeader:Bool = false
    @State var riderForTemplate:Rider?
    @State var updateTemplate:Bool = false
    @State var emailStatus:String?
    @State var emailWaiverRecipient:String?
    @State var activeSheet: ActiveSheet?
    @State var animateIcon = false
    @State var showInfo = false

    private let messageComposeDelegate = MessageComposerDelegate()
    private let mailComposeDelegate = MailComposerDelegate()

    @ObservedObject var messages = Messages.instance
    @Environment(\.openURL) var openURL

    func addRide(ride:ClubRide) {
        signedInRiders.setRide(ride: ride)
    }
    
    func loadTemplate(name:String) {
        rideTemplates.loadTemplate(name: name, signedIn: signedInRiders)
    }
    
    func selectRider(_: Rider) {
        activeSheet = ActiveSheet.riderDetail
    }
    
    func version() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let bld = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        let info = "Version \(version) build \(bld)"
        return info
    }
    
    func addRider(rider:Rider, clubMember: Bool) {
        if ClubMembers.instance.getByName(displayName: rider.getDisplayName()) != nil {
            rider.inDirectory = true
        }
        SignedInRiders.instance.add(rider: rider)
        SignedInRiders.instance.setSelected(id: rider.id)
        SignedInRiders.instance.setAdded(id: rider.id)
        self.scrollToRiderId = rider.id
        ClubMembers.instance.clearSelected()
        if AppUserDefaults.instance.promptAddRiderToTemplate {
            addRiderToTemplate(rider: rider)
        }
        if !rider.inDirectory {
            self.riderCommunicate(riders: [rider], way: CommunicationType.waiverEmail, body: nil)
        }
    }
    
    func riderCommunicate(riders:[Rider], way:CommunicationType, body:String?) {
        DispatchQueue.global(qos: .userInitiated).async {
            //only way to get this to work. i.e. wait for calling view to be shut down fully before text ui is displayed
            usleep(500000)
            DispatchQueue.main.async {
                if way == CommunicationType.phone {
                    //let url:NSURL = URL(string: "TEL://0123456789")! as NSURL
                    var phone = ""
                    for c in riders[0].phone {
                        if c.isNumber {
                            phone += String(c)
                        }
                    }
                    let url:NSURL = URL(string: "TEL://\(phone)")! as NSURL
                    UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                }
                else {
                    self.presentMessageCompose(riders: riders, way: way, body: body)
                }
            }
        }
    }
        
    func info() -> String {
        var info = "Thanks for using the Western Wheelers Sign-In app and I hope you find it useful. Feel free to send any suggestions or new ideas to davidmurphy1088@gmail.com"
        info += "\n\n\(version())"
        info += "\n\n"+Messages.instance.getMessages()
        return info
    }
    

    func addRiderToTemplate(rider:Rider) {
        //offer to add rider to template
        if let templateName = signedInRiders.rideData.templateName  {
            if let template = rideTemplates.get(name: templateName) {
                DispatchQueue.global(qos: .userInitiated).async {
                    sleep(1)
                    var fnd = false
                    for templateRider in template.list {
                        if templateRider.id == rider.id {
                            fnd = true
                            break
                        }
                    }
                    if !fnd {
                        self.riderForTemplate = Rider(rider: rider)
                        self.updateTemplate = true
                    }
                }
            }
        }
    }

    var body: some View {
        VStack {
            VStack{
                Text("")
                if signedInRiders.rideData.ride == nil {
                    VStack {
                        Spacer()
                        Text("Western Wheelers").font(.title2)
                        Text("Ride Sign Up").font(.title2)
                        Image("Bike_Wheel")
                            .resizable()
                            .onAppear {
                                self.animateIcon.toggle()  //cause the animation to start
                            }
                            .rotationEffect(Angle(degrees: self.animateIcon ? 2160: 0)) //, anchor: UnitPoint(x: 1.0, y: 1.0))
                            .animation(Animation.linear(duration: 30).repeatForever(autoreverses: false))
                            .frame(width: 200, height: 200, alignment: .center)
                        Spacer()
                        if let errMsg = rides.errMsg {
                            Text("Cannot load rides, \(errMsg)\nPlease verify internet connectivity")
                                .foregroundColor(Color.red)
                        }
                        else {
                            if rides.listPublished.count == 0 {
                                Text("Loading current rides ...")
                            }
                            else {

                                Button("Select a Ride") {
                                    activeSheet = .selectRide
                                }
                                .font(.title2)
                                .padding()
                                .background(Color.gray.opacity(0.2)) // muted grey background
                                .cornerRadius(10) // rounded corners
                            }
                        }
                        Spacer()
                    }
                }
                else {
                    Text(signedInRiders.rideData.ride?.name ?? "")
                        .font(.title2)
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.2)) // muted grey background
                        .cornerRadius(8) // rounded corners
                    //Text("")
                    Button("Select Ride Template") {
                        if !SignedInRiders.instance.hasRidersBesideLeader() {
                            activeSheet = .selectTemplate
                        }
                        else {
                            confirmAddTemplate = true
                        }
                    }
                    .padding(8)
                    .disabled(rideTemplates.list.count == 0)
                    .alert(isPresented:$confirmAddTemplate) {
                        Alert(
                            title: Text("Clear the ride sheet?"),
                            message: Text("Adding a template will clear the ride sheet. The sheet has \(SignedInRiders.instance.getCount()) riders."),
                            primaryButton: .destructive(Text("Clear")) {
                                activeSheet = .selectTemplate
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    if SignedInRiders.instance.getCount() > 0 && SignedInRiders.instance.selectedCount() < SignedInRiders.instance.getCount() {
                        Button("Remove Unselected Riders") {
                            SignedInRiders.instance.removeUnselected()
                        }
                        .padding(8)
                    }
                    Button("Clear Ride Sheet") {
                        confirmClean = true
                    }
                    .padding(8)
                    .alert(isPresented:$confirmClean) {
                        Alert(
                            title: Text("Clear the ride sheet and start a new ride?"),
                            primaryButton: .destructive(Text("Clear")) {
                                signedInRiders.clearData(clearRide: true)
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    RidersView(selectRider: selectRider, riderList: SignedInRiders.instance, deleteNeedsConfirm: false, scrollToRiderId: $scrollToRiderId, showSelect: true)
                    
                    HStack {
                        Spacer()
                        VStack {
                            Button(action: {
                                activeSheet = .addRider
                            }) {
                                HStack {
                                    Text("Add Rider")
                                }
                            }
                            .frame(alignment: .leading)
                            Text("")
                            Button(action: {
                                activeSheet = .addGuest
                            }) {
                                HStack {
                                    Text("Add Guest")
                                }
                            }
                            .frame(alignment: .leading)
                        }
                        .alert(isPresented: $updateTemplate) { () -> Alert in
                            Alert(
                                title: Text("Update template?"),
                                message: Text("\(self.riderForTemplate?.getDisplayName() ?? "") is not in the template \(signedInRiders.rideData.templateName!)"),
                                primaryButton: .destructive(Text("Add rider to template")) {
                                    if let template = rideTemplates.get(name: signedInRiders.rideData.templateName!) {
                                        template.add(rider: riderForTemplate!)
                                        template.setAdded(id: riderForTemplate!.id)
                                        rideTemplates.save(saveTemplate: template)
                                    }
                                    riderForTemplate = nil
                                },
                                secondaryButton: .cancel()
                            )
                        }

                        Spacer()
                        VStack {
                            Button(action: {
                                activeSheet = .rideInfoEdit
                            }, label: {
                                Text("Ride Info")
                            })
                            .alert(isPresented: $emailShowStatus) { () -> Alert in
                                Alert(title: Text(emailStatus ?? ""))
                            }
                            Text("")
                            Button(action: {
                                emailResult = nil
                                if signedInRiders.getLeader() != nil || confirmEmailWithoutLeader {
                                    activeSheet = .emailStats
                                }
                                else {
                                    confirmEmailWithoutLeader = true
                                }
                            }, label: {
                                Text("Email Ride Sheet")
                            })
                            .disabled(signedInRiders.selectedCount() == 0)
                            .alert(isPresented:$confirmEmailWithoutLeader) {
                                Alert(
                                    title: Text("The ride has no leader speciifed. Do you want to still send the email without a ride leader?"),
                                    primaryButton: .destructive(Text("Yes")) {
                                        activeSheet = .emailStats
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
//                            Button(action: {
//                                riderCommunicate(riders: signedInRiders.getList(), way: CommunicationType.text)
//                            }, label: {
//                                Text("Text All Riders")
//                            })

                        }

                        Spacer()
                    }
                }
            }
            Text("")
            HStack {
                Spacer()
                Button(action: {
                    self.activeSheet = .showHelp

                }) {
                    Image(systemName: "questionmark.circle").resizable().frame(width:30.0, height: 30.0)
                }

                Spacer()
                Text("Signed up \(SignedInRiders.instance.selectedCount()) riders").font(.footnote)
                Spacer()
                Button(action: {
                    self.showInfo = true
                }) {
                    Image(systemName: "info.circle.fill").resizable().frame(width:30.0, height: 30.0)
                }
                .actionSheet(isPresented: self.$showInfo) {
                    ActionSheet(
                        title: Text("App Info"),
                        message: Text(info()),
                        buttons: [
                            .cancel {  },
                        ]
                    )
                }

                Spacer()
            }

            if let errMsg = messages.errMessage {
                Text(errMsg).font(.footnote).foregroundColor(Color.red)
            }
            else {
                Text("")
            }
        }
        
        .sheet(item: $activeSheet) { item in
            switch item {
            case .selectTemplate:
                SelectTemplateView(loadTemplate: self.loadTemplate(name:))
            case .selectRide:
                SelectRide( addRide: self.addRide(ride:)) 
            case .addRider:
                AddRiderView(addRider: self.addRider(rider:clubMember:), usingTemplate: signedInRiders.rideData.templateName != nil)
            case .addGuest:
                AddGuestView(addRider: self.addRider(rider:clubMember:))
            case .emailStats:
                let msg = SignedInRiders.instance.getHTMLContent(version: version())
                let rideDate = Messages.dateDisplay(dateToShow: SignedInRiders.instance.rideData.ride!.dateTime, addDay: true, addTime: false)
                let rideName = SignedInRiders.instance.rideData.ride!.rideNameNoLevels()
                if MFMailComposeViewController.canSendMail() {
                    SendMailView(isShowing: $emailShowing, result: $emailResult,
                                 messageRecipient:"stats@westernwheelers.org", 
                                 //messageRecipient:"davidmurphy1088@gmail.com",
                                 messageSubject: "WW Ride Sheet,\(rideName),\(rideDate)",
                                 messageContent: msg)
                }
                //else {
                 //
                //}
            case .riderDetail:
                RiderDetailView(rider: riderForDetail!, prepareCommunicate: self.riderCommunicate(riders:way:body:))
            case .rideInfoEdit:
                RideInfoView(signedInRiders: signedInRiders)
            case .showHelp:
                HelpView()
            }
        }
        
        .onAppear() {
//  TODO          GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        }
        
        .onChange(of: emailResult) {result in
            if emailResult == nil {
                return
            }
            self.emailShowStatus = true
            if result == MFMailComposeResult.sent {
                emailStatus = "Signup sheet sent for \(SignedInRiders.instance.selectedCount()) riders"
            }
            if result == MFMailComposeResult.cancelled {
                emailStatus = "Email cancelled"
            }
            if result == MFMailComposeResult.failed {
                emailStatus = "Email failed"
            }
            if result == MFMailComposeResult.saved {
                emailStatus = "Email saved"
            }
        }
    }
}

struct MainView: View {
    @Environment(\.scenePhase) var scenePhase
    @ObservedObject var verifiedMember:VerifiedMember = VerifiedMember.instance

    var body: some View {
        if verifiedMember.username != nil {
            TabView {
                CurrentRideView()
                .tabItem {
                    Label("Ride", systemImage: "bicycle.circle.fill")
                }
                TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet.rectangle")
                }
                MembersView()
                .tabItem {
                    Label("Members", systemImage: "person.3.fill")
                }
            }
            .onChange(of: scenePhase) { newScenePhase in
              switch newScenePhase {
              case .active:
                break
              case .inactive:
                VerifiedMember.instance.save()
                SignedInRiders.instance.save()
                AppUserDefaults.instance.save()
              case .background:
                VerifiedMember.instance.save()
                SignedInRiders.instance.save()
                AppUserDefaults.instance.save()
              @unknown default:
                break
              }
            }
        }
        else {
            SignInView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
