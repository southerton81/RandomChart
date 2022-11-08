import XCTest
import CoreData
@testable import iosApp

class iosAppTests: XCTestCase {
    
    func testCoreDataMergeConflict() {
        let expectation = XCTestExpectation(description: "")
        expectation.expectedFulfillmentCount = 2
        
        Task {
            await CoreDataInventory.instance.perform { (context) in
                let newChartState = ChartState(context: context)
                newChartState.chartLen = 100
                newChartState.seed = 1
            }
        }
        
        Task {
            await CoreDataInventory.instance.perform { (context) in
                sleep(1)
                self.modifyChartStateSeed(context, 2)
                sleep(1) // Wait 1 seconds before save for the next background task to read the same version of entity
            }
            expectation.fulfill()
        }
        
        Task {
            await CoreDataInventory.instance.perform { (context) in
                sleep(1)
                self.modifyChartStateSeed(context, 3)
                sleep(2)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 8)
    }
    
    private func modifyChartStateSeed(_ context: NSManagedObjectContext, _ seed: Int32) {
        let fetchRequest: NSFetchRequest<ChartState> = ChartState.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "chartLen = %i", 100)
        let chartStateEntity = try? context.fetch(fetchRequest).first
        chartStateEntity?.seed = seed
    }
    
    private func test(_ c: CoreDataInventory) async {
        await c.perform(block: { c in
            sleep(3)
            print("test ", Thread.current)
            
        })
    }
    
    func testCoreDataBackgroundContext() {
        let expectation = XCTestExpectation(description: "Should take ~9 seconds")
        expectation.expectedFulfillmentCount = 3
        
        let coreDataInventory = CoreDataInventory.instance
        let options = XCTMeasureOptions()
        options.iterationCount = 0
        
        self.measure(options: options) {
            Task {
                print("Task 1 start", Thread.current)
                await test(coreDataInventory)
                print("Task 1 end ")
                expectation.fulfill()
            }
            
            Task {
                print("Task 2 start", Thread.current)
                await test(coreDataInventory)
                print("Task 2 end ")
                expectation.fulfill()
            }
            
            Task {
                print("Task 3 start", Thread.current)
                await test(coreDataInventory)
                print("Task 3 end ")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 12)
        }
    }
}
