//
//  AppDelegate.swift
//  Quick Weather-MAC
//
//  Created by Ozan Mirza on 2/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let popUp = NSPopover()
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        windowOpen = true
        popUp.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("main_icon"))
            button.action = #selector(togglePopover(_:))
        }
        popUp.contentViewController = PopUpViewController.freshController()
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popUp.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popUp.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popUp.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        
        eventMonitor?.start()
        
        windowOpen = true
        
        guard let cvc = popUp.contentViewController as? PopUpViewController else { return }
        cvc.refreshWeatherContent(cvc)
    }
    
    func closePopover(sender: Any?) {
        popUp.performClose(sender)
        
        eventMonitor?.stop()
        
        windowOpen = false
    }
}
