# CoreDataFDLeak
Code demonstrating a leak of file descriptors in iOS 10.0.1

# Summary
After mutating the fetchRequest on a fetchedResultsController, each save of the managed object context will open one or more file descriptors pointing to the sectionInfo cache file of the fetchedResultsController.
When hitting 255 open files, no new resources may be opened (on iOS devices), causing any subsequent opening of xib files, images, etc. to fail.

# Steps to Reproduce
1. Build the project in Xcode 8
2. Install on an iPad running iOS 10
3. Launch the app.
4. Tap 'Add Entity' a few times
5. Tap 'Mutate Fetch Request' once
6. Continue tapping 'Save Context (x 20)' until 255 file descriptors are open (they will be shown in a UITextView)
7. Tap 'Load Resource' - just to see that the loading of the resource will fail.
8. The force-unwrapping of the resource causes the app to crash. This is intentional to show problems that are likely to occur as a side effect of this issue.

# Expected Results
NSFetchedResultsController section cache does not leak file descriptors.

# Actual Results
NSFetchedResultsController section cache leaks file descriptors.

# Version
iOS 10.0.1

# Notes
This happens in simulator as well, but on MacOS you can open 1024 files without running into the issue.
This also happens with apps built using Xcode 7 but running on iOS 10.

# Configuration
iPad Pro 12.9 inc

# Only known workaround
Disable NSFetchedResultsController caching by supplying nil as the cache filename.
