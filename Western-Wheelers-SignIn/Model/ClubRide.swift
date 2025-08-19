import Foundation

class ClubRide : Identifiable, Decodable, Encodable, ObservableObject {
    var id:String
    var sessionId:String
    var name:String = ""
    var timeWasSpecified:Bool = true
    var dateTime: Date = Date()
    var activeStatus: Int = 0
    var levels:[String] = []
    static let LONGEST_RIDE_IN_HOURS = 8.0 //asume max ride length of 8 hrs

    init(id:String, name:String) {
        self.id = id
        self.sessionId = ""
        self.setName(name: name)
    }
    
    func setName(name:String) {
        var rideName = ""
        let words = name.components(separatedBy: " ")
        var cnt = 0
        for word in words {
            if word.contains("/") || word.count <= 1 {
                rideName = rideName + " " + word
            }
            else {
                let x = String(word.suffix(word.count-1))
                rideName = rideName + " " + word.prefix(1) + x.lowercased()
            }
            cnt += 1
        }
        self.name = rideName.trimmingCharacters(in: .whitespaces)
    }
    
    func rideNameNoLevels() -> String {
        var name = ""
        let words = self.name.components(separatedBy: " ")
        for word in words {
            //"D/3-4/35-65"
            if !(word.contains("/") || word.contains("-")) {
                name = name + " " + word
            }
        }
        return name
    }
    
    func setLevels() {
        var titleLevels: [String] = []
        //let name = "C/3/15+; D/4/15+ TUESDAY EVENING RIDE"
        let specs = name.components(separatedBy: ";")
        for spec in specs {
            let parts = spec.components(separatedBy: "/")
            for part in parts {
                let upPart = part.uppercased().trimmingCharacters(in: .whitespaces)
                var lvl = ""
                for c in upPart {
                    if c >= "A" && c <= "E" {
                        if !lvl.isEmpty {
                            titleLevels.append(lvl)
                        }
                        lvl = String(c)
                    }
                    else {
                        if c == "+" || c == "-" {
                            lvl  += String(c)
                        }
                        else {
                            lvl = ""
                            break
                        }
                    }
                }
                if !lvl.isEmpty {
                    titleLevels.append(lvl)
                }
            }
        }
        let levelSet = Set(titleLevels)
        titleLevels = []
        titleLevels.append(contentsOf: levelSet)
        titleLevels.sort()
        levels = []
        levels.append(contentsOf: titleLevels)
    }
    
    func nearTerm() -> Bool {
        let seconds = Date().timeIntervalSince(self.dateTime) // > 0 => ride start in past
        let minutes = seconds / 60.0
        let startHours = minutes / 60
        let endHours = startHours - ClubRide.LONGEST_RIDE_IN_HOURS
        
        if endHours > 16.0 {
            return false
        }
        else {
            if endHours > 0 {
                return false
            }
            else {
                if startHours > 0 {
                    return true
                }
                else {
                    if abs(startHours) < 48.0 {
                        return true
                    }
                    else {
                        return false
                    }
                }
            }
        }
    }
    
    func dateDisplay() -> String {
        return Messages.dateDisplay(dateToShow: self.dateTime, addDay: true, addTime: self.timeWasSpecified)
    }
    
    static func guestWaiverDoc(ride: ClubRide?, html: Bool) -> String {
        var msg = ""
        if html {
            msg += "<html><body>"
        }
        msg += "Welcome to your Western Wheelers ride today."
        if let ride = ride {
            msg += " \(ride.dateDisplay())"
            msg += " Ride: \(ride.name)"
        }

        if html {
            msg += "<br><br>"
        }
        msg += "Please review the liability waiver below prior to starting the ride."
        if html {
            msg += "<br><br>"
        }
        msg += "Then place your initials here ____ and reply to this email to indicate your consent to the waiver."
        if html {
            msg += "<br><br>"
        }
        if let fileURL = Bundle.main.url(forResource: "doc_waiver", withExtension: "txt") {
            if let fileContents = try? String(contentsOf: fileURL) {
                if html {
                    // Replace newline characters with <br> tags for HTML
                    let htmlFormattedContents = fileContents.replacingOccurrences(of: "\n", with: "<br>")
                    msg += htmlFormattedContents
                } else {
                    msg += fileContents
                }
            }
        }
        if html {
            msg += "</body></html>"
        }
        return msg
    }
    
}


