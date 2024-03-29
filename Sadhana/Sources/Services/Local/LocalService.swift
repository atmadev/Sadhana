//
//  LocalService.swift
//  Sadhana
//
//  Created by Alexander Koryttsev on 6/26/17.
//  Copyright © 2017 Alexander Koryttsev. All rights reserved.
//


import CoreData
import Crashlytics

enum LocalError : Error {
    case noData
}

class LocalService: NSObject {
    var viewContext : NSManagedObjectContext {
        get {
            return persistentContainer.viewContext;
        }
    }
    
    private var persistentContainer: NSPersistentContainer
    var backgroundContext: NSManagedObjectContext
    
    var url : URL? {
        return persistentContainer.persistentStoreDescriptions.first?.url
    }
    
    init(completionClosure: @escaping () -> ()) {
        persistentContainer = NSPersistentContainer(name: "Model")
        persistentContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionClosure()
        }
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func newSubViewForegroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func newSubViewBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}


extension NSManagedObjectContext {
    func fetchUser(for ID:Int32) -> ManagedUser? {
        let request = ManagedUser.request()
        request.predicate = NSPredicate(format: "id == %d", ID)
        return fetchSingle(request)
    }
    
    func fetchEntry(for date:LocalDate, userID:Int32) -> ManagedEntry? {
        let request = ManagedEntry.request()
        request.predicate = NSPredicate(format: "date == %@ AND userID == %d", date.date as NSDate, userID)
        return fetchSingle(request)
    }

    func fetchOrCreateEntry(for date:LocalDate, userID:Int32) -> ManagedEntry {
        if let localEntry = fetchEntry(for: date, userID:userID) {
            return localEntry
        }
        else {
            let newEntry = create(ManagedEntry.self)
            newEntry.userID = userID
            newEntry.date = date.date
            newEntry.month = date.trimDay.date
            newEntry.dateCreated = Date()
            newEntry.dateUpdated = newEntry.dateCreated
            return newEntry
        }
    }

    func fetchEntries(by month:LocalDate, userID:Int32) -> [ManagedEntry] {
        let request = ManagedEntry.request()
        request.predicate = NSPredicate(format: "month == %@ AND userID == %d", month.date as NSDate, userID)
        request.sortDescriptors = [.init(key: "date", ascending: true)]
        return fetchHandled(request)
    }

    func fetchEntries(by monthes:[LocalDate], userID:Int32) -> [ManagedEntry] {
        let request = ManagedEntry.request()
        request.predicate = NSPredicate(format: "month IN %@ AND userID == %d", monthes.map({ (localDate) -> NSDate in
            return localDate.date as NSDate
        }), userID)
        return fetchHandled(request)
    }

    func fetchUnsendedEntries(userID:Int32) -> [ManagedEntry] {
        let previousMonth = Calendar.global.date(byAdding: .month, value: -1, to: Date())!.trimmedDayAndTime
        let request = ManagedEntry.request()
        request.predicate = NSPredicate(format: "userID == %d AND (dateSynched == nil OR dateUpdated > dateSynched) AND month >= %@", userID, previousMonth as NSDate)
        return fetchHandled(request)

    }

    private func fetchHandled<T>(_ request: NSFetchRequest<T>) -> [T] {
        do {
            return try fetch(request)
        }
        catch {
            fatalError("Can't fetch: \(error)")
        }
    }
    
    private func fetchSingle<T>(_ request: NSFetchRequest<T>) -> T? {
        request.fetchLimit = 1
        
        do {
            return try fetch(request).first
        }
        catch {
            log(error)
        }
        
        return nil
    }

    func saveHandledRecursive() {
        saveHandled()

        if self.parent != nil {
            if Thread.isMainThread,
                self.parent?.concurrencyType == .mainQueueConcurrencyType {
                self.parent?.saveHandledRecursive()
            }
            else {
                self.parent?.performAndWait {
                    self.parent?.saveHandledRecursive()
                }
            }
        }
    }

    func saveHandled() {
        if self.concurrencyType == .mainQueueConcurrencyType,
            !Thread.isMainThread {
            self.performAndWait {
                self.saveHandledInternal()
            }
        }
        else {
           saveHandledInternal()
        }
    }

