import Foundation


class ProfileObservableObject: ObservableObject {
    private let c: CoreDataInventory
    
    init(_ c: CoreDataInventory) {
        self.c = c
    }
}
