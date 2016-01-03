//
//  ExtComments.swift
//
//  Created by Wolfgang Domröse on 31.10.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

import Cocoa

class ExtComments: NSObject {               //className == bundleName!
    
    static let plugin =     ExtComments()   //it's a real singleton
    var bundle:             NSBundle?       //set by calling "start" for the first time
    
    lazy var center = NSNotificationCenter.defaultCenter()
    lazy var settings = NSUserDefaultsController.sharedUserDefaultsController().defaults
    
    lazy var setupWindowController : SetupWC = SetupWC(windowNibName: "SetupWC")
    lazy var showWindowController : ShowWC = ShowWC(windowNibName: "ShowWC")
    
    lazy var xcodeWindowController : NSWindowController? = {
        guard let win = NSApp.mainWindow else {return nil}
        return win.windowController
    }()
    
    override init() {
        super.init()
    }
    
    func start(pluginBundle: NSBundle) {
        if bundle == nil {  //make sure to use it only once
            bundle = pluginBundle
            
            center.addObserver(self, selector: Selector("xcodeAppDidLaunch"), name: NSApplicationDidFinishLaunchingNotification, object: nil)
        }
    }

    deinit {
        center.removeObserver(self)
    }
    
    func removeObserver(name: String) {
        center.removeObserver(self, name: name, object: nil)
    }

    func xcodeAppDidLaunch() {
        removeObserver(NSApplicationDidFinishLaunchingNotification)
        WDBGXcodeBridge.xcodeBridge.setEditMenus()  //prepare ExtComments and activate
    }
    
    func resetHiddenAlerts() {
        settings.removeEntriesContaining("ExtComment_Alert")
    }
    
    func messageBox(uniqueID: String, text: String, info: String, button1: String, button2: String, button3: String, allowSupress: Bool, supressedReturn: Int) -> Int {
        
        guard !(allowSupress && settings.boolForKey("ExtComment_Alert"+uniqueID))
            else {return supressedReturn}
        
        let alert = NSAlert()
        alert.messageText = text
        alert.informativeText = info
        if button1 != "" {alert.addButtonWithTitle(button1)}
        if button2 != "" {alert.addButtonWithTitle(button2)}
        if button3 != "" {alert.addButtonWithTitle(button3)}
        if allowSupress {alert.showsSuppressionButton = true}
        
        var result = 0
        switch alert.runModal() {
        case NSAlertFirstButtonReturn:
            result = 1
        case NSAlertSecondButtonReturn:
            result = 2
        case NSAlertThirdButtonReturn:
            result = 3
        default:
            result = 0
        }
        
        if alert.suppressionButton?.state ?? NSOffState == NSOnState {
            settings.setBool(true, forKey: "ExtComment_Alert"+uniqueID)
        }
        
        return result
    }
    
}

