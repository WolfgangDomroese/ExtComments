//
//  XcodeBridge.swift
//  ExtComments
//
//  Created by Wolfgang Domröse on 31.10.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//


import Cocoa

class WDBGXcodeBridge : NSObject {
    static let xcodeBridge = WDBGXcodeBridge()  //singleton
    
    var xcodeProjectNavigator:          AnyObject?

    enum WDBGMenuTags : Int {
        case insertTag = 0, showTag, saveTag, setTag
    }
    
    var ExtCommentsMenu:  NSMenu?
    
    func setXCommMenuItems() {
        
//Docu>:
        /*
        ExtComments can be written as combination of ident and info. The ident must be one word with any Character except Whitespaces!. Outside ident, whitespaces are allowed.
        
        - short comment like "//ToDo: ...info..."
        
        - long comment like "   /*FixIt: This is a long (multiline)
        info */

        Characters after "/* .... */" are ignored.
        
        - source comment witht a short start-comment like "//Docu>: ...info..." and a short end-comment like "//>Docu" or
        - source comment with a long start-comment like "/*Book>: ...info...*/ and a along end-comment like /*>Book */
        Characters before start-comment are ignored.
        Characters before end-comment are part of info.
        Characters after ">" are ignored.
        
        Except long comments, all comments have to be one-line comments.
        
        Whitespaces between "//" or "/*" and ":" are forbidden!           */
        Additional characters in source-end-comments are ignored.
        
        A source comment defines source code between start- and end-comment to be looked for in show or save (mainly). Of course, source code can be a mixture of source code and comments!
        
        Note: in setup, all idents must be set without the starting "//" or "/*" and colon ":" and "*/.
        Just the pure text like "Mark" or "Docu>"
        
        ExtComments can be set manually in editor or by selecting appropriate menu entry in "Edit" menu.
        
        Holding <alt> pressed while selecting menu item, sets
        - long comment instead of short
        - end-comment instead of start-comment with source comments like "Docu>"
        
        Setting "Prefer /*...*/ comments" in setup, skips this behaviour:
        - set long Comment without and short Comment with <alt> pressed
        - set source Comments with e.g. "/*Docu>:*/" instead of "  //Docu>:"
        */
//>Docu

        
        guard let xCommMenu = ExtCommentsMenu else {return}
        let setupCntrl = ExtComments.plugin.setupWindowController
        
        xCommMenu.removeAllItems()
        
        
         func createMenuItem(withTitle: String, tag: WDBGMenuTags, alternative: Bool) -> NSMenuItem {
            let newItem: NSMenuItem = NSMenuItem(title: withTitle, action: "doMenuAction:", keyEquivalent:"")
            
            newItem.tag = tag.rawValue
            newItem.enabled = true
            newItem.target = self
            newItem.alternate = alternative
            newItem.keyEquivalentModifierMask = alternative ? Int(NSEventModifierFlags.AlternateKeyMask.rawValue) : 0
            
            return newItem
        }
        
        for elem in setupCntrl.userXCommObjects {
            let indexll = elem.xComment.endIndex.advancedBy(-1)
            let longlong = elem.xComment.substringFromIndex(indexll) == ">"
            
            if longlong {   //open longlong comment
                xCommMenu.addItem(createMenuItem(setupCntrl.preferAsteriks ? "/*\(elem.xComment):*/" : "//\(elem.xComment):", tag: WDBGMenuTags.insertTag, alternative: false))
            } else {
                xCommMenu.addItem(createMenuItem(setupCntrl.preferAsteriks ? "/*\(elem.xComment): */" : "//\(elem.xComment): ", tag: WDBGMenuTags.insertTag, alternative: false))
            }
            
            //Alternate item
            let rawText = longlong ? elem.xComment.substringToIndex(indexll) : ""
            if longlong {   //close longlong comment
                xCommMenu.addItem(createMenuItem(setupCntrl.preferAsteriks ? "/*>\(rawText)*/" : "//>\(rawText)", tag: WDBGMenuTags.insertTag, alternative: true))
            } else {
                xCommMenu.addItem(createMenuItem(setupCntrl.preferAsteriks ? "//\(elem.xComment): " : "/*\(elem.xComment): */", tag: WDBGMenuTags.insertTag, alternative: true))
            }
        }
        
        //menu item for showing XComments
        xCommMenu.addItem(NSMenuItem.separatorItem())
        xCommMenu.addItem(createMenuItem("Show", tag: WDBGMenuTags.showTag, alternative: false))
        //menu item for saving XComments
        xCommMenu.addItem(NSMenuItem.separatorItem())
        xCommMenu.addItem(createMenuItem("Save", tag: WDBGMenuTags.saveTag, alternative: false))
        //menu item for setup XComments
        xCommMenu.addItem(NSMenuItem.separatorItem())
        xCommMenu.addItem(createMenuItem("Setup", tag: WDBGMenuTags.setTag, alternative: false))
    }
    
