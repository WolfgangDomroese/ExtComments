//
//  ShowWC.swift
//  ExtComments
//
//  Created by Wolfgang Domröse on 26.11.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

import Cocoa

class ShowWC: NSWindowController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    var xCommDataSource =  [XCommGroup]()
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func ViewClicked(sender: NSOutlineView) {
        guard sender.clickedRow >= 0 else {return}
        guard let item = sender.itemAtRow(sender.clickedRow) as? XCommItem else {return}
        guard let (path, range) = item.getLOC() else {return}
        guard WDBGXcodeBridge.xcodeBridge.singleSourceEditorActive() else {
            ExtComments.plugin.messageBox("NeedSIDE", text: "Must close assistant editor", info: "Selection of ExtComments only available in Standard Editor", button1: "", button2: "", button3: "", allowSupress: true, supressedReturn: 0)
            return
        }
        guard let delegate = NSApp.delegate else {return}
        let editorPath = WDBGXcodeBridge.xcodeBridge.currentEditorDocumentURL()?.path ?? ""
        if editorPath == path || delegate.application!(NSApp, openFile: path) {
            
            let _ = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.02), target: WDBGXcodeBridge.xcodeBridge , selector: "selectEditorRange:", userInfo: range, repeats: false)
            
            window?.makeKeyAndOrderFront(self)
        }
    }
    
    @IBAction func buttonOKCLicked(sender: NSButton) {
        window!.close()
    }
    
    @IBOutlet weak var showOutlineView: NSOutlineView!

    //NSOutlineViewDataSource
    func setNewDataSource(source: [XCommGroup]) {
        xCommDataSource = source
        if showOutlineView != nil {showOutlineView!.reloadData()}
    }

    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let it = item as? XCommItem {
            return it.child(index)
        }
        //root items
        return xCommDataSource[index]
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let it = item as? XCommItem {
            return it.numChildren() > 0
        }
        return true //should never happen
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let it = item as? XCommItem {
            return it.numChildren()
        }
        //first call with item == nil: lets say "how many root-objects do you have?"
        return xCommDataSource.count
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn: NSTableColumn?, byItem: AnyObject?) -> AnyObject? {
        if let item = byItem as? XCommItem {
            return item.txt
        }
        return nil
    }
    
}
