//
//  AppDelegate.swift
//  Pages
//
//  Created by Nathan Borror on 10/5/16.
//

import UIKit
import PageKit

class App {

    enum Endpoint: String {
        case dev = "https://localhost:8080/"
    }

    let window: UIWindow?
    var navigation: UINavigationController?
    
    let service: Service
    var state = State.initial
    
    init(window: UIWindow?) {
        self.service = Service(endpoint: Endpoint.dev.rawValue)
        self.window = window
        
        guard case .active = state else {
            viewAuth()
            return
        }
        viewHome()
    }
}

// Events

extension App {

    func handle(event: State.InputEvent) {
        switch state.handle(event: event) {
        case .activated?:
            DispatchQueue.main.async(execute: viewHome)

        case .deactivated?:
            DispatchQueue.main.async(execute: viewAuth)
            
        case .updated?:
            DispatchQueue.main.async {
                NotificationCenter.default.post(Notification(name: .onPagesUpdated))
            }

        case let .error(error)?:
            DispatchQueue.main.async {
                self.viewError(error: error)
            }
            
        case nil: break
        }
    }
}

// Actions

extension App {

    func register(name: String, email: String, password: String) {
        service.register(name: name, email: email, password: password) { result in
            do {
                let session = try result()
                self.handle(event: .activate(session))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }
    
    func connect(identifier: String, password: String) {
        service.connect(identifier: identifier, password: password) { result in
            do {
                let session = try result()
                self.handle(event: .activate(session))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }
    
    func logout() {
        handle(event: .deactivate)
    }
    
    func loadPages() {
        service.pageList { result in
            do {
                let pages = try result()
                self.handle(event: .update(pages.pages))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }

    func create(page text: String?) {
        guard case .active(let session, _) = self.state else {
            return
        }
        guard let text = text else {
            return
        }
        service.pageCreate(text: text, token: session.token) { result in
            do {
                let page = try result()
                self.handle(event: .update([page]))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }
    
    func update(page: Page, text: String?) {
        guard case .active(let session, _) = self.state else {
            return
        }
        guard let text = text else {
            return
        }
        service.pageUpdate(id: page.id, text: text, token: session.token) { result in
            do {
                let page = try result()
                self.handle(event: .update([page]))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }
    
    func delete(page: Page) {
        guard case .active(let session, _) = self.state else {
            return
        }
        service.pageDelete(id: page.id, token: session.token) { result in
            do {
                _ = try result()
                self.handle(event: .remove(page))
            } catch {
                self.handle(event: .error(error))
            }
        }
    }
}

// Views

extension App {

    func viewAuth() {
        let controller = AuthController()
        controller.onConnect = connect
        controller.onRegister = { name, email, password in
            self.register(name: name, email: email, password: password)
        }
        window?.rootViewController = controller
    }
    
    func viewHome() {
        guard case let .active(_, pages) = state else {
            viewAuth()
            return
        }
        
        let controller = ListController<PageCell, Page>()
        controller.configureCell = { cell, page in
            cell.textLabel?.text = page.text
        }
        controller.items = pages.map { $0.value }
        controller.onCreate = { self.viewForm() }
        controller.onRefresh = {
            guard case let .active(_, updatedPages) = self.state else {
                return pages
                    .map { $0.value }
                    .sorted { $0.created < $1.created }
            }
            return updatedPages
                .map { $0.value }
                .sorted { $0.created < $1.created }
        }
        
        navigation = UINavigationController(rootViewController: controller)
        window?.rootViewController = navigation
        
        loadPages()
    }

    func viewForm(page: Page? = nil) {
        let controller = FormController<Page>()
        controller.item = page
        controller.onCreate = create
        controller.onUpdate = update
        let controllerNav = UINavigationController(rootViewController: controller)
        navigation?.present(controllerNav, animated: true, completion: nil)
    }
    
    func viewError(error: Error?) {
        print(error)
    }
}

// Notifications

extension Notification.Name {

    static let onPagesUpdated = Notification.Name("OnPagesUpdatedNotification")
}

// App Delegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var app: App!
    var window: UIWindow?

    static let endpoint = URL(string: "https://localhost:8080")!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        app = App(window: window)
        
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()
        return true
    }
}