    func setEditMenus() {
        
        guard let editMenuItem = NSApp.mainMenu?.itemWithTitle("Edit") else {
            NSLog("ExtComments: itemWithTitle('Edit') == nil")
            return
        }
        
        let insertMenuItem = NSMenuItem(title:"ExtComments", action: "doMenuAction:", keyEquivalent:"")
        insertMenuItem.target = self
        
        guard let editSubmenu = editMenuItem.submenu else {return}
        
        editSubmenu.addItem(NSMenuItem.separatorItem())
        editSubmenu.addItem(insertMenuItem)
        
        //prepare the new menu for selection of xComments
        ExtCommentsMenu = NSMenu(title: "")
        ExtCommentsMenu!.autoenablesItems = false
        
        //bind xCommMenu to insertMenuItem
        editSubmenu.setSubmenu(ExtCommentsMenu!, forItem: insertMenuItem)
        
        setXCommMenuItems()
        
    }
    
    func doMenuAction(sender: NSMenuItem) {
        guard let xcodeMainWindowController = ExtComments.plugin.xcodeWindowController else {return}
        let setupCntrl = ExtComments.plugin.setupWindowController

        xcodeProjectNavigator = IDEBridge.xcodeProjectNavigator(xcodeMainWindowController)
        /* ExtComments uses "Project navigator" to select groups and files. The Project navigator must be visible for show, save and setup!
        */
        if (sender.tag != WDBGMenuTags.insertTag.rawValue) && (xcodeProjectNavigator == nil) {
            ExtComments.plugin.messageBox("PNavNV", text: "Can not continue", info: "Project navigator not visible", button1: "", button2: "", button3: "", allowSupress: false, supressedReturn: 1)
            return
        }
        switch sender.tag {
        case WDBGMenuTags.insertTag.rawValue:
            /*Docu: To insert XComments by menu, text editor must be opened
            */
            guard let editor = IDEBridge.currentEditor(xcodeMainWindowController) else {
                ExtComments.plugin.messageBox("TEediNV", text: "Can not insert text", info: "No texteditor in main window", button1: "", button2: "", button3: "", allowSupress: true, supressedReturn: 1)
                break
            }
            guard let currentTextView = IDEBridge.currentTextView(editor) else {
                ExtComments.plugin.messageBox("TEediNV", text: "Can not insert text", info: "No texteditor in main window", button1: "", button2: "", button3: "", allowSupress: true, supressedReturn: 1)
                break
            }
            let range = currentTextView.selectedRange()
            if !(range.length > 0 &&
                ExtComments.plugin.messageBox("RepTxt", text: "Replace text", info: "Do you really want to replace selected text?", button1: "NO!", button2: "Yes", button3: "", allowSupress: true, supressedReturn: 2) != 2) {
                    currentTextView.insertText(sender.title, replacementRange: currentTextView.selectedRange())
            }
        case WDBGMenuTags.showTag.rawValue:
            let urlArray = naviGetFilesToAnalyse(setupCntrl.excludeGroups, includedTypes: setupCntrl.fileTypeInclude)
            guard let window = ExtComments.plugin.showWindowController.window else {return}
            let xCommInProject = XCommInProject(byFiles: urlArray, forSave: false, allowedComments: setupCntrl.userXCommObjects)
            ExtComments.plugin.showWindowController.setNewDataSource(xCommInProject.xCommGroupArray)
            window.makeKeyAndOrderFront(self)
            //NSApp.runModalForWindow(window)
            //ExtComments.plugin.showWindowController!.close()
        case WDBGMenuTags.saveTag.rawValue:
            let urlArray = naviGetFilesToAnalyse(setupCntrl.excludeGroups, includedTypes: setupCntrl.fileTypeInclude)
            let xCommInProject = XCommInProject(byFiles: urlArray, forSave: true, allowedComments: setupCntrl.userXCommObjects)
            xCommInProject.writeToFile()
        case WDBGMenuTags.setTag.rawValue:
            guard let window = ExtComments.plugin.setupWindowController.window else {return}
            let returnCode = SetupVC.showSetup(window)
            if returnCode > 0 {setXCommMenuItems()}
            ExtComments.plugin.setupWindowController.close()
        default: ()
        }
    }

