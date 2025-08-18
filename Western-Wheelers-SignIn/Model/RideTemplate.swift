import Foundation
import CloudKit

class RideTemplate: RiderList, Hashable {
    var name: String = ""
    var lastUpdater:String = ""
    var lastUpdate:Date = Date()
    var creator:String = ""
    var createDate:Date = Date()
    var notes:String = ""
    var recordId:CKRecord.ID?

    init(name: String, notes:String, riders:[Rider]){
        self.name = name
        self.notes = notes
        self.lastUpdater = VerifiedMember.instance.username ?? ""
        self.creator = VerifiedMember.instance.username ?? ""
        self.createDate = Date()
    }
    
    init(record:CKRecord) {
        super.init()
        recordId = record.recordID
        if let data = record["name"] {
            name = data.description
        }
        if let data = record["notes"] {
            notes = data.description
        }
        if let data = record["lastUpdater"] {
            lastUpdater = data.description
        }
        if let data = record["lastUpdate"] {
            lastUpdate = (data as! NSDate) as Date
        }
        if let data = record["creator"] {
            creator = data.description
        }
        if let data = record["createdDate"] {
            createDate = (data as! NSDate) as Date
        }
        let riders = record.object(forKey: "riders") as! NSArray
        let decoder = JSONDecoder()
        for r in riders {
            let json = Data("\(r)".utf8)
            if let rider = try? decoder.decode(Rider.self, from: json) {
                list.append(rider)
            }
        }
    }
    
    static func == (lhs: RideTemplate, rhs: RideTemplate) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    func makeRecord() -> CKRecord {
        var ckRecord = CKRecord(recordType: "RideTemplates")
        if let id = self.recordId {
            ckRecord = CKRecord(recordType: "RideTemplates", recordID: id)
        }
        ckRecord["name"] = name as CKRecordValue
        ckRecord["notes"] = notes as CKRecordValue
        ckRecord["lastUpdater"] = VerifiedMember.instance.username ?? "" 
        ckRecord["lastUpdate"] = Date()
        ckRecord["creator"] = creator as CKRecordValue
        ckRecord["createdDate"] = createDate as CKRecordValue
        let encoder = JSONEncoder()
        var jsonRiders:[String] = []
        for rider in self.list {
            if let data = try? encoder.encode(rider) {
                let s = String(data: data, encoding: String.Encoding.utf8)
                jsonRiders.append(s!)
            }
        }
        ckRecord["riders"] = jsonRiders as CKRecordValue
        return ckRecord
    }
    
    func remoteAdd() {
        let op = CKModifyRecordsOperation(recordsToSave: [makeRecord()], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive

        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords == nil || savedRecords?.count != 1 {
                Messages.instance.reportCKError(context: "Template add", err: error!)
                return
            }
            guard let records = savedRecords else {
                Messages.instance.reportError(context: "RideTemplate", msg: "none added")
                return
            }
            let record = records[0]
            self.recordId = record.recordID
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }
    
    public func remoteModify() {
        let op = CKModifyRecordsOperation(recordsToSave: [makeRecord()], recordIDsToDelete: [])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive
        op.savePolicy = .allKeys  //2 hours later ... required otherwise it does NOTHING :( :(
        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || savedRecords?.count != 1 {
                Messages.instance.reportCKError(context: "Template modify", err: error!)
            }
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }
    
    public func remoteDelete() {
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [self.recordId!])
        op.queuePriority = .veryHigh
        op.qualityOfService = .userInteractive
        op.savePolicy = .allKeys
        op.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            if error != nil || deletedRecordIDs?.count != 1 {
                Messages.instance.reportCKError(context: "Template delete", err: error!)
            }
        }
        RideTemplates.container.publicCloudDatabase.add(op)
    }

}
