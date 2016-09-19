//
//  ViewController.swift
//  CoreData-FetchedResultsController-FileDescriptor-Leak
//
//  Created by Morten Ditlevsen on 19/09/2016.
//  Copyright © 2016 Wallmob. All rights reserved.
//

import UIKit
import Darwin
import CoreData

let FD_SETSIZE: Int32 = 1024

func lsof() -> String {
    var flags: Int32
    let bufferSize = 1024
    var buffer = Array<UInt8>(repeating: 0, count: bufferSize)

    var n: Int = 1

    var openFilesArray: [String] = []

    for fd in 0..<FD_SETSIZE {
        errno = 0
        flags = fcntl(fd, F_GETFD, 0);
        if (flags == -1 && errno != 0) {
            if (errno != EBADF) {
                return ""
            }
            else {
                continue
            }
        }
        _ = fcntl(fd , F_GETPATH, &buffer )
        let output = NSString(bytes: &buffer, length: 1024, encoding: String.Encoding.utf8.rawValue)!

        let openFileText = "File Descriptor \(fd) number \(n) in use for: \(output)"
        openFilesArray.append(openFileText)
        n += 1
    }
    return openFilesArray.joined(separator: "\n")
}




class ViewController: UIViewController {

    var fetchedResultsController: NSFetchedResultsController<Entity>!

    let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

    @IBOutlet weak var openFilesTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSFetchRequest<Entity>(entityName: "Entity")
        request.sortDescriptors = [NSSortDescriptor(key: "attribute", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: "EntityCache")

        fetchedResultsController.delegate = self
        _ = try? fetchedResultsController.performFetch()


        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self

        refreshOpenFiles()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func refreshOpenFiles() {
        openFilesTextView.text = lsof()
    }

    @IBAction func addEntityButtonAction(_ sender: AnyObject) {
        let entity = Entity(context: moc)
        entity.attribute = "a"
        refreshOpenFiles()
    }

    @IBAction func loadResourceButtonAction(_ sender: AnyObject) {
        // Force unwrapping here to trigger crash when resource suddenly cannot be loaded
        let imageView = UIImageView(image: UIImage(named: "aaargh.gif")!)
        let viewController = UIViewController()
        viewController.view.addSubview(imageView)
        viewController.modalPresentationStyle = .formSheet
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.closeViewController))
        viewController.view.addGestureRecognizer(tapRecognizer)
        present(viewController, animated: true)
    }

    @objc func closeViewController() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func saveContextButtonAction(_ sender: AnyObject) {
        for _ in 0..<20 {
            do {
                _ = try moc.save()
            } catch {
                fatalError("Could not save context")
            }
        }
        refreshOpenFiles()
    }

    @IBAction func mutateFetchRequestButtonAction(_ sender: AnyObject) {
        fetchedResultsController.fetchRequest.predicate = NSPredicate(value: true)
        let cacheName: String = "EntityCache"
        NSFetchedResultsController<Entity>.deleteCache(withName: cacheName)
        _ = try? fetchedResultsController.performFetch()

        refreshOpenFiles()
    }
}

extension ViewController: UITableViewDelegate {

}

extension ViewController: UITableViewDataSource {
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        configureCell(cell: cell, forIndexPath: indexPath)
        return cell
    }

    func configureCell(cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
        let object = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = object.attribute
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = fetchedResultsController.sections?[section] else {
            return 0
        }
        return section.numberOfObjects
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {


    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break;
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell: cell, forIndexPath: indexPath)
                }
            }
            break;
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break;
        }
    }
}

