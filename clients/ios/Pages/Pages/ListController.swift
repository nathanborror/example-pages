//
//  PagesController.swift
//  Pages
//
//  Created by Nathan Borror on 10/5/16.
//

import UIKit
import PageKit

class ListController<Cell: UITableViewCell, Item>: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let table = Table(style: .plain)
    
    var items = [Item]() { didSet { reload() }}
    
    var onCreate: (() -> Void)?
    var onUpdate: ((Item) -> Void)?
    var onDelete: ((Item) -> Void)?
    var onRefresh: (() -> [Item])?
    var onLogout: (() -> Void)?

    var configureCell: ((Cell, Item) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table
            .delegate(self)
            .dataSource(self)
            .frame(view.bounds)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .register(cell: Cell.self)
            .rowHeight(UITableViewAutomaticDimension)
            .estimatedRowHeight(44)
            .makeSubview(of: view)


        let create = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createHit))
        navigationItem.rightBarButtonItem = create
        
        let logout = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutHit))
        navigationItem.leftBarButtonItem = logout

        NotificationCenter.default.addObserver(self, selector: #selector(itemsUpdated), name: .onPagesUpdated, object: nil)
    }

    func createHit() {
        onCreate?()
    }
    
    func logoutHit() {
        onLogout?()
    }
    
    func reload() {
        table.reloadData()
    }

    func itemsUpdated() {
        guard let items = onRefresh?() else {
            return
        }
        self.items = items
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Table Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = table.dequeueReusable(cell: Cell.self) else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        configureCell?(cell, item)
        return cell
    }

    // Table Delegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let item = items[indexPath.row]
        var actions = [UITableViewRowAction]()
        
        if onDelete != nil {
            let action = UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
                self.onDelete?(item)
            }
            actions.append(action)
        }
        if onUpdate != nil {
            let action = UITableViewRowAction(style: .normal, title: "Edit") { _, _ in
                self.onUpdate?(item)
            }
            actions.append(action)
        }
        return actions
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