    //Navi functions
    func naviGroupArray(itemChildren: [AnyObject]) -> [AnyObject] {
        var result = [AnyObject]()
        
        for elem in itemChildren {
            switch IDEBridge.naviObjType(elem) {
            case .Unknown:
                break
            case .Navigator:
                result.append(elem)
            case .Container:
                result.append(elem)
            case .Group:
                result.append(elem)
            case .File:
                break
            }
        }
        return result
    }

    func naviSubgroups(item: AnyObject) -> [AnyObject] {
        let itemChildren = IDEBridge.naviChildren(item)
        let itemSubgroups = naviGroupArray(itemChildren)
        
        return itemSubgroups
    }
    
    func naviGroupName(item: AnyObject) -> String {
        var result = ""
        
        switch IDEBridge.naviObjType(item) {
        case .Unknown:
            break
        case .Navigator:
            result = "ProjectNavigator"
        case .Container:
            result = IDEBridge.navigItemName(item)
        case .Group:
            result = IDEBridge.navigItemName(item)
        case .File:
            break
        }
    return result
    }
    
    func naviGetFileURL(item: AnyObject) -> NSURL? {
        let url : NSURL? = IDEBridge.navigItemURL(item)
        guard url != nil else {return nil}
        return url!
    }
    
    func naviGetFilesToAnalyse(excludedPathes: [String], includedTypes: [String : Bool]) -> [NSURL] {
        var result = [NSURL]()
        
        guard xcodeProjectNavigator != nil else {return result}
        
        func getFilesFromFolder(folder: AnyObject, path: String) -> [NSURL] {
            var result = [NSURL]()
            
            guard !excludedPathes.contains(path) else {return result}
            
            let children = IDEBridge.naviChildren(folder)
            
            for child in children {
                
                switch IDEBridge.naviObjType(child) {
                case .Unknown:
                    break
                case .Navigator:
                    break
                case .Container:
                    result += getFilesFromFolder(child, path: path + ":" + naviGroupName(child))
                case .Group:
                    result += getFilesFromFolder(child, path: path + ":" + naviGroupName(child))
                case .File:
                    guard let url = naviGetFileURL(child) else {break}
                    guard let ext = url.pathExtension else {break}
                    guard includedTypes[ext] == true else {break}
                    result += [url]
                }
            }
            
            return result
        }
        
        result += getFilesFromFolder(xcodeProjectNavigator!, path: naviGroupName(xcodeProjectNavigator!))
        
        return result
    }
    
    //function fired by timer in ShowWC.swift
    func selectEditorRange(timer: NSTimer) {
        guard let xcodeMainWindowController = ExtComments.plugin.xcodeWindowController else {return}
        guard let editor = IDEBridge.currentEditor(xcodeMainWindowController) else {return}
        guard let currentTextView = IDEBridge.currentTextView(editor) else {return}
        guard let range = timer.userInfo as? NSRange else {return}
        currentTextView.setSelectedRange(range)
        currentTextView.scrollRangeToVisible(range)
    }
    
    func singleSourceEditorActive() -> Bool {
        guard let xcodeMainWindowController = ExtComments.plugin.xcodeWindowController else {return false}
        switch IDEBridge.editorType(xcodeMainWindowController)
        {
        case 0: return false
        case 1: return true
        case 2: return false
        default: return false
        }
    }
    
    func currentEditorDocumentURL() -> NSURL? {
        guard let xcodeMainWindowController = ExtComments.plugin.xcodeWindowController else {return nil}
        guard let editor = IDEBridge.currentEditor(xcodeMainWindowController) else {return nil}
        guard let document = IDEBridge.currentSourceCodeDocument(editor) else {return nil}
        return document.fileURL
    }
    
}