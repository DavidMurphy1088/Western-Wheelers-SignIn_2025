
import Foundation

class AppUserDefaults : ObservableObject {
    static let instance:AppUserDefaults = AppUserDefaults()
    @Published var promptAddRiderToTemplate = true
    private static var savedKey = "APP_USER_DEFAULTS"
    
    func promptToggle() {
        DispatchQueue.main.async {
            self.promptAddRiderToTemplate.toggle()
        }
    }
    func save() {
        do {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.promptAddRiderToTemplate) {
                let compressedData = try (data as NSData).compressed(using: .lzfse)
                UserDefaults.standard.set(compressedData, forKey: AppUserDefaults.savedKey)
            }
        }
        catch {
            let msg = "Error saving user defaults \(error.localizedDescription)"
            Messages.instance.reportError(context: "AppUserDefaults", msg: msg)
        }
    }
    
    func restore() {
        let savedData = UserDefaults.standard.object(forKey: AppUserDefaults.savedKey)
        if let savedData = savedData {
            do {
                let json = try (savedData as! NSData).decompressed(using: .lzfse)
                let decoder = JSONDecoder()
                if let decoded = try? decoder.decode(Bool.self, from: json as Data) {
                    promptAddRiderToTemplate = decoded
                    Messages.instance.sendMessage(msg: "Restored user defaults")
                }
            }
            catch {
                let msg = "Error restoring defaults \(error.localizedDescription)"
                Messages.instance.reportError(context: "AppUserDefaults", msg: msg)
            }
        }
    }
    
}

