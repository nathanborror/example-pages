//
//  AuthController.swift
//  Pages
//
//  Created by Nathan Borror on 10/9/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import UIKit

class AuthController: UINavigationController {
    
    let connectController = ConnectController()
    let registerController = RegisterController()
    
    var onRegister: ((_ name: String, _ email: String, _ password: String) -> Void)?
    var onConnect: ((_ identifier: String, _ password: String) -> Void)?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [self.connectController]
        
        let register = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(registerHit))
        connectController.navigationItem.rightBarButtonItem = register

        connectController.onSubmit = connectSubmit
        registerController.onSubmit = registerSubmit
    }
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerHit() {
        show(registerController, sender: self)
    }

    func registerSubmit(name: String, email: String, password: String) {
        onRegister?(name, email, password)
    }

    func connectSubmit(identifier: String, password: String) {
        onConnect?(identifier, password)
    }
}

class RegisterController: UIViewController, UITextFieldDelegate {

    let table = Table(style: .grouped)

    let nameField       = Field()
    let emailField      = Field()
    let passwordField   = Field()
    var submitButton    = Button()

    let nameCell        = UITableViewCell()
    let emailCell       = UITableViewCell()
    let passwordCell    = UITableViewCell()
    let submitCell      = UITableViewCell()

    var fields = [UITableViewCell]()

    var onSubmit: ((_ name: String, _ email: String, _ password: String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        table
            .dataSource(self)
            .frame(view.bounds)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .makeSubview(of: view)

        nameField
            .delegate(self)
            .placeholder("Name")
            .frame(nameCell.contentView.bounds, insets: nameCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .keyboard(returnKey: .next, autocorrect: .no, capitalization: .words)
            .makeSubview(of: nameCell.contentView)

        emailField
            .delegate(self)
            .placeholder("Email")
            .frame(emailCell.contentView.bounds, insets: emailCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .keyboard(keyboard: .emailAddress, returnKey: .next, autocorrect: .no, capitalization: .none)
            .makeSubview(of: emailCell.contentView)

        passwordField
            .delegate(self)
            .placeholder("Password")
            .frame(passwordCell.contentView.bounds, insets: passwordCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .keyboard(returnKey: .join, secure: true)
            .makeSubview(of: passwordCell.contentView)

        submitButton
            .title("Register")
            .frame(submitCell.contentView.bounds, insets: submitCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .align(.left)
            .addTarget(self, action: #selector(submitHit))
            .makeSubview(of: submitCell.contentView)

        fields = [nameCell, emailCell, passwordCell]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    func submitHit() {
        guard
            let name = nameField.text,
            let email = emailField.text,
            let password = passwordField.text
        else { return }
        onSubmit?(name, email, password)
        clear()
        view.endEditing(true)
    }

    func clear() {
        nameField.text = nil
        emailField.text = nil
        passwordField.text = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameField.textField: emailField.becomeFirstResponder()
        case emailField.textField: passwordField.becomeFirstResponder()
        default: submitHit()
        }
        return false
    }
}

extension RegisterController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return fields.count
        default: return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return fields[indexPath.row]
        default: return submitCell
        }
    }
}

class ConnectController: UIViewController, UITextFieldDelegate {
    
    let table = Table(style: .grouped)

    var identifierField = Field()
    var passwordField   = Field()
    var submitButton    = Button()
    
    let identifierCell  = UITableViewCell()
    let passwordCell    = UITableViewCell()
    let submitCell      = UITableViewCell()

    var fields = [UITableViewCell]()
    
    var onSubmit: ((_ identifier: String, _ password: String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        table
            .dataSource(self)
            .frame(view.bounds)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .makeSubview(of: view)

        identifierField
            .placeholder("Email")
            .delegate(self)
            .frame(identifierCell.contentView.bounds, insets: identifierCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .keyboard(keyboard: .emailAddress, returnKey: .next, autocorrect: .no, capitalization: .none)
            .makeSubview(of: identifierCell.contentView)

        passwordField
            .placeholder("Password")
            .delegate(self)
            .frame(passwordCell.contentView.bounds, insets: passwordCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .keyboard(returnKey: .done, secure: true)
            .makeSubview(of: passwordCell.contentView)

        submitButton
            .title("Connect")
            .frame(submitCell.contentView.bounds, insets: submitCell.separatorInset)
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .align(.left)
            .addTarget(self, action: #selector(submitHit))
            .makeSubview(of: submitCell.contentView)

        fields = [identifierCell, passwordCell]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        identifierField.becomeFirstResponder()
    }
    
    func submitHit() {
        guard
            let identifier = identifierField.textField.text,
            let password = passwordField.textField.text
        else { return }
        onSubmit?(identifier, password)
        clear()
        view.endEditing(true)
    }
    
    func clear() {
        identifierField.text = nil
        passwordField.text = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case identifierField.textField: passwordField.textField.becomeFirstResponder()
        default: submitHit()
        }
        return false
    }
}

extension ConnectController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return fields.count
        default: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: return fields[indexPath.row]
        default: return submitCell
        }
    }
}
