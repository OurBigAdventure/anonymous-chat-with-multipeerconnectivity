//
//  Settings.swift
//  Chatter
//
//  Created by Chris Brown on 6/1/15.
//  Copyright (c) 2015 Chris Brown. All rights reserved.
//

import Foundation
import CoreData

@objc(Settings)
class Settings: NSManagedObject {

    @NSManaged var color: String
    @NSManaged var blocks: NSNumber

}
