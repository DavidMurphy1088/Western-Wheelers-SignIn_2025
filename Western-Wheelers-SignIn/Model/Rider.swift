import Foundation

class Rider : Hashable, Equatable, Identifiable, Encodable, Decodable, ObservableObject {
    var id:String
    var nameFirst:String
    var nameLast:String
    var phone:String
    var emergencyPhone:String
    var email:String
    var isSelected: Bool
    var isAdded: Bool
    var isLeader:Bool
    var isCoLeader:Bool
    var inDirectory:Bool
    var isGuest:Bool
    //var isDeleteInTemplate:Bool

    init (id:String, nameFirst:String, nameLast:String, phone:String, emrg:String, email:String, isGuest:Bool = false) {
        self.id = id
        self.nameFirst = nameFirst
        self.nameLast = nameLast
        self.phone = Rider.formatPhone(phone: phone)
        self.emergencyPhone = Rider.formatPhone(phone: emrg)
        self.email = email
        self.isSelected = false
        self.isAdded = false
        self.isLeader = false
        self.isCoLeader = false
        self.inDirectory = false
        self.isGuest = isGuest
        //self.isDeleteInTemplate = false
    }
    
    init (rider:Rider) {
        self.id = rider.id
        self.nameFirst = rider.nameFirst
        self.nameLast = rider.nameLast
        self.phone = rider.phone
        self.emergencyPhone = rider.emergencyPhone
        self.email = rider.email
        self.isSelected = rider.isSelected
        self.isAdded = rider.isAdded
        self.isLeader = rider.isLeader
        self.isCoLeader = rider.isCoLeader
        self.inDirectory = rider.inDirectory
        self.isGuest = rider.isGuest
        //self.isDeleteInTemplate = rider.isDeleteInTemplate
    }
    
    enum CodingKeys: String, CodingKey {
        //requires hand crafted code if type contains any published types
        case id
        case nameFirst
        case nameLast
        case phone
        case emergencyPhone
        case email
        case isSelected
        case isHilighted
        case isLeader
        case isCoLeader
        case inDirectory
        case isGuest
        case isPrivacyVerified
        case accessEmail
        case accessEmergencyPhone
        case accessPhone
    }
        
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(nameFirst, forKey: .nameFirst)
        try container.encode(nameLast, forKey: .nameLast)
        try container.encode(phone, forKey: .phone)
        try container.encode(emergencyPhone, forKey: .emergencyPhone)
        try container.encode(email, forKey: .email)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isAdded, forKey: .isHilighted)
        try container.encode(isLeader, forKey: .isLeader)
        try container.encode(isCoLeader, forKey: .isCoLeader)
        try container.encode(inDirectory, forKey: .inDirectory)
        try container.encode(isGuest, forKey: .isGuest)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.nameFirst = try container.decode(String.self, forKey: .nameFirst)
        self.nameLast = try container.decode(String.self, forKey: .nameLast)
        self.phone = try container.decode(String.self, forKey: .phone)
        self.emergencyPhone = try container.decode(String.self, forKey: .emergencyPhone)
        self.email = try container.decode(String.self, forKey: .email)
        self.isSelected = try container.decode(Bool.self, forKey: .isSelected)
        self.isAdded = try container.decode(Bool.self, forKey: .isHilighted)
        self.isLeader = try container.decode(Bool.self, forKey: .isLeader)
        self.isCoLeader = try container.decode(Bool.self, forKey: .isCoLeader)
        self.inDirectory = try container.decode(Bool.self, forKey: .inDirectory)
        self.isGuest = try container.decode(Bool.self, forKey: .isGuest)
    }
    
    func selected() -> Bool {
        return self.isSelected
    }
    func setSelected(_ way:Bool) {
        self.isSelected = way
    }
    
    func getLeader() -> Bool {
        return self.isLeader
    }

    static func == (lhs: Rider, rhs: Rider) -> Bool {
        return lhs.getDisplayName() == rhs.getDisplayName()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(getDisplayName())
    }
    
    func getDisplayName() -> String {
        if nameFirst.isEmpty {
            return nameLast
        }
        if nameLast.isEmpty {
            return nameFirst
        }
        return nameFirst + " " + nameLast
    }
    
    static func formatPhone(phone:String) -> String {
        if phone.count==0 || phone.isEmpty {
            return ""
        }
        var num = "("
        for c in phone {
            if c.isNumber {
                num += String(c)
                if num.count == 4 {
                    num += String(") ")
                }
                if num.count == 9 {
                    num += String("-")
                }
            }
        }
        return num
    }
}
