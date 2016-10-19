//
//  Extensions.swift
//  Pages
//
//  Created by Nathan Borror on 10/9/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import UIKit

class Field {

    var textField: UITextField

    init() {
        textField = UITextField()
    }

    var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    @discardableResult
    func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    func delegate(_ delegate: UITextFieldDelegate) -> Self {
        textField.delegate = delegate
        return self
    }

    @discardableResult
    func placeholder(_ text: String) -> Self {
        textField.placeholder = text
        return self
    }

    @discardableResult
    func frame(_ frame: CGRect, insets: UIEdgeInsets = .zero) -> Self {
        textField.frame = UIEdgeInsetsInsetRect(frame, insets)
        return self
    }

    @discardableResult
    func autoresizingMask(_ resizing: UIViewAutoresizing) -> Self {
        textField.autoresizingMask = resizing
        return self
    }

    @discardableResult
    func keyboard(keyboard: UIKeyboardType = .default,
                           returnKey: UIReturnKeyType = .default,
                           autocorrect: UITextAutocorrectionType = .default,
                           capitalization: UITextAutocapitalizationType = .sentences,
                           secure: Bool = false) -> Self {
        textField.keyboardType = keyboard
        textField.returnKeyType = returnKey
        textField.autocorrectionType = autocorrect
        textField.autocapitalizationType = capitalization
        textField.isSecureTextEntry = secure
        return self
    }

    @discardableResult
    func makeSubview(of view: UIView) -> Self {
        view.addSubview(textField)
        return self
    }
}

class Text {

    var textView: UITextView

    init() {
        textView = UITextView()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.font = UIFont.preferredFont(forTextStyle: .body)
    }

    var text: String? {
        get { return textView.text }
        set { textView.text = newValue }
    }

    @discardableResult
    func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    @discardableResult
    func delegate(_ delegate: UITextViewDelegate) -> Self {
        textView.delegate = delegate
        return self
    }

    @discardableResult
    func frame(_ frame: CGRect, insets: UIEdgeInsets = .zero) -> Self {
        textView.frame = UIEdgeInsetsInsetRect(frame, insets)
        return self
    }

    @discardableResult
    func autoresizingMask(_ resizing: UIViewAutoresizing) -> Self {
        textView.autoresizingMask = resizing
        return self
    }

    @discardableResult
    func makeSubview(of view: UIView) -> Self {
        view.addSubview(textView)
        return self
    }
}

class Table {

    var tableView: UITableView

    init(style: UITableViewStyle) {
        tableView = UITableView(frame: .zero, style: style)
    }

    @discardableResult
    func dataSource(_ dataSource: UITableViewDataSource) -> Self {
        tableView.dataSource = dataSource
        return self
    }

    @discardableResult
    func delegate(_ delegate: UITableViewDelegate) -> Self {
        tableView.delegate = delegate
        return self
    }

    @discardableResult
    func frame(_ frame: CGRect, insets: UIEdgeInsets = .zero) -> Self {
        tableView.frame = UIEdgeInsetsInsetRect(frame, insets)
        return self
    }

    @discardableResult
    func autoresizingMask(_ resizing: UIViewAutoresizing) -> Self {
        tableView.autoresizingMask = resizing
        return self
    }

    @discardableResult
    func register(cell: UITableViewCell.Type) -> Self {
        tableView.register(cell, forCellReuseIdentifier: String(describing: cell))
        return self
    }

    @discardableResult
    func makeSubview(of view: UIView) -> Self {
        view.addSubview(tableView)
        return self
    }

    @discardableResult
    func rowHeight(_ height: CGFloat) -> Self {
        tableView.rowHeight = height
        return self
    }

    @discardableResult
    func estimatedRowHeight(_ height: CGFloat) -> Self {
        tableView.estimatedRowHeight = height
        return self
    }

    func reloadData() {
        tableView.reloadData()
    }

    func dequeueReusable<T: UITableViewCell>(cell: T.Type) -> T? {
        return tableView.dequeueReusableCell(withIdentifier: String(describing: cell)) as? T
    }
}

class Button {

    var button: UIButton

    init() {
        button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }

    @discardableResult
    func frame(_ frame: CGRect, insets: UIEdgeInsets = .zero) -> Self {
        button.frame = UIEdgeInsetsInsetRect(frame, insets)
        return self
    }

    @discardableResult
    func title(_ title: String, for state: UIControlState = .normal) -> Self {
        button.setTitle(title, for: state)
        return self
    }

    @discardableResult
    func autoresizingMask(_ resizing: UIViewAutoresizing) -> Self {
        button.autoresizingMask = resizing
        return self
    }

    @discardableResult
    func makeSubview(of view: UIView) -> Self {
        view.addSubview(button)
        return self
    }

    @discardableResult
    func align(_ alignment: UIControlContentHorizontalAlignment) -> Self {
        button.contentHorizontalAlignment = alignment
        return self
    }

    @discardableResult
    func addTarget(_ target: Any?, action: Selector, for event: UIControlEvents = .touchUpInside) -> Self {
        button.addTarget(target, action: action, for: event)
        return self
    }
}
