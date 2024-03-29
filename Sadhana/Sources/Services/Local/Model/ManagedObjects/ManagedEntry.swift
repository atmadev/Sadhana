//
//  ManagedEntry.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 7/8/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//


import CoreData

@objc(ManagedEntry)
class ManagedEntry: ManagedSynchable, Entry {
    typealias Key = EntryFieldKey
    var bedTime: Time? {
        get {
            return timeOptionalValue(forKey: Key.bedTime)
        } set {
            set(time: newValue, forKey: Key.bedTime)
        }
    }
    @NSManaged public var date: Date
    @NSManaged public var month: Date
    @NSManaged public var yoga: Bool
    @NSManaged public var id: NSNumber?
    @NSManaged public var japaCount7_30: Int16
    @NSManaged public var japaCount10: Int16
    @NSManaged public var japaCount18: Int16
    @NSManaged public var japaCount24: Int16
    @NSManaged public var kirtan: Bool
    @NSManaged public var lections: Bool
    var readingInMinutes: Int16 {
        get {
            return customValue(forKey: Key.reading) as! Int16
        } set {
            customSet(value: newValue, forKey: Key.reading)
        }
    }
    var reading: Time {
        get {
            return timeValue(forKey: Key.reading)
        } set {
            set(time: newValue, forKey: Key.reading)
        }
    }

    var readingTimeOptional: Time? {
        get {
            return timeValue(forKey: Key.reading)
        } set {
            set(time: newValue ?? Time(rawValue:0), forKey: Key.reading)
        }
    }
    @NSManaged public var service: Bool
    @NSManaged public var userID: Int32
    var wakeUpTime: Time? {
        get {
            return timeOptionalValue(forKey: Key.wakeUpTime)
        } set {
            set(time: newValue, forKey: Key.wakeUpTime)
    }   }

    var ID: Int32? {
        get {
            return id as? Int32
        } set {
            id = newValue != nil ? NSNumber(value: newValue!) : nil
        }
    }

    var user : User?

    var empty : Bool {
        return bedTime == nil &&
            yoga == false &&
            id == nil &&
            japaCount7_30 == 0 &&
            japaCount10 == 0 &&
            japaCount18 == 0 &&
            japaCount24 == 0 &&
            kirtan == false &&
            lections == false &&
            readingInMinutes == 0 &&
            service == false &&
            wakeUpTime == nil
    }

    @discardableResult
    func map(_ entry: Entry) -> Self {
        ID = entry.ID
        dateCreated = entry.dateCreated
        dateUpdated = entry.dateUpdated
        userID = entry.userID
        date = entry.date

        month = date.trimmedDayAndTime
        japaCount7_30 = entry.japaCount7_30
        japaCount10 = entry.japaCount10
        japaCount18 = entry.japaCount18
        japaCount24 = entry.japaCount24
        reading = entry.reading
        kirtan = entry.kirtan
        bedTime = entry.bedTime
        wakeUpTime = entry.wakeUpTime
        yoga = entry.yoga
        service = entry.service
        lections = entry.lections
        dateSynched = Date()

        return self
    }


    
    static let entityName = NSStringFromClass(ManagedEntry.self)
    
    @nonobjc public class func request() -> NSFetchRequest<ManagedEntry> {
        return NSFetchRequest<ManagedEntry>(entityName: entityName)
    }
}

/*
 Example of raw JSON: {
 "id": "58035",
 "created_at": "2016-07-31 19:08:53",
 "updated_at": "2016-07-31 22:08:53",
 "user_id": "1",
 "date": "2016-07-30",
 "day": "30",
 "jcount_730": "14",
 "jcount_1000": "2",
 "jcount_1800": "9",
 "jcount_after": "0",
 "reading": "40",
 "kirtan": "1",
 "opt_sleep": null,
 "opt_wake_up": null,
 "opt_exercise": "0",
 "opt_service": "0",
 "opt_lections": "0"
 }
 */
