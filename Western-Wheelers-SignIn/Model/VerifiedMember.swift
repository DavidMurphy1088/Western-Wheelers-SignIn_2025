import Foundation

class VerifiedMember : ObservableObject {
    static let instance:VerifiedMember = VerifiedMember()
    private static var savedKey = "VERIFIED_MEMBER"
    private let api = WAApi()
    @Published var username:String?
    
    private init() {
    }
    
    func signOut() {
        DispatchQueue.main.async { [self] in
            self.username = nil
            save()
        }
    }

    func signIn(user: String, pwd: String, fail: @escaping (String) -> ()) {
        let url = "https://api.wildapricot.org/publicview/v1/accounts/$id/contacts/me"
        api.apiCall(context: "WW Site Signin", url: url, username: user, password: pwd, completion: self.userVerified, fail: fail)
    }
    
    func userVerified(rawData: Data) {
         if let verified = try! JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] {
            let dict = verified as NSDictionary
            if let email = dict["Email"] as? String {
                DispatchQueue.main.async {
                    self.username = email
                }
            }
         }
     }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            if self.username == nil {
                UserDefaults.standard.removeObject(forKey: VerifiedMember.savedKey)
            }
            else {
                if let data = try? encoder.encode(self.username) {
                    let compressedData = try (data as NSData).compressed(using: .lzfse)
                    UserDefaults.standard.set(compressedData, forKey: VerifiedMember.savedKey)
                }
            }
        }
        catch {
            let msg = "Error saving rider list \(error.localizedDescription)"
            Messages.instance.reportError(context: "VerifiedMember", msg: msg)
        }
    }
    
    func restore() {
        let savedData = UserDefaults.standard.object(forKey: VerifiedMember.savedKey)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode(String.self, from: json as Data) {
                    username = decoded
                    Messages.instance.sendMessage(msg: "Restored \(self.username ?? "") verification from local")
                }
            }
            catch {
                let msg = "Error restoring member list \(error.localizedDescription)"
                Messages.instance.reportError(context: "VerifiedMember", msg: msg)
            }
        }
    }
    

}
