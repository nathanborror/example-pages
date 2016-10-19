//
//  Components.swift
//  Pages
//
//  Created by Nathan Borror on 10/15/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import UIKit

class PageCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
