
import Foundation

class ClubRides : ObservableObject {
    static let instance:ClubRides = ClubRides()
    private let api = WAApi()
    @Published public var listPublished:[ClubRide] = []
    @Published public var errMsg:String? = nil
    var listFromAPI:[ClubRide] = []
    var listPagedSkip = 0
    
    private init() {
        listPublished = []
        listFromAPI = []
        listPagedSkip = 0
        getCurrentRides()
    }
    
    func getURL(skip:Int) -> String {
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
    
    func getCurrentRides() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.errMsg = nil
            Messages.instance.sendMessage(msg: "Start downloaded of club rides")
            let eventsUrl = self.getURL(skip: 0)
            self.api.apiCall(context: "Load rides", url: eventsUrl, username:nil, password:nil,
                             completion: self.loadRides,
                             fail: self.loadRidesFailed)
        }
    }
    
    func dateFromJSON(dateStr:String) -> Date {
        let index = dateStr.index(dateStr.startIndex, offsetBy: 16)
        let dateHHmm = String(dateStr[..<index])

        let LocalDateFormat = DateFormatter()
        LocalDateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        LocalDateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm"
        // if not specified this formatter's time zone is GMT
        //UTCDateFormat.timeZone = TimeZone(abbreviation: "")

        let InputDateFormat = DateFormatter()
        InputDateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        InputDateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm"
        // The app stores ride dates as expressed in UTC
        // However, the raw date string coming from the WA API is expressed in PDT time, so the input formatter needs to know to parse the raw date as being expressed in the PDT format
        // if not specified this formatter's time zone is GMT
        InputDateFormat.timeZone = TimeZone(abbreviation: "PDT") //

        let utcRideDate = InputDateFormat.date(from: String(dateHHmm))
        if let rideDate = utcRideDate {
            return rideDate
        }
        else {
            return Date(timeIntervalSince1970: 0)
        }
    }
    
    func loadRidesFailed(msg:String) {
        self.errMsg = msg
        Messages.instance.reportError(context: "Load Rides", msg: "cannot load rides after")
    }

    func loadRides(rawData: Data) {
        var ridesThisPage = [ClubRide]()
        var ridePageCount = 0
        if let events = try! JSONSerialization.jsonObject(with: rawData, options: []) as? [String: Any] {
            for (_, val) in events {
                let rides = val as! NSArray
                ridePageCount = rides.count
                for rideData in rides {
                    let rideDict = rideData as! NSDictionary
                    let ride = ClubRide(id: "", name: "")
                    //some rides have an array of sessions. Each must be listed separately in the app
                    var sessions:[ClubRide] = []
                    for (attr, value) in rideDict {
                        let key = attr as! String
                        if key == "Name" {
                            let title = value as! String
                            ride.setName(name: title)
                        }
                        if key == "StartDate" {
                            if let speced = rideDict["StartTimeSpecified"] {
                                let on = speced as! Int
                                if on == 0 {
                                    ride.timeWasSpecified = false
                                }
                            }
                            ride.dateTime = self.dateFromJSON(dateStr: value as! String)
                        }
                        if key == "Sessions" {
                            let eventSessions = value as! NSArray
                            for sess in eventSessions {
                                let sessRide = ClubRide(id:"", name: "")
                                let sessionAttributes = sess as! NSDictionary
                                for (sAttr, sValue) in sessionAttributes {
                                    let skey = sAttr as! String
                                    if skey == "StartDate" {
                                        sessRide.dateTime = self.dateFromJSON(dateStr: sValue as! String)
                                    }
                                }
                                sessions.append(sessRide)
                            }
                        }
                        if key == "Id" {
                            ride.id = "\(value)"
                        }
                    }
                    if sessions.count > 0 {
                        var sessionNum = 0
                        for session in sessions {
                            session.name = ride.name
                            session.id = ride.id + "_" + String(sessionNum)
                            session.sessionId = String(sessionNum)
                            ridesThisPage.append(session)
                            sessionNum += 1
                        }
                    }
                    else {
                        ridesThisPage.append(ride)
                    }
                }
            }
        }
        
        //self.listPaged = []
        for ride in ridesThisPage {
            if ride.nearTerm()  {
                ride.setLevels()
                self.listFromAPI.append(ride)
            }
        }
       
        if ridePageCount > 0 {
            ///get the next page of rides
            self.listPagedSkip += ridePageCount
            let eventsUrl = self.getURL(skip: listPagedSkip)
            self.api.apiCall(context: "Load rides", url: eventsUrl, username:nil, password:nil,
                             completion: self.loadRides,
                             fail: self.loadRidesFailed)
        }
        else {
            DispatchQueue.main.async {
                let sortedRides = self.listFromAPI.sorted(by: {
                    $0.dateTime < $1.dateTime
                })
                print("========= total rides", sortedRides.count)
                self.listPublished.append(contentsOf: sortedRides)
                Messages.instance.sendMessage(msg: "Downloaded \(self.listPublished.count) current club rides")
            }
        }
    }
}
