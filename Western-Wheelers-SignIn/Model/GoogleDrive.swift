import GoogleSignIn
import GoogleAPIClientForREST
import Foundation

class GoogleDrive : NSObject {
    static let instance = GoogleDrive() //first called from AppDelegate didFinishLaunching
    var notificationName:String?
    var listFunc: ((GTLRDrive_FileList?, Error?) -> ())? = nil
    
    func application(_ application: UIApplication,
                   open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        //TODO return GIDSignIn.sharedInstance().handle(url)
        return false
    }
    
    override private init() {
        super.init()
    }

    private func signIn() {
// TODO        GIDSignIn.sharedInstance().restorePreviousSignIn()
//        if GIDSignIn.sharedInstance().currentUser == nil {
//            GIDSignIn.sharedInstance()?.signIn()
//        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        // called after a sign in -OR- after
        // a call to restorePreviousSignIn which will attempt to restore a previously authenticated user without interaction.
        // This delegate will then be called at the end of this process indicating success or failure
        if let error = error {
//  TODO          if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
//                //("The user has not signed in before or they have since signed out.")
//            } else {
//                //Messages.instance.reportError(context: "GoogleDrive sign in", msg: error.localizedDescription)
//            }
        }
        NotificationCenter.default.post(name: Notification.Name(self.notificationName!), object: error)
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }

    public func getId(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        
        query.q = "name contains '\(fileName)'"
        let service = GTLRDriveService()
//TODO        if let user = GIDSignIn.sharedInstance().currentUser {
//            service.authorizer = user.authentication.fetcherAuthorizer()
//            service.executeQuery(query) { (ticket, results, error) in
//                onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
//            }
//        }
    }
    
    public func listFilesInFolder(onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
        if self.notificationName == nil {
            self.notificationName = "LIST_FILES"
            NotificationCenter.default.addObserver(self, selector: #selector(listFilesInFolderNotified), name: Notification.Name(self.notificationName!), object: nil)
        }
        listFunc = onCompleted
        signIn()
    }
    
    @objc func listFilesInFolderNotified() {
        getId("Ride_Templates") { (folderID, error) in
            guard let ID = folderID else {
                self.listFunc!(nil, error)
                return
            }
            self.listFiles(ID, onCompleted: self.listFunc!)
        }
    }
    
    private func listFiles(_ folderID: String, onCompleted: @escaping (GTLRDrive_FileList?, Error?) -> ()) {
//   TODO     let query = GTLRDriveQuery_FilesList.query()
//        query.pageSize = 100
//        query.q = "'\(folderID)' in parents"
//        let service = GTLRDriveService()
//        service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
//        service.executeQuery(query) { (ticket, result, error) in
//            onCompleted(result as? GTLRDrive_FileList, error)
//        }
    }

    func readSheet(id:String, onCompleted: @escaping ([[String]]) -> ())  {
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: id, range: "A1:Z100")
        let service = GTLRSheetsService()
// TODO       if let user = GIDSignIn.sharedInstance().currentUser {
//            service.authorizer = user.authentication.fetcherAuthorizer()
//        }
        Messages.instance.clearError()
        service.executeQuery(query) { (ticket:GTLRServiceTicket, result:Any?, error:Error?) in
            var sheetData:[[String]] = []
            if let error = error {
                Messages.instance.reportError(context: "GoogleDrive read sheet", msg: error.localizedDescription)
            } else {
                let data = result as? GTLRSheets_ValueRange
                let rows = data?.values as? [[String]] ?? [[""]]
                for row in rows {
                    sheetData.append(row)
                }
                Messages.instance.clearError()
            }
            onCompleted(sheetData)
        }
    }

    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        let service = GTLRDriveService()
        //TODO service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
        service.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
}
