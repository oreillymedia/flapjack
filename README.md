# Flapjack

Flapjack is an iOS/macOS/tvOS framework with 2 primary goals.

1. Help you abstract your model-focused database persistence layer from the rest of your app
2. Simplify the database layer's API into an easy-to-use, easy-to-remember, full Swift one

It lets you _skip_ the boilerplate commonly associated with database layers like Core Data and lets you introduce structured, sane data persistence in your app _sooner_, letting you spend more of your time creating the app you really want. We use it at [O'Reilly Media][orm] and [Safari Books Online][sbo] for our iOS apps, and if you like what you see, perhaps you will too.


## Getting started

Flapjack will soon be available through [CocoaPods][cpd]. To install it for now, simply add the following line to your Podfile:

```ruby
pod 'Flapjack', git: 'https://github.com/oreillymedia/flapjack.git', tag: '0.1.0'
# If you're using Core Data...
pod 'Flapjack/CoreData', git: 'https://github.com/oreillymedia/flapjack.git', tag: '0.1.0'
# If you're targeting iOS and want some helpers...
pod 'Flapjack/UIKit', git: 'https://github.com/oreillymedia/flapjack.git', tag: '0.1.0'
```

And run `pod install` at the command line. Then in your iOS project (like perhaps in your `UIApplicationDelegate`), kick things off with the following code (if you're using Core Data; support for more databases planned).

```swift
import Flapjack

// Create the DataAccess object, your main point-of-entry for persistence.
// You can also pass in `.sql(filename: "YourCoreDataStore.sql")`.
let dataAccess = CoreDataAccess(name: "YourCoreDataStore", type: .memory)

// Then tell the stack to configure itself.
dataAccess.prepareStack(asynchronously: true) { error in
    if let error = error {
        print(error.localizedDescription)
    }

    // Make sure you retain your `dataAccess` variable, and now you're all
    //   ready to go!
}
```

Note: support for Swift Package Manager and Carthage are forthcoming.


## Usage

Full documentation is forthcoming, but here's a good thorough run-through of what Flapjack has to offer.

For your model objects to take part in the simplified API provided by Flapjack, you'll need to make sure they conform to `DataObject`. [For a class such as `Pancake`][pcm] that has the fields `identifier`, `flavor`, and `radius` defined in a Core Data model, this would look like the following.

```swift
extension Pancake: DataObject {
    // The type of your primary key, if you have one of your own.
    public typealias PrimaryKeyType = String
    // The name of the entity as Core Data knows it.
    public static var representedName: String {
        return "Pancake"
    }
    // The key path to your model's primary key.
    public static var primaryKeyPath: String {
        return #keyPath(identifier)
    }
    // An array of sorting criteria.
    public static var defaultSorters: [SortDescriptor] {
        return [
            SortDescriptor(#keyPath(flavor), ascending: true, caseInsensitive: true),
            SortDescriptor(#keyPath(radius), ascending: false)
        ]
    }
}
```

Now you're cookin'. Interacting with the data store is even easier.

```swift
// Get every pancake.
let pancakes = dataAccess.mainContext.objects(ofType: Pancake.self)
// Get just the chocolate chip ones.
let pancakes = dataAccess.mainContext.objects(ofType: Pancake.self, attributes: ["flavor": "Chocolate Chip"])
// Create your own.
let pancake = dataAccess.mainContext.create(Pancake.self, attributes: ["flavor": "Rhubarb"])
// Save your changes.
let error = context.persist()
```

Granted you don't want to do expensive data operations on the main thread. Flapjack's Core Data support follows best practices for such a thing:

```swift
dataAccess.performInBackground { [weak self] context in
    let pancake = context.create(Pancake.self, attributes: ["flavor": flavor, "radius": radius, "height": height])
    let error = context.persist()

    DispatchQueue.main.async {
        guard let `self` = self else {
            return
        }
        let foregroundPancake = self.dataAccess.mainContext.object(ofType: Pancake.self, objectID: pancake.objectID)
        completion(foregroundPancake, error)
    }
}
```

Sick of your database? There's a function for that, too.

```swift
dataAccess.deleteDatabase(rebuild: true) { error in
    if let error = error {
        print(error.localizedDescription)
    }

    // It's almost as if it never happened.
}
```


## Data sources

This wouldn't be nearly as much fun if Flapjack didn't provide a way to automatically listen for model changes. The `DataSource` and `SingleDataSource` protocols define a way to listen for changes on a collection of persisted objects _or_ a single object, respectively. If you're targeting Core Data, the two implementations of those protocols (`CoreDataSource` and `CoreSingleDataSource`) are powered by `NSFetchResultsController` and listening to `.NSManagedObjectContextObjectsDidChange`, respectively.

```swift
import Flapjack

let dataSourceFactory = CoreDataSourceFactory(dataAccess: dataAccess)
let queryAttributes = ["radius": 2.0, "flavor": "Chocolate Chip"]
let dataSource: CoreDataSource<Pancake> = dataSourceFactory.vendObjectsDataSource(attributes: queryAttributes, sectionProperty: "flavor", limit: 100)

// Prepare yourself for pancakes, but only chocolate chip ones bigger than a 2" radius, and no more than 100.
// This block fires every time the data source picks up an insert/change/deletion.
dataSource.onChange = { itemChanges, sectionChanges in
	// If you've added `Flapjack/UIKit` to your Podfile, you get helper extensions!
	self.tableView.performBatchUpdates(itemChanges, sectionChanges: sectionChanges)

	// Get a specific pancake:
	print("\(String(describing: dataSource.object(at: IndexPath(item: 0, section: 0))))")
}

// Kick off a call to start listening (and immediately fire `.onChange` with all existing results).
dataSource.execute()
```

For a more complete example on how to use `CoreDataSource`, see [AutomaticViewController.swift][avc]. To see the steps you'd have to go through to access stored data _without_ it, see [ManualViewController.swift][mvc].


## Authors

- Ben Kreeger ([@kreeger][krg])


## License

Flapjack is available under the MIT license. See [LICENSE][lic] file for more info.


[orm]:     https://oreilly.com
[sbo]:     https://safaribooksonline.com
[cpd]:     https://cocoapods.org
[pcm]:     https://github.com/oreillymedia/flapjack/blob/master/Example/Flapjack/Core%20Data/Pancake.swift
[avc]:     https://github.com/oreillymedia/flapjack/blob/master/Example/Flapjack/AutomaticViewController.swift
[mvc]:     https://github.com/oreillymedia/flapjack/blob/master/Example/Flapjack/ManualViewController.swift
[krg]:     https://github.com/kreeger
[lic]:     https://github.com/oreillymedia/flapjack/blob/master/LICENSE