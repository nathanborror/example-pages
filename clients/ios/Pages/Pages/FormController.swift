//
//  FormController.swift
//  Pages
//
//  Created by Nathan Borror on 10/9/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import UIKit
import PageKit

class FormController<Item: CustomStringConvertible>: UIViewController {

    var item: Item? { didSet { reload() }}
    let text = Text()

    var onCreate: ((String?) -> Void)?
    var onUpdate: ((Item, String?) -> Void)?
    var onCancel: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        text
            .frame(view.bounds, insets: UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
            .autoresizingMask([.flexibleWidth, .flexibleHeight])
            .makeSubview(of: view)

        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneHit))
        navigationItem.rightBarButtonItem = done

        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelHit))
        navigationItem.leftBarButtonItem = cancel
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        text.becomeFirstResponder()
    }

    func doneHit() {
        if let item = item {
            onUpdate?(item, text.text)
        } else {
            onCreate?(text.text)
        }
        dismiss(animated: true, completion: nil)
    }

    func cancelHit() {
        onCancel?()
        dismiss(animated: true, completion: nil)
    }

    func reload() {
        text.text = item?.description
    }
}
