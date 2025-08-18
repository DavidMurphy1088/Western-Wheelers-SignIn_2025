import UIKit
import GoogleSignIn
import GoogleSignIn
import GoogleAPIClientForREST

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    internal func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        VerifiedMember.instance.restore()
        AppUserDefaults.instance.restore()
        //Preferences.instance.restore()
// TODO      GIDSignIn.sharedInstance().clientID = "505823345399-a79vs9g0o24984ionca518phdqdavbuc.apps.googleusercontent.com"
//        GIDSignIn.sharedInstance().delegate = GoogleDrive.instance
//        GIDSignIn.sharedInstance()?.scopes = [kGTLRAuthScopeDrive]
        SignedInRiders.instance.restore()
        //ClubRides.instance //start the rides loading here rather than the popup that uses it so it loads at start up
        //SignUpListener.instance.start() //listen for blue tooth sign ups 
        return true
    }
}

