//
//  ViewController.swift
//  YapTaskQueue
//
//  Created by David Chiles on 3/31/16.
//  Copyright © 2016 David Chiles. All rights reserved.
//

import UIKit

class MessageSendAction:NSObject, NSCoding, YapTaskQueueAction {
    let key:String
    let collection:String
    let messageToSendKey:String
    let messagetoSendCollection:String
    let queue:String
    let date:Date
    
    init(key:String, collection:String, messageToSendKey:String,messagetoSendCollection:String, queue:String, date:Date) {
        self.key = key
        self.collection = collection
        self.messageToSendKey = messageToSendKey
        self.messagetoSendCollection = messagetoSendCollection
        self.queue = queue
        self.date = date
    }
    
    //MARK: YapTaskQueueAction
    func yapKey() -> String {
        return self.key
    }
    
    func yapCollection() -> String {
        return self.collection
    }
    
    func queueName() -> String {
        return self.queue
    }
    
    func sort(_ otherObject: YapTaskQueueAction) -> ComparisonResult {
        guard let otherAction = otherObject as? MessageSendAction else {
            return .orderedSame
        }
        
        return self.date.compare(otherAction.date)
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.key, forKey: "key")
        aCoder.encode(self.collection, forKey: "collection")
        aCoder.encode(self.messageToSendKey, forKey: "messageToSendKey")
        aCoder.encode(self.messagetoSendCollection, forKey: "messagetoSendCollection")
        aCoder.encode(self.queue, forKey: "queue")
        aCoder.encode(self.date, forKey: "date")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let key = aDecoder.decodeObject(forKey: "key") as? String,
        let collection = aDecoder.decodeObject(forKey: "collection") as? String,
        let messageToSendKey = aDecoder.decodeObject(forKey: "messageToSendKey") as? String,
        let messagetoSendCollection = aDecoder.decodeObject(forKey: "messagetoSendCollection") as? String,
        let queue = aDecoder.decodeObject(forKey: "queue") as? String,
        let date = aDecoder.decodeObject(forKey: "date") as? Date
            else {
                return nil
        }
        
        self.init(key:key,collection: collection, messageToSendKey: messageToSendKey, messagetoSendCollection: messagetoSendCollection, queue: queue, date: date)
    }
}

class MessageHandler:YapTaskQueueHandler {
    
    @objc func handleNextItem(_ action: YapTaskQueueAction, completion: @escaping (_ success: Bool, _ retryTimeout: TimeInterval) -> Void) {
        guard action is MessageSendAction else {
            completion(false, -1)
            return
        }
        
        /**
         1. Get the 'real' message out of the database
         2. Send the message over the wire
         3. get result
        */
        
        let result = true
        /**
        If the sending was successful then return true and it doesn't matter what you set the `retryTimeout` to
        If the sedning was not successful then send bask false and when you want to retry
         It's also possible to set the retry timeout to -1 if you don't want a timed retry but would rather manually retry when the conditions are more likely to result in a success
        
        completion(success: result, retryTimeout: 5)
        */
        completion(result, -1)
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

