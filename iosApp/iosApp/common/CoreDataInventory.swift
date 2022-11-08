import Foundation
import CoreData

final class CoreDataInventory {
    static let instance = CoreDataInventory()
    
    let persistentContainer: NSPersistentContainer
    let viewContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "Data")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        viewContext = persistentContainer.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
    }
    
    /* Performs supplied block on a background managed object context
       and saves possible changes */
    func perform(block: @escaping (_ context: NSManagedObjectContext) -> Void) async {
        await backgroundContext.perform {
            do {
                block(self.backgroundContext)
                
                if (self.backgroundContext.hasChanges) {
                    try self.backgroundContext.save()
                }
            } catch {
                let nsError = error as NSError
                fatalError("saveContext() error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