    private func saveHandledInternal() {
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        do {
            try self.save()
        } catch {
            log("context error \(error)")
            Crashlytics.sharedInstance().recordError(error)
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func create<T:NSManagedObject>(_ type: T.Type) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: NSStringFromClass(T.self), into: self) as! T
    }

    private func rxFetch<T:NSManagedObject>(_ request:NSFetchRequest<T>) -> Observable<[T]> {
        return Observable<[T]>.create { [weak self] (observer) -> Disposable in
            self?.perform {
                do {
                    if let result = try self?.fetch(request) {
                        observer.onNext(result)
                        observer.onCompleted()
                    }
                    else {
                        observer.onError(GeneralError.error)
                    }
                } catch {
                    observer.onError(error)
                    #if DEBUG
                    fatalError("Failure to fetch data: \(error)")
                    #endif
                }
            }
            return Disposables.create {}
        }
    }

    private func rxFetchSingle<T:NSManagedObject>(_ request:NSFetchRequest<T>) -> Observable<T?> {
        request.fetchLimit = 1;
        return rxFetch(request).map({ (objects) -> T? in
            return objects.first
        })
    }

    private func rxSave<T>(_ object:T) -> Observable<T> {
        return Observable.create { [unowned self] (observer) -> Disposable in
            self.perform {
                do {
                    if self.persistentStoreCoordinator != nil && self.persistentStoreCoordinator!.persistentStores.count == 0 {
                        log("trying save without persistent stores")
                        //TODO: create pretty error
                        observer.onError(GeneralError.error)
                        return
                    }
                    try self.save()
                    if let parent = self.parent {
                        _ = parent.rxSave(object).subscribe(observer)
                    }
                    else {
                        observer.onNext(object)
                        observer.onCompleted()
                    }
                } catch {
                    observer.onError(error)

                    #if DEBUG
                        fatalError("Failure to save context: \(error)")
                    #endif
                }
            }

            return Disposables.create {}
        }
    }

    func rxSave(user:User) -> Observable<ManagedUser> {
        let request = ManagedUser.request()
        request.predicate = NSPredicate(format: "id = %d", user.ID)
        request.fetchLimit = 1
        return rxFetch(request).map { [unowned self] (localUsers) -> ManagedUser in
            var localUser : ManagedUser? = nil

            self.performAndWait {
                localUser = localUsers.count > 0 ? localUsers.first! : self.create(ManagedUser.self)
                localUser!.map(user:user)
            }

            return localUser!
        }.flatMap {[unowned self] (localUser) in self.rxSave(localUser)}
    }

    func rxSave(entries:[Entry]) -> Observable<[ManagedEntry]> {
        let request = ManagedEntry.request()
        let IDs = entries.compactMap { (entry) -> Int32 in
            return entry.ID!
        }
        request.predicate = NSPredicate(format: "id IN %@", IDs)
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        return self.rxFetch(request).map { [unowned self] (localEntries) -> [ManagedEntry] in
            var remoteEntries = entries.sorted(by: { (entry1, entry2) -> Bool in
                return entry1.ID! <  entry2.ID!
            })
            var updatedLocalEntries = [ManagedEntry]()

            self.performAndWait {
                var localEntriesMutable = localEntries
                while remoteEntries.count > 0 {
                    let remoteEntry = remoteEntries.first!
                    let remoteEntryID = remoteEntry.ID!
                    if localEntriesMutable.count > 0 {
                        let localEntry = localEntriesMutable.first!
                        let localEntryID = localEntry.ID!
                        switch localEntryID {
                        case remoteEntryID:
                            localEntry.map(remoteEntry)
                            updatedLocalEntries.append(localEntry)
                            localEntriesMutable.removeFirst()
                            remoteEntries.removeFirst()
                            continue
                        case 0..<remoteEntryID:
                            localEntriesMutable.removeFirst()
                            continue
                        default: break
                        }
                    }

                    let newEntry = self.create(ManagedEntry.self)
                    newEntry.map(remoteEntry)
                    updatedLocalEntries.append(newEntry)
                    remoteEntries.removeFirst()
                }
            }

            return updatedLocalEntries
            }.flatMap {[unowned self] (entries) in self.rxSave(entries)}
    }
}

