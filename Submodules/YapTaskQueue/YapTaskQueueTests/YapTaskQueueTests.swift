//
//  YapTaskQueueTests.swift
//  YapTaskQueueTests
//
//  Created by David Chiles on 3/31/16.
//  Copyright © 2016 David Chiles. All rights reserved.
//

import XCTest
import YapDatabase
@testable import YapTaskQueue

fileprivate extension Double {
    static var max: Double {
        return Double.greatestFiniteMagnitude
    }
}

class TestActionObject:NSObject, YapTaskQueueAction, NSCoding, NSCopying {
    var key:String
    var collection:String
    
    var name:String
    var queue:String
    var date = Date()
    
    init(key:String, collection:String, name:String, queue:String) {
        self.key = key
        self.collection = collection
        self.name = name
        self.queue = queue
    }
    
    func yapKey() -> String {
        return self.key
    }
    
    func yapCollection() -> String {
        return self.collection
    }
    
    func sort(_ otherObject: YapTaskQueueAction) -> ComparisonResult {
        guard let otherAction = otherObject as? TestActionObject else {
            return .orderedSame
        }
        return self.date.compare(otherAction.date)
    }
    
    func queueName() -> String {
        return self.queue
    }
    
    ///NSCopying
    func copy(with zone: NSZone?) -> Any {
        let copy = TestActionObject(key: self.key, collection: self.collection, name: self.name, queue: self.queue)
        copy.date = self.date
        return copy
    }
    
    ///NSCoding
    internal func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: "name")
        aCoder.encode(self.queue, forKey: "queue")
        aCoder.encode(self.date, forKey: "date")
        aCoder.encode(self.key, forKey: "key")
        aCoder.encode(self.collection, forKey: "collection")
    }
    
    internal required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let queue = aDecoder.decodeObject(forKey: "queue") as! String
        let date = aDecoder.decodeObject(forKey: "date") as! Date
        let key = aDecoder.decodeObject(forKey: "key") as! String
        let collection = aDecoder.decodeObject(forKey: "collection") as! String
        
        self.init(key:key, collection: collection, name: name, queue: queue)
        self.date = date
    }
}

open class TestHandler:YapTaskQueueHandler {
    
    var handleBlock:(_ action:TestActionObject) -> (Bool,TimeInterval)
    var connection:YapDatabaseConnection?
    
    init(handleBlock:@escaping (TestActionObject) -> (Bool,TimeInterval)) {
        self.handleBlock = handleBlock
    }
    
    @objc open func handleNextItem(_ action: YapTaskQueueAction, completion: @escaping (_ success: Bool, _ retryTimeout: TimeInterval) -> Void) {
    
        guard let testObject = action as? TestActionObject  else {
            completion(false, Double.max)
            return
        }
        
        let (result,retryTimout) =  self.handleBlock(testObject)
        completion(result, retryTimout)
    }
}

func deleteFiles(_ url:URL) {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions(), errorHandler: nil)
    while let file = enumerator?.nextObject() as? URL {
        try! fileManager.removeItem(at: file)
    }
}

