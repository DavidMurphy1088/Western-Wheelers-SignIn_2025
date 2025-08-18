
import Foundation
import SwiftUI

class Messages : ObservableObject {
    static public let instance = Messages()
    @Published public var messages:[String] = []
    @Published public var errMessage:String? = nil

    func sendMessage(msg: String) {
        DispatchQueue.main.async {
            print("MESSAGE", msg)
            self.messages.append(msg)
        }
    }
    
    func getMessages() -> String {
        var msg = ""
        for m in messages {
            msg += m + "\n"
        }
        return msg
    }
    
    func reportCKError(context:String, err:Error) {
        //case networkFailure = 4
        //case notAuthenticated = 9
        //case partialFailure = 2
        var msg = ""
        let errMsg = String(describing: err)
        if errMsg.contains("Permission Failure") {
            msg += "Not signed in with Apple ID, "
        }
        msg += err.localizedDescription
        reportError(context: context, msg: msg)
    }
    
    func reportError(context:String, msg: String? = nil, error:Error? = nil) {
        DispatchQueue.main.async {
            var message:String = msg ?? ""
            if !NetworkReachability().checkConnection() {
                message += "\nInternet appears to be offline"
            }
            if let err = error {
                message += " " + err.localizedDescription
            }
            self.errMessage = context + " " + message
            Messages.instance.sendMessage(msg: "Error:\(String(describing: self.errMessage))")
        }
    }
    
    func clearError() {
        if self.errMessage == nil || self.errMessage!.isEmpty {
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            sleep(10)
            DispatchQueue.main.async {
                self.errMessage = nil
            }
        }
    }
    
    static func dateDisplay(dateToShow:Date, addDay:Bool, addTime:Bool) -> String {
        let formatter = DateFormatter() // this formats the day,time according to users local timezone
        formatter.dateFormat = addDay ? "EEEE MMM d" : "MMM d"
        let dayDisp = formatter.string(from: dateToShow)
        if !addTime {
            return dayDisp
        }
        
        // force 12-hour format even if they have 24 hour set on phone
        let timeFmt = "h:mm a"
        formatter.setLocalizedDateFormatFromTemplate(timeFmt)
        formatter.dateFormat = timeFmt
        formatter.locale = Locale(identifier: "en_US")
        let timeDisp = formatter.string(from: dateToShow)
        let disp = dayDisp + ", " + timeDisp
        return disp
    }

}
