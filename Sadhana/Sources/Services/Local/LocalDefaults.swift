//
//  LocalDefaults.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 7/11/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//

class LocalDefaults {
    enum Key : String {
        case prefix = "LocalDefaults"
        case tokens
        case entriesUpdatedDate
        case userID
        case userEmail
        case userPassword
        case optionFields
        case otherGraphsEnabled
        case guidesShown
        case showBedTimeForYesterday
        case readingOnlyInMinutes
        case manualKeyboardEnabled

        var string : String {
            return Key.prefix.rawValue.appending(rawValue.capitalizedFirstLetter)
        }
    }
    
    var userID: Int32? {
        get {
            return Int32(integer(for: .userID))
        }
        set {
            set(newValue, for:.userID)
        }
    }

    var userEmail: String? {
        get {
            return string(for: .userEmail)
        }
        set {
            set(newValue, for: .userEmail)
        }
    }

    var userPassword: String? {
        get {
            return string(for: .userPassword)
        }
        set {
            set(newValue, for: .userPassword)
        }
    }

    var optionFields : [String : Bool] {
        get {
            return dictionary(for:.optionFields) as? [String : Bool] ?? [String : Bool]()
        }
        set {
            set(newValue, for: .optionFields)
        }
    }

    var tokens : JSON? {
        get {
            return dictionary(for: .tokens)
        }
        set {
            set(newValue, for: .tokens)
        }
    }

    var entriesUpdatedDate : Date? {
        get {
            return value(for: .entriesUpdatedDate) as? Date
        }
        set {
            set(newValue, for: .entriesUpdatedDate)
        }
    }

    var guidesShown : [String : Bool] {
        get {
            return dictionary(for:.guidesShown) as? [String : Bool] ?? [String : Bool]()
        }
        set {
            set(newValue, for: .guidesShown)
        }
    }

    var showBedTimeForYesterday: Bool {
        get {
            return bool(for: .showBedTimeForYesterday)
        }
        set {
            set(newValue, for:.showBedTimeForYesterday)
        }
    }

    var readingOnlyInMinutes: Bool {
        get {
            return bool(for: .readingOnlyInMinutes)
        }
        set {
            set(newValue, for:.readingOnlyInMinutes)
        }
    }

    var manualKeyboardEnabled: Bool {
        get {
            return bool(for: .manualKeyboardEnabled)
        }
        set {
            set(newValue, for:.manualKeyboardEnabled)
        }
    }

    var shouldShowGuideCompletion = false

    func set(field:EntryFieldKey, enabled:Bool) {
        var fields = optionFields
        fields[field.rawValue] = !enabled
        optionFields = fields
    }

    func isFieldEnabled(_ field:EntryFieldKey) -> Bool {
        return optionFields[field.rawValue] ?? false
    }

    func set(guide:NSObject, shown:Bool) {
        var guides = guidesShown
        guides[guide.classString] = shown
        guidesShown = guides
    }

    func isGuideShown(_ guide:NSObject) -> Bool {
        return guidesShown[guide.classString] ?? false
    }


    func resetGuide() {
        guidesShown = [:]
    }

    func reset() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if  key != Key.guidesShown.string,
                key != Key.userEmail.string {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.resetStandardUserDefaults()
        UserDefaults.standard.synchronize()
    }

    private func string(for key:Key) -> String? {
        return UserDefaults.standard.string(forKey: key.string)
    }

    private func bool(for key:Key) -> Bool {
        return UserDefaults.standard.bool(forKey: key.string)
    }

    private func integer(for key:Key) -> Int {
        return UserDefaults.standard.integer(forKey: key.string)
    }

    private func dictionary(for key:Key) -> [String : Any]? {
        return UserDefaults.standard.dictionary(forKey: key.string)
    }

    private func value(for key:Key) -> Any? {
        return UserDefaults.standard.value(forKey: key.string)
    }

    private func remove(for key:Key) {
        UserDefaults.standard.removeObject(forKey: key.string)
        UserDefaults.standard.synchronize()
    }

    private func set(_ value:Any?, for key:Key) {
        if value != nil {
            UserDefaults.standard.set(value, forKey: key.string)
        }
        else {
            UserDefaults.standard.removeObject(forKey: key.string)
        }
        UserDefaults.standard.synchronize()
    }
}
