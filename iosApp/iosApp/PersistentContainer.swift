import Foundation
import CoreData

class PersistentContainer {
    private var backgroundContext: NSManagedObjectContext?
    private let persistentContainerQueue = OperationQueue()
    
    init() {
        persistentContainerQueue.maxConcurrentOperationCount = 1
    }
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Data")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func context() -> NSManagedObjectContext {
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        return persistentContainer.viewContext
    }
    
    func sharedBackgroundContext() -> NSManagedObjectContext {
        let newBackgroundContext = backgroundContext ?? persistentContainer.newBackgroundContext()
        backgroundContext = newBackgroundContext
        return newBackgroundContext
    }
    
    func saveContext(block: @escaping (_ context: NSManagedObjectContext) -> Void, _ actionAfterSave: @escaping () -> Void = {}) {
        let context = sharedBackgroundContext()
        persistentContainerQueue.addOperation() {
            context.performAndWait {
                do {
                    block(context)
                    
                    if (context.hasChanges) {
                        try context.save()
                    }
                    
                    DispatchQueue.main.async {
                        actionAfterSave()
                    }
                } catch {
                    let nsError = error as NSError
                    fatalError("saveContext() error: \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
}
