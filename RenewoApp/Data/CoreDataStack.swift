import CoreData
import Foundation

final class CoreDataStack {
    enum StoreType {
        case persistent
        case inMemory
    }

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init(
        modelName: String = "Renewo",
        storeType: StoreType = .persistent,
        bundle: Bundle = Bundle(for: CoreDataStack.self)
    ) {
        let model = Self.loadModel(named: modelName, bundle: bundle)
        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)

        let description: NSPersistentStoreDescription
        if storeType == .inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description = persistentContainer.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        }

        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        persistentContainer.persistentStoreDescriptions = [description]

        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                assertionFailure("Core Data store failed to load: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func inMemory(modelName: String = "Renewo") -> CoreDataStack {
        CoreDataStack(modelName: modelName, storeType: .inMemory)
    }

    private static func loadModel(named name: String, bundle: Bundle) -> NSManagedObjectModel {
        if let url = bundle.url(forResource: name, withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: url) {
            return model
        }

        if let model = NSManagedObjectModel.mergedModel(from: [bundle]) {
            return model
        }

        if let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) {
            return model
        }

        assertionFailure("Failed to load Core Data model: \(name)")
        return NSManagedObjectModel()
    }
}
