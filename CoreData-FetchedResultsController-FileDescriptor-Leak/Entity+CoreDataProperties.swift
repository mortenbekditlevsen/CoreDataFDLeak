//
//  Entity+CoreDataProperties.swift
//  CoreData-FetchedResultsController-FileDescriptor-Leak
//
//  Created by Morten Ditlevsen on 19/09/2016.
//  Copyright © 2016 Wallmob. All rights reserved.
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity");
    }

    @NSManaged public var attribute: String?

}
