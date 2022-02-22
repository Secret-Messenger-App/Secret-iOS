# YapTaskQueue [![Build Status](https://travis-ci.org/davidchiles/YapTaskQueue.svg?branch=master)](https://travis-ci.org/davidchiles/YapTaskQueue)
A persistent serial queue based on [YapDatabase](https://github.com/yapstudios/YapDatabase).

## Use

### Setup

To setup create a handler and then register the handler with a name. Then in the block return if a given queueName is handled by this handler. If a queue is registered to multiple handler this will result in unpredictable behavior because they may both start the action but completion may complete with different results.

```swift
  let database = YapDatabase(path: path)
  let handler = //Some object that conforms to YapTaskQueueHandler
  let broker = try! YapTaskQueueBroker.setupWithDatabase(database, name: "handler1", handler: handler) { (queueName) -> Bool in
            // return true here if it's a queue that this handler understands and 'handles'
            return true
        }
  // Or instead of checking the queue name in a closure you can just use the broker name as the prefix to a queue.
  // So in this case any actionItem that returns a queue starting with "handler1" like "handler1-queue2"

  let broker = try! YapTaskQueueBroker.setupWithDatabase(database, name: "handler1", handler: handler)

```

### Creating an action

An action object should only hold the minimal information necessary for the corresponding `YapTaskQueueHandler` to know what to do if it's instructed to handle it.

Example

This is what a simple message send action might look like
```swift
class MessageSendAction:NSObject, NSCoding, YapTaskQueueAction {
    let key:String
    let collection:String
    let messageToSendKey:String
    let messagetoSendCollection:String
    let queue:String
    let date:NSDate

    init(key:String, collection:String, messageToSendKey:String,messagetoSendCollection:String, queue:String, date:NSDate) {
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

    func sort(otherObject: YapTaskQueueAction) -> NSComparisonResult {
        guard let otherAction = otherObject as? MessageSendAction else {
            return .OrderedSame
        }

        return self.date.compare(otherAction.date)
    }

    //MARK: NSCoding

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.key, forKey: "key")
        aCoder.encodeObject(self.collection, forKey: "collection")
        aCoder.encodeObject(self.messageToSendKey, forKey: "messageToSendKey")
        aCoder.encodeObject(self.messagetoSendCollection, forKey: "messagetoSendCollection")
        aCoder.encodeObject(self.queue, forKey: "queue")
        aCoder.encodeObject(self.date, forKey: "date")
    }

    required convenience init?(coder aDecoder: NSCoder) {
        guard let key = aDecoder.decodeObjectForKey("key") as? String,
        let collection = aDecoder.decodeObjectForKey("collection") as? String,
        let messageToSendKey = aDecoder.decodeObjectForKey("messageToSendKey") as? String,
        let messagetoSendCollection = aDecoder.decodeObjectForKey("messagetoSendCollection") as? String,
        let queue = aDecoder.decodeObjectForKey("queue") as? String,
        let date = aDecoder.decodeObjectForKey("date") as? NSDate
            else {
                return nil
        }

        self.init(key:key,collection: collection, messageToSendKey: messageToSendKey, messagetoSendCollection: messagetoSendCollection, queue: queue, date: date)
    }
}
```

Here's a rough outline of a message handler:
```swift
class MessageHandler:YapTaskQueueHandler {

    var databaseConnection:YapDatabaseConnection?

    func handleNextItem(action: YapTaskQueueAction, completion: (success: Bool, retryTimeout: NSTimeInterval) -> Void) {
        guard let messageAction = action as? MessageSendAction else {
            completion(success: false, retryTimeout: -1)
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
        If the sending was not successful then send bask false and when you want to retry
        It's also possible to set the retry timeout to -1 if you don't want a timed retry but would rather manually retry when the conditions are more likely to result in a success

        completion(success: result, retryTimeout: 5)
        */
        completion(success: result, retryTimeout: -1)
    }
}
```

Once the broker and hanlder are setup with the database just by saving an action it will be processed in the queue. It's not recomended to remove an action from within the handler. Rather when an action is completed as successful then the broker removes the action from the database and checks for remaining actions.
