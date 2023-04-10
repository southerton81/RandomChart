import Foundation
import CoreData

final class CoreDataInventory {
    static let instance = CoreDataInventory()
    
    let persistentContainer: NSPersistentContainer
    let viewContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "Data")
        
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
    
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        viewContext = persistentContainer.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext = persistentContainer.newBackgroundContext()
    }
    
    /* Performs supplied block on a background managed object context and saves any resulting changes in CoreData */
    func performWrite(block: @escaping (_ context: NSManagedObjectContext) -> Void) async {
        await backgroundContext.perform {
            block(self.backgroundContext)
            
            if (self.backgroundContext.hasChanges) {
                do {
                    try self.backgroundContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("performWrite() error: \(nsError), \(nsError.userInfo)")
                }
            }
            
        }
    }
    
    /* Performs supplied block on a background managed object context returning its result */
    func performRead<T>(block: @escaping (_ context: NSManagedObjectContext) -> T) async -> T  {
        return await backgroundContext.perform {
            return block(self.backgroundContext)
        }
    } 
}
