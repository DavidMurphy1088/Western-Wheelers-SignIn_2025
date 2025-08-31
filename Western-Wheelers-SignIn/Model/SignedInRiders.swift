import Foundation

class Level : Decodable, Encodable, Hashable, Equatable  {
    var name:String
    var selected:Bool = false
    private static var saveLevels = "RIDE_LEVEL"
    
    init(name:String) {
        self.name = name
    }
    
    static func == (lhs: Level, rhs: Level) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

class RideData : Encodable, Decodable {
    var templateName:String?
    var totalMiles:String?
    var totalClimb:String?
    var avgSpeed:String?
    var notes:String?
    var ride:ClubRide?
    
    func clear(clearRide:Bool) {
        templateName = nil
        totalMiles = nil
        totalClimb = nil
        avgSpeed = nil
        notes = nil
        if clearRide {
            ride = nil
        }
    }
}

class RiderList : ObservableObject {
    @Published var list:[Rider] = []
    
    func toggleSelected(id: String) {
        for r in list {
            if r.id == id {
                r.setSelected(!r.selected())
            }
        }
        self.pushChange()
    }
    
    func pushChange() {
        //force an array change to publish the row change
        list.append(Rider(id: "", nameFirst: "", nameLast: "", phone: "", emrg: "", email: ""))
        list.remove(at: list.count-1)
    }
    
    func add(rider:Rider) {
        var fnd = false
        for r in list {
            if r.id == rider.id {
                fnd = true
                break
            }
        }
        if !fnd {
            list.append(Rider(rider: rider))
        }
        sort()
    }
    
    func sort () {
        list.sort {
            $0.getDisplayName() < $1.getDisplayName()
        }
    }
    
    func remove(id:String) {
        var i = 0
        for r in list {
            if r.id == id {
                list.remove(at: i)
                break
            }
            i += 1
        }
        sort()
    }
    
    func setAdded(id: String) {
        for r in list {
            if r.id == id {
                r.isAdded = true
            }
            else {
                r.isAdded = false
            }
        }
        self.pushChange()
    }
}

class SignedInRiders : RiderList {
    static let instance:SignedInRiders = SignedInRiders()

    var levels:[Level]?
    @Published var levelSelected = false
    
    var rideData:RideData
    
    private static var savedList = "RIDE_LIST"
    private static var savedData = "RIDE_DATA"
    private static var savedLevels = "RIDE_LEVELS"

    private override init() {
       rideData = RideData()
    }
    
    func getCount() -> Int {
        return list.count
    }
    
    func hasRidersBesideLeader() -> Bool {
        if getCount()==0 {
            return false
        }
        if getCount() > 1 {
            return true
        }
        if let user = VerifiedMember.instance.username {
            return self.list[0].email != user
        }
        else {
            return true
        }
    }
    
    func getGuestId(firstName:String, lastName:String) -> Int {
        let name = firstName+lastName
        return name.hash
    }
    
    func getList() -> [Rider] {
        return list
    }
    
    func setRide(ride:ClubRide) {
        rideData.ride = ride
        self.levels = []
        for level in ride.levels {
            self.levels!.append(Level(name:level))
        }
        if let email = VerifiedMember.instance.username {
            let defaultLeader = ClubMembers.instance.getByEmail(email: email)
            if let rider = defaultLeader {
                add(rider: rider)
                setLeader(rider: rider, way: true)
            }
        }
    }
    
