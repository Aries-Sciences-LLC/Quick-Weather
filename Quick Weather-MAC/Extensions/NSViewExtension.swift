//
//  NSViewExtension.swift
//  Quick Weather-MAC
//
//  Created by Ozan Mirza on 2/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

extension NSView {
    var backgroundColor: NSColor {
        get {
            let colorRef = self.layer?.backgroundColor
            return NSColor(cgColor: colorRef!)!
        }
        set(backgroundColor) {
            self.wantsLayer = true
            self.layer!.backgroundColor = backgroundColor.cgColor
        }
    }
}
