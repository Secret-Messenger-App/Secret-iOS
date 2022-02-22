//
//  YapTaskQueueMasterBroker.swift
//  YapTaskQueue
//
//  Created by David Chiles on 4/5/16.
//  Copyright © 2016 David Chiles. All rights reserved.
//

import Foundation
import YapDatabase


///Only create one of these per database. This is required to filter out all the available actoins. The queue is managed in YapTaskQueueBroker
open class YapTaskQueueMasterBroker:YapDatabaseAutoView {
    
    @objc public convenience init(options:YapDatabaseViewOptions?) {
        
        let grouping = YapDatabaseViewGrouping.withObjectBlock { (transaction, collection, key, object) -> String? in
            guard let actionObject = object as? YapTaskQueueAction else {
                return nil
            }
            return actionObject.queueName()
        }
        
        let sorting = YapDatabaseViewSorting.withObjectBlock { (transaction, group, collection1, key1, object1, collection2, key2, object2) -> ComparisonResult in
            guard let actionObject1 = object1 as? YapTaskQueueAction else {
                return .orderedSame
            }
            guard let actionObject2 = object2 as? YapTaskQueueAction else {
                return .orderedSame
            }
            
            return actionObject1.sort(actionObject2)
        }
        
        self.init(grouping: grouping, sorting: sorting, versionTag: nil, options: options)
    }
    
}