    func save() {
        Messages.instance.clearError()
        do {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.list) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: SignedInRiders.savedList)
            }
            if let data = try? encoder.encode(self.rideData) {
                UserDefaults.standard.set(data, forKey: SignedInRiders.savedData)
            }
            if let data = try? encoder.encode(self.levels) {
                UserDefaults.standard.set(data, forKey: SignedInRiders.savedLevels)
            }
        }
        catch {
            Messages.instance.reportError(context: "SignedInRiders saving rider list", error: error)
        }
    }
    
    func restore() {
        var savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedList)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode([Rider].self, from: json as Data) {
                    list = decoded
                    Messages.instance.sendMessage(msg: "Restored \(self.selectedCount()) signed in riders from local", publish: false)
                }
            }
            catch {
                Messages.instance.reportError(context: "SignedInRiders restore list", error: error)
            }
        }
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedData)
        if let savedData = savedData {
            let json = savedData as! NSData
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(RideData.self, from: json as Data) {
                rideData = decoded
            }
        }
        savedData = UserDefaults.standard.object(forKey: SignedInRiders.savedLevels)
        if let savedData = savedData {
            let json = savedData as! NSData
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([Level].self, from: json as Data) {
                levels = decoded
            }
        }
    }
    
    func clearData(clearRide:Bool) {
        list = []
        rideData.clear(clearRide: clearRide)
    }
    
    func toggleLevel(level:Level) {
        if let levelSet = levels {
            for l in levelSet {
                if l.name == level.name {
                    l.selected = !l.selected
                    //force a published update
                    DispatchQueue.main.async {
                        self.levelSelected = !self.levelSelected
                    }
                }
            }
        }
    }
    
    func setLeader(rider:Rider, way:Bool) {
        for r in list {
            if r.id == rider.id {
                r.isLeader = way
                r.isSelected = true
            }
            else {
                r.isLeader = false
            }
        }
        self.pushChange()
    }
    
    func setCoLeader(rider:Rider, way:Bool) {
        for r in list {
            if r.id == rider.id {
                r.isCoLeader = way
                r.isSelected = true
            }
            else {
                r.isCoLeader = false
            }
        }
        self.pushChange()
    }
    
    func selectedCount() -> Int {
        var count = 0
        for r in list {
            if r.selected() {
                count += 1
            }
        }
        return count
    }
    
    func removeUnselected() {
        var dels:[Int] = []
        for cnt in 0...list.count-1 {
            if !list[cnt].selected() {
                dels.append(cnt)
            }
        }
        var i = 0
        for d in dels {
            list.remove(at: d-i)
            i += 1
        }
    }
    
    func filter(name: String) {
        for r in list {
            if r.nameFirst.lowercased().contains(name.lowercased()) {
                r.setSelected(true)
            }
            else {
                r.setSelected(false)
            }
        }
        self.pushChange()
    }

    func setSelected(id: String) {
        for r in list {
            if r.id == id {
                r.setSelected(true)
                break
            }
        }
        //setSignInDate()
        self.pushChange()
    }
        
    func getLeader() -> Rider? {
        for rider in self.list {
            if rider.isLeader {
                return rider
            }
        }
        return nil
    }
    
    func getHTMLContent(version:String) -> String {
        var content = "<html><body>"
        if let name = rideData.ride?.name {
            content += "<h3>\(name)</h3>"
        }
        if let day = rideData.ride?.dateDisplay() {
            content += "\(day)"
        }
        if let levels = self.levels {
            for level in levels {
                if level.selected {
                    content += "<br>Level: \(level.name)"
                }
            }
        }

        content += "<h3>Ride Info</h3>"
        var members = 0
        var guests = 0
        for rider in self.list {
            if rider.isSelected {
                if rider.isGuest {
                    guests += 1
                }
                else {
                    members += 1
                }
            }
        }

        //ride info
        
        content += "Member Riders Total: \(members)"
        if guests > 0 {
            content += "<br>Guest  Riders Total: \(guests)"
        }
        
        if let miles = self.rideData.totalMiles {
            if !miles.isEmpty {
                content += "<br>Total miles: " + miles
            }
        }
        if let climb = self.rideData.totalClimb {
            if !climb.isEmpty {
                content += "<br>Total ascent: " + climb
            }
        }
        if let avg = self.rideData.avgSpeed {
            if !avg.isEmpty {
                content += "<br>Average Speed: " + avg
            }
        }
        
        content += "<h3>Ride Leaders</h3>"
        var leaders = ""
        for rider in self.list {
            if rider.isLeader {
                leaders += "<br>Ride Leader: "+rider.getDisplayName()
            }
        }
        for rider in self.list {
            if rider.isCoLeader {
                leaders += "<br>Ride Co-Leader: "+rider.getDisplayName()
            }
        }
        if leaders.isEmpty {
            content += "No ride leader was speciifed"
        }
        else {
            content += leaders.suffix(leaders.count-4)
        }
        
        content += "<h3>Riders</h3>"
        var riders = ""
        for rider in self.list {
            if rider.selected() {
                riders += "<br>" + rider.getDisplayName()
                if rider.isGuest {
                    riders += " (guest)"
                }
            }
        }
        if !riders.isEmpty {
            content += riders.suffix(riders.count-4)
        }

        // template notes
        
        var notes = ""
        if let ns = self.rideData.notes  {
            let lines = ns.components(separatedBy: "\n")
            for line in lines {
                if !line.isEmpty {
                    notes += "<br>"+line
                }
            }
        }
        if !notes.isEmpty {
            content += "<h3>Template Notes</h3>"
            content += "Template name: "+(rideData.templateName ?? "")
            content += notes
        }

        content += "<br><br>App version: \(version)</body></html>"
        return content        
    }
}
