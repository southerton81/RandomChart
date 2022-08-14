import Foundation
import CoreData

class PersistentContainer {
    private var backgroundContext: NSManagedObjectContext?
    
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
        return persistentContainer.viewContext
    }
    
    func sharedBackgroundContext() -> NSManagedObjectContext {
        let newBackgroundContext = backgroundContext ?? persistentContainer.newBackgroundContext()
        backgroundContext = newBackgroundContext
        return newBackgroundContext
    }
    
    
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
