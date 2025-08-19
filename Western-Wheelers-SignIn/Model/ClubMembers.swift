import Foundation

class ClubMembers : ObservableObject {
    @Published public var clubList:[Rider] = []
    static let instance:ClubMembers = ClubMembers()
    static let savedDataName = "MemberListData"
    private var pageList:[Rider] = []
    private let api = WAApi()

    private init() {

        DispatchQueue.global(qos: .userInitiated).async {
            var done = false
            var skipRecordCount = 0
            //let pageSize = 400
            let pageSize = 100 //19Aug2025 100 is new Wild Apricot max page size
            var downloadList:[Rider] = []
            var pageCount = 0

            while !done {
                var url = "https://api.wildapricot.org/publicview/v1/accounts/$id/contacts"
                url += "?%24skip=\(skipRecordCount)&%24top=\(pageSize)"
                self.pageList = []
                self.api.apiCall(context: "Load members", url: url, username:nil, password:nil, completion: self.loadMembers, fail: self.loadMembersFailed)
                skipRecordCount += pageSize
                downloadList.append(contentsOf: self.pageList)
                pageCount += 1
                if self.pageList.count < pageSize {
                    done = true
                    break
                }
                
            }
            downloadList.sort {
                $0.getDisplayName().uppercased() < $1.getDisplayName().uppercased()
            }
            let msg = "Downloaded \(self.clubList.count) club members in \(pageCount) download pages"
            Messages.instance.sendMessage(msg: msg)
            if downloadList.count > 0 {
                self.updateList(updList: downloadList)
            }
        }
        
        let savedData = UserDefaults.standard.object(forKey: ClubMembers.savedDataName)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let list = try? decoder.decode([Rider].self, from: json as Data) {
                    DispatchQueue.main.async {
                        self.clubList = list
                        Messages.instance.sendMessage(msg: "Restored \(list.count) club members from local")
                    }
                }
                else {
                    Messages.instance.reportError(context: "ClubRiders", msg: "Unable to member list")
                }
            }
            catch {
                let msg = "Error restoring member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
        else {
            Messages.instance.sendMessage(msg: "Please wait for the club member list to download")
        }
    }
    
    private func getURL(skip:Int) -> String {
        var eventsUrl = "https://api.wildapricot.org/v2/accounts/$id/events"
        let formatter = DateFormatter()
        let startDate = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        
        ///Got to ensure we load all the session templates
        formatter.dateFormat = "yyyy-01-01"
        //formatter.dateFormat = "yyyy-MM-dd"
        let startDateStr = formatter.string(from: startDate)
        eventsUrl = eventsUrl + "?%24filter="
        eventsUrl += "StartDate%20gt%20\(startDateStr)"
        
        let maxPageSize = 100 ///WA imposed max page size
        eventsUrl = eventsUrl + "&%24top=\(maxPageSize)&%24skip=\(skip)"
        
        print("=========", eventsUrl)
        return eventsUrl
    }
    
    func loadMembersFailed(msg: String) {
        Messages.instance.reportError(context: "ClubRiders", msg: msg)
    }

    func loadMembers(rawData: Data) {
        var cnt = 0
        
        if let contacts = try! JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] {
            for (key, val) in contacts {

                if key == "Contacts" {
                    let members = val as! NSArray
                    for member in members {
                        let memberDict = member as! NSDictionary

                        let id = memberDict["Id"] as! Int
                        var lastName = ""
                        if let name = memberDict["LastName"] as? String {
                            lastName = name
                        }
                        var firstName = ""
                        if let name = memberDict["FirstName"] as? String {
                            firstName = name
                        }
                        
                        //var homePhone = ""
                        var cellPhone = ""
                        var emergencyPhone = ""
                        var email = ""

                        let keys = memberDict["FieldValues"] as! NSArray
                        var c = 0
                        for k in keys {
                            let fields = k as! NSDictionary
                            let fieldName = fields["FieldName"]
                            let fieldValue = fields["Value"]
                            c = c+1

                            if fieldName as! String == "Cell Phone" {
                                if let e = fieldValue as? String {
                                    cellPhone = e
                                }
                            }
                            if fieldName as! String == "Emergency Phone" {
                                if let e = fieldValue as? String {
                                    emergencyPhone = e
                                }
                            }
                            if fieldName as! String == "e-Mail" {
                                if let e = fieldValue as? String {
                                    email = e
                                }
                            }

                        }
                        cnt += 1
                        self.pageList.append(Rider(id: String(id), nameFirst: firstName, nameLast: lastName, phone: cellPhone, emrg: emergencyPhone, email: email))
                    }
                }
            }
        }
    }

    func get(id:String) -> Rider? {
        for r in clubList {
            if r.id == id {
                return r
            }
        }
        return nil
    }
    
    func getByName(displayName:String) -> Rider? {
        for r in clubList {
            if r.getDisplayName() == displayName {
                return r
            }
        }
        return nil
    }
    
    func getByEmail(email:String) -> Rider? {
        for r in clubList {
            if r.email == email {
                return r
            }
        }
        return nil
    }

    func selectionCount() -> Int {
        var cnt = 0
        for r in clubList {
            if r.selected() {
                cnt += 1
            }
        }
        return cnt
    }
    
    func getFirstSelected() -> Rider? {
        for r in clubList {
            if r.selected() {
                return r
            }
        }
        return nil
    }
    
    func pushChange() {
        //force an array change to publish the row change
        clubList.append(Rider(id: "", nameFirst: "", nameLast: "", phone: "", emrg: "", email: ""))
        clubList.remove(at: clubList.count-1)
    }

    func filter(name: String) {
        let parts = name.components(separatedBy: " ")
        for r in clubList {
            if name.isEmpty  {
                r.setSelected(false)
                continue
            }
            if parts.count == 1 {
                if r.nameLast.lowercased().contains(name.lowercased()) || r.nameFirst.lowercased().contains(name.lowercased()) {
                    r.setSelected(true)
                }
                else {
                    r.setSelected(false)
                }
            }
            else {
                if r.nameLast.lowercased().contains(parts[1].lowercased()) && r.nameFirst.lowercased().contains(parts[0].lowercased()) {
                    r.setSelected(true)
                }
                else {
                    r.setSelected(false)
                }

            }
        }
        self.pushChange()
    }
    
    func clearSelected() {
        for r in clubList {
            r.setSelected(false)
        }
        //force an array change to publish the row change
        pushChange()
    }

    func updateList(updList: [Rider]) {
        Messages.instance.clearError()
        DispatchQueue.main.async {
            self.clubList = []
            for r in updList {
                self.clubList.append(r)
            }
            do {
                var capacity:Int64 = 0
                //In iOS, the home directory is the application’s sandbox directory
                let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                let values = try docPath.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                if let cap = values.volumeAvailableCapacityForImportantUsage {
                    capacity = cap
                }

                let encoder = JSONEncoder()
                if let data = try? encoder.encode(self.clubList) {
                    let compressedData = try (data as NSData).compressed(using: .lzfse)
                    if compressedData.count < capacity {
                        UserDefaults.standard.set(compressedData, forKey: ClubMembers.savedDataName)
                    }
                    else {
                        Messages.instance.reportError(context: "ClubRiders", msg:"insufficent space to save list")
                    }
                }
            }
            catch {
                let msg = "Error saving member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "ClubRiders", msg: msg)
            }
        }
    }
}