func createDatabase(_ suffix:String) -> YapDatabase {
    let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
    
    let baseDir = URL(fileURLWithPath: paths.first ?? NSTemporaryDirectory())
    deleteFiles(baseDir)
    let file = URL(fileURLWithPath: #file).lastPathComponent.components(separatedBy: ".").first!
    let name = "\(file)-\(suffix).sqlite"
    let path = baseDir.appendingPathComponent(name).path
    // Setup datbase
    return YapDatabase(path: path)
}

func setupDatabase(_ suffix:String) -> YapDatabase {
    let database = createDatabase(suffix)
    
    // Setup Extension
    let options = YapDatabaseViewOptions()
    let master = YapTaskQueueMasterBroker(options: options)
    database.register(master, withName: "master")
    return database
}

class YapTaskQueueTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {

        super.tearDown()
    }
    
    func setupQueue(_ database:YapDatabase, handler:TestHandler, actionCount:Int, name:String) {
        let connection = database.newConnection()
        let ext = YapTaskQueueBroker(parentViewName: "master", handler: handler, filtering: { (threadName) -> Bool in
            return threadName == name
        })
        database.register(ext, withName: "broker-\(name)")
        
        connection.asyncReadWrite({ (transaction) in
            for actionIndex in 0..<actionCount {
                let actionName = "\(actionIndex)"
                let action = TestActionObject(key: actionName, collection: "collection\(name)", name: actionName, queue: name)
                
                transaction.setObject(action, forKey: action.key, inCollection: action.collection)
                
            }
        })
    }
    
    func testMoveFromOneQueueToAnother() {
        let database = createDatabase(#function)
        let connection = database.newConnection()
        let expectation = self.expectation(description: #function)
        
        let firstHanlder = TestHandler { (action) -> (Bool,TimeInterval) in
            let newAction = action.copy() as! TestActionObject
            newAction.key = "newKey"
            newAction.queue = "handler2-queue"
            connection.readWrite({ (transaction) in
                transaction.setObject(newAction, forKey: newAction.yapKey(), inCollection: newAction.yapCollection())
            })
            return (true,0)
        }
        let secondHandler = TestHandler { (action) -> (Bool,TimeInterval) in
            expectation.fulfill()
            return (true,0)
        }
        let handler1 = try! YapTaskQueueBroker.setupWithDatabase(database, name: "handler1", handler: firstHanlder)
        _ = try! YapTaskQueueBroker.setupWithDatabase(database, name: "handler2", handler: secondHandler)
        let queueName = try! handler1.queueNameWithSuffix("queue")
        let action = TestActionObject(key: "key", collection: "collection", name: "name", queue:queueName)
        connection.readWrite { (transaction) in
            transaction.setObject(action, forKey: action.yapKey(), inCollection: action.yapCollection())
        }
        
        
        self.waitForExpectations(timeout: 10, handler: nil)
        
    }
    
    func testOneAction() {
        let database  = setupDatabase(#function)
        let expectation = self.expectation(description: "test one action")
        
        let handler = TestHandler { (action) -> (Bool,TimeInterval) in
            print("\(action.name) - \(action.date)")
            expectation.fulfill()
            return (true,0)
        }
        handler.connection = database.newConnection()
        
        let ext = YapTaskQueueBroker(parentViewName: "master", handler: handler, filtering: { (threadName) -> Bool in
            return true
            })
        database.register(ext, withName: "broker")
        
        database.newConnection().readWrite({ (transaction) in
            let action = TestActionObject(key: "key", collection: "collection", name: "name", queue: "default")
            transaction .setObject(action, forKey: action.key, inCollection: action.collection)
        })
        
        self.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testMultipleActionsOneThread() {
        let database  = setupDatabase(#function)
        var currentCount = 0
        let count = 10
        let expectation = self.expectation(description: "testMultipleActionsOneThread")
        let handler = TestHandler { (action) -> (Bool,TimeInterval) in
            
            let nameInt = Int(action.name)
            print("\(currentCount) \(String(describing: nameInt))")
            XCTAssert(currentCount == nameInt,"Expect Item: \(currentCount) - Recieved: \(nameInt!)")
            
            
            if (count-1 == currentCount) {
                expectation.fulfill()
            }
            currentCount += 1
            return (true,0)
        }
        handler.connection = database.newConnection()
        
        let connection = database.newConnection()
        
        
        let ext = YapTaskQueueBroker(parentViewName: "master", handler: handler, filtering: { (queueName) -> Bool in
            return true
        })
        database.register(ext, withName: "broker")
        
        for index in 0..<count {
            let name = "\(index)"
            let action = TestActionObject(key: name, collection: "collection", name: name, queue: "default")
            connection.asyncReadWrite({ (transaction) in
                transaction.setObject(action, forKey: action.key, inCollection: action.collection)
            })
        }
        
        self.waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testSteup() {
        let database = createDatabase(#function)
        let handler = TestHandler { (action) -> (Bool,TimeInterval) in
            return (true,0)
        }
        let broker = try! YapTaskQueueBroker.setupWithDatabase(database, name: "queue1", handler: handler)
        XCTAssertNotNil(broker,"Error Setting up database")
        let ext = database.registeredExtension("queue1")
        XCTAssertNotNil(ext,"No extension registered")
    }
    
    func testMultipleActionsMultipleThreads () {
        let database = setupDatabase(#function)
        let threadCount = 5
        for threadIndex in 0..<threadCount {
            let expectation = self.expectation(description: "test Multiple \(threadIndex)")
            let actionCount = (threadIndex+1) * 5
            var currentCount = 0
            let handler = TestHandler(handleBlock: { (action) -> (Bool,TimeInterval) in
                let actionNumber = Int(action.name)!
                print("\(threadIndex): \(currentCount) - \(actionNumber)")
                XCTAssertEqual(currentCount, actionNumber,"\(threadIndex): \(currentCount) - \(actionNumber)")
                
                if (actionCount-1 == currentCount) {
                    expectation.fulfill()
                }
                
                currentCount+=1
                
                return (true,0)
            })
            
            self.setupQueue(database, handler: handler, actionCount: actionCount, name: "\(threadIndex)")
        }
        
        self.waitForExpectations(timeout: 1000, handler: nil)
        
    }
    
    func testPausingAction() {
        let expectation = self.expectation(description: #function)
        let database = setupDatabase(#function)
        
        var count = 0
        
        // This handler waits to be called a second time in order to fulfill the expectation. 
        // The first time through it returns that the action failed and it should wait an indefinite amount of time before restarting the task.
        let startDate = Date()
        let delay = 2.0
        let handler = TestHandler { (action) -> (Bool, TimeInterval) in
            print("handled \(count)")
            
            count += 1
            if (count == 2) {
                let timeDifference = abs(startDate.timeIntervalSinceNow)
                XCTAssertEqual(timeDifference, delay, accuracy: 0.5)
                expectation.fulfill()
            }
            return (false,Double.max)
        }
        //Setup the queue with one action
        self.setupQueue(database, handler: handler, actionCount: 1, name: "queue")
        
        // After 2 seconds (should be enough time for the action to fail the first time) we tryto restart the queue if it has a paused action.
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        let queue = DispatchQueue.global()
        queue.asyncAfter(deadline: time) { 
            if let queue = database.registeredExtension("broker-queue") as? YapTaskQueueBroker {
                queue.restartQueueIfPaused("queue")
            }
        }
        
        self.waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testPausingActionWithTimeout() {
        let expectation = self.expectation(description: #function)
        let database = setupDatabase(#function)
        let delay = 3.0
        let startDate = Date()
        var count = 0
        let handler = TestHandler { (action) -> (Bool, TimeInterval) in
            count += 1
            
            //After the first one fails once it then succeeds
            if count == 2 {
                let timeDifference = abs(startDate.timeIntervalSinceNow)
                
                XCTAssertEqual(timeDifference, delay, accuracy: 0.5)
                return (true,0)
            }
            // This is the third time through so we're done with the test
            else if (count == 3) {
                
                expectation.fulfill()
            }
            
            return(false,delay)
        }
        
        self.setupQueue(database, handler: handler, actionCount: 2, name: "queue")
        
        
        self.waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testDeletingAction() {
        let expectation = self.expectation(description: #function)
        let database = setupDatabase(#function)
        let handler = TestHandler { (action) -> (Bool, TimeInterval) in
            if action.name == "0" {
                return (false,10)
            } else if action.name == "1" {
                expectation.fulfill()
                return (true,0)
            }
            XCTAssert(false)
            return (false,-1)
        }
        
        self.setupQueue(database, handler: handler, actionCount: 2, name: "queue")
        let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) { 
            database.newConnection().readWrite({ (transaction) in
                transaction.removeObject(forKey: "0", inCollection: "collectionqueue")
            })
        }
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testDeleteingAndAddingAction() {
        let expectation = self.expectation(description: #function)
        let database = setupDatabase(#function)
        var count = 0;
        var act:TestActionObject? = nil
        let handler = TestHandler { (action) -> (Bool, TimeInterval) in
            count += 1
            
            if count == 1 {
                act = action
                return (false, 10)
            }
            expectation.fulfill()
            return (true,0)
        }
        
        self.setupQueue(database, handler: handler, actionCount: 1, name: "queue")
        let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            database.newConnection().readWrite({ (transaction) in
                transaction.removeObject(forKey: act!.key, inCollection: act!.collection)
            })
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                database.newConnection().readWrite({ (transaction) in
                    
                    transaction.setObject(act, forKey: act!.key, inCollection: act!.collection)
                })
            }
            
        }
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
