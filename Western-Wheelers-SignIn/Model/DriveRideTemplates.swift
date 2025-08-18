import Foundation
import GoogleAPIClientForREST

class DriveRideTemplate: Identifiable, Hashable, Equatable {
    var id = UUID()
    var name: String = ""
    var ident: String = ""
    var isSelected: Bool = false
    var nextId: Int = 10000
    
    init(name: String, ident: String){
        self.name = name
        self.ident = ident
    }
    
    static func == (lhs: DriveRideTemplate, rhs: DriveRideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func requestLoad(ident:String) {
        GoogleDrive.instance.readSheet(id: self.ident, onCompleted:loadData(data:))
    }
    
    func loadData(data:[[String]]) {
        for row in data {
            if row.count > 1 && (row[1] == "TRUE" || row[1] == "FALSE") { // and row.count == 2
                if row[0] != "" {
                    let name = row[0]
                    let components = name.components(separatedBy: ",")
                    var nameLast = ""
                    var nameFirst = ""
                    if components.count < 2 {
                        //nameLast = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        nameFirst = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    else {
                        nameLast = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        nameFirst = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    var phone = ""
                    var email = ""
                    var emerg = ""
                    var inDirectory = false
                    var id = ""
//                    if row.count > 2 {
//                        phone = row[2]
//                    }
//                    if row.count > 3 {
//                        email = row[3]
//                    }
                    if let rider = ClubMembers.instance.getByName(displayName: nameLast+", "+nameFirst) { 
                        //load the rider data from the directory if possible
                        if phone == "" {
                            phone = rider.phone
                        }
                        if email == "" {
                            email = rider.email
                        }
                        emerg = rider.emergencyPhone
                        inDirectory = true
                        id = rider.id
                    }
                    else {
                        id = String(self.nextId)
                        self.nextId += 1
                    }
                    let rider = Rider(id: id, nameFirst: nameFirst, nameLast: nameLast, phone: phone, emrg: emerg, email: email)
                    rider.inDirectory = inDirectory
                    if row[1] == "TRUE" {
                        rider.setSelected(true)
                    }
                    SignedInRiders.instance.add(rider: rider)
                }
            }
            else {
                var note = ""
                for fld in row {
                    note += " " + fld
                }
                if SignedInRiders.instance.rideData.notes == nil {
                    SignedInRiders.instance.rideData.notes = ""
                }
                SignedInRiders.instance.rideData.notes! += note + "\n"
            }
        }
        SignedInRiders.instance.sort()
    }
}

class DriveRideTemplates : ObservableObject {
    static let instance = DriveRideTemplates() //called when shared first referenced
    @Published var templates:[DriveRideTemplate] = []

    private init() {
    }
    
    func setSelected(name: String) {
        for t in templates {
            if t.name == name {
                t.isSelected = true
            }
            else {
                t.isSelected = false
            }
        }
        //force an array change to publish the row change
        templates.append(DriveRideTemplate(name: "", ident: ""))
        templates.remove(at: templates.count-1)
    }
    
    func loadTemplates() {
        let drive = GoogleDrive.instance
        drive.listFilesInFolder(onCompleted: self.saveTemplates)
    }
    
    func saveTemplates(files: GTLRDrive_FileList?, error: Error?) {
        templates = []
        if let filesList : GTLRDrive_FileList = files {
            if let filesShow : [GTLRDrive_File] = filesList.files {
                for file in filesShow {
                    if let name = file.name {
                        self.templates.append(DriveRideTemplate(name: name, ident: file.identifier!))
                    }
                }
            }
        }
    }
}
