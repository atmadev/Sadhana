//
//  ManagedObject.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 7/24/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//


import CoreData

@objc(ManagedObject)
class ManagedObject: NSManagedObject {
    func customValue(forKey key:FieldKey) -> Any? {
        let rawKey = key.rawValue
        return customValue(forRawKey: rawKey)
    }
    
    func customSet<T>(value:T?, forKey key:FieldKey) {
        let rawKey = key.rawValue
        customSet(value: value, forRawKey: rawKey)
    }
    
    func customValue(forRawKey rawKey:String) -> Any? {
        willAccessValue(forKey: rawKey)
        let value = primitiveValue(forKey: rawKey)
        didAccessValue(forKey: rawKey)
        return value
    }
    
    func customSet<T>(value:T?, forRawKey rawKey:String) {
        willChangeValue(forKey: rawKey)
        let newValue : T? = (value != nil) ? value : nil
        setPrimitiveValue(newValue, forKey: rawKey)
        didChangeValue(forKey: rawKey)
    }

    func timeValue(forKey key:FieldKey) -> Time {
        return Time(rawValue:(customValue(forKey: key) as! NSNumber))
    }

    func timeOptionalValue(forKey key:FieldKey) -> Time? {
        return Time(rawValue:(customValue(forKey: key) as? NSNumber))
    }

    func set(time:Time, forKey key:FieldKey) {
        customSet(value: time.nsNumber, forKey: key)
    }

    func set(time:Time?, forKey key:FieldKey) {
        customSet(value: time?.nsNumber, forKey: key)
    }
}

@objc(ManagedUpdatable)
class ManagedUpdatable: ManagedObject, Updatable {
    @NSManaged public var dateCreated: Date
    @NSManaged public var dateUpdated: Date
}

@objc(ManagedSynchable)
class ManagedSynchable: ManagedUpdatable, Synchable {
    @NSManaged public var dateSynched: Date?
}
