//
//  WrapperView.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import UIKit

class WrapperView: UIStackView {
    init(_ views: [UIView], axis: NSLayoutConstraint.Axis, centered: Bool) {
        super.init(frame: .zero)
        
        let leading = UIView()
        let trailing = UIView()
        
        self.axis = axis
        self.distribution = .fillProportionally
        
        if centered {
            self.addArrangedSubview(leading)
        }
        
        for view in views {
            self.addArrangedSubview(view)
        }
        
        if centered {
            self.addArrangedSubview(trailing)
        }

        if centered {
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: leading, attribute: .width, relatedBy: .equal, toItem: trailing, attribute: .width, multiplier: 1, constant: 0)
            ])
        }
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
}
