//
//  SetupWC.swift
//  ExtComments
//
//  Created by Wolfgang Domröse on 15.11.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

import Cocoa

class SetupWC: NSWindowController {

    lazy var settings = NSUserDefaultsController.sharedUserDefaultsController().defaults
    
    override func windowWillLoad() {
        super.windowWillLoad()
        
        //initial Values for bindings
        NSUserDefaultsController.sharedUserDefaultsController().initialValues = [
            "ExtComment_saveSorted" : 0,
            "ExtComments_supressPath" : 0,
            "ExtComment_Asteriks" : 0
        ]
    }
    //User Defaults with Binding
    var preferAsteriks : Bool {get {return settings.integerForKey("ExtComment_Asteriks") == NSOnState}}
    var saveSortedByFiles : Bool {get {return settings.integerForKey("ExtComment_saveSorted") == NSOnState}}
    //User Defaults without Binding
    var fileTypeInclude : [String : Bool] {                         //AnyObject : Bool
        get {return settings.dictionaryForKey("ExtComment_FileType") as? [String : Bool] ?? [:]}
        set (dict) {settings.setObject(dict, forKey: "ExtComment_FileType")}
    }
    var excludeGroups: [String] {
        get {return settings.arrayForKey("ExtComment_ExclGroups") as? [String] ?? []}
        set (arr) {settings.setObject(arr, forKey: "ExtComment_ExclGroups")}
    }
    var userXCommObjects: [SetupObject] {
        get {
            guard let data = settings.objectForKey("ExtComment_Comments") as? NSData else {
                return [        //default settings
                    SetupObject(comment: "ToDo", commshow: true, commsave: false),
                    SetupObject(comment: "ToFix", commshow: true, commsave: false),
                    SetupObject(comment: "Docu>", commshow: false, commsave: true)]
            }
            return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [SetupObject]
        }
        
        set (val) {
            let data = NSKeyedArchiver.archivedDataWithRootObject(val)
            settings.setObject(data, forKey: "ExtComment_Comments")
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard window != nil else {return}
        let bundleName : String = (ExtComments.plugin.bundle?.infoDictionary?["CFBundleName"] ?? "ExtComments") as! String
        let bundleVersion : String = (ExtComments.plugin.bundle?.infoDictionary?["CFBundleShortVersionString"] ?? "0.0.0") as! String
        let bundleBuild : String = (ExtComments.plugin.bundle?.infoDictionary?["CFBundleVersion"] ?? "0.0.0") as! String
        window!.title = "Setup \(bundleName) \(bundleVersion) (Xcode: \(bundleBuild))"
    }
}

class FileTypeBox: NSBox {
    
    var fileTypes : [String : Bool] = [:]
    
    func typeOf(title: String) -> String {
    
        let indx = title.startIndex.advancedBy(1)
        guard title.substringToIndex(indx) == "." else {return ""}
        return title.substringFromIndex(indx)
    }
    
    func getFileTypeChecks() -> [String : Bool] {
        var result : [String : Bool] = [:]
        
        for sub in subviews[0].subviews where sub is NSButton { //one view in the box
            let key = typeOf((sub as! NSButton).title)
            guard key != "" else {break}
            result[key] = (sub as! NSButton).state == NSOnState
        }
    
        return result
    }
    
    func setFileTypeChecks(source: [String : Bool]) {
        for sub in subviews[0].subviews where sub is NSButton { //one view in the box
            let key = typeOf((sub as! NSButton).title)
            guard key != "" else {break}
            (sub as! NSButton).state = (source[key] ?? true) ? NSOnState : NSOffState
        }
    }
}

class SetGroupsObject: NSObject {   //data source for NSOutlineView

    static var rootItem: SetGroupsObject?
        
    var navigatorObject:    AnyObject?
    var parentGroup:        SetGroupsObject?
    var groupName:          String
    var naviPath:           String
    lazy var children:      [SetGroupsObject]? = {
                                var newChildren:    [SetGroupsObject] = []
                                if self.isNaviGroup {
                                    let naviItems = WDBGXcodeBridge.xcodeBridge.naviSubgroups(self.navigatorObject!)
                                    if self.parentGroup != nil {newChildren.append(SetGroupsObject(navigatorObj: nil, parent: self))}
                                    for subgroup in naviItems {
                                        newChildren.append(SetGroupsObject(navigatorObj: subgroup, parent: self))
                                    }
                                }
                                return newChildren
                            }()

    var isNaviGroup: Bool {
        get {return navigatorObject != nil}
    }
    
    init(navigatorObj: AnyObject?, parent: SetGroupsObject?) {
        parentGroup = parent
        if parentGroup == nil {  //root
            navigatorObject = WDBGXcodeBridge.xcodeBridge.xcodeProjectNavigator
            groupName = WDBGXcodeBridge.xcodeBridge.naviGroupName(navigatorObject!)
            naviPath = groupName
        } else {
            navigatorObject = navigatorObj
            groupName = (navigatorObject == nil) ? "---" : WDBGXcodeBridge.xcodeBridge.naviGroupName(navigatorObject!)
            naviPath = parentGroup!.naviPath
            if navigatorObj != nil {naviPath += ":" + groupName}
        }
    }
    
    class func iterateGroups(start: SetGroupsObject, callFunc: (SetGroupsObject) -> Bool) {
        guard start.isNaviGroup else {return}
        if start.parentGroup == nil || callFunc(start) {    //iterate children
            if start.children != nil {
                for group in start.children! where group.isNaviGroup {
                    iterateGroups(group, callFunc: callFunc)
                }
            }
        }
        
    }
    
    class func expandAll(outlineView: NSOutlineView, withExceptions: [String]) {
    
        func expand(obj: SetGroupsObject) -> Bool {     //returns false, if item is not expanded
            if !withExceptions.contains(obj.naviPath) {
                outlineView.expandItem(obj)
                return true
            } else {
                outlineView.collapseItem(obj)
            return false
            }
        }
        guard rootItem != nil else {return}
        iterateGroups(rootItem!, callFunc: expand)
    }
    
    class func getCollapsedPathes(outlineView: NSOutlineView) -> [String] {
        var result: [String] = []
        
        func getPath(obj: SetGroupsObject) -> Bool {    //returns false, if item is not expanded
            if outlineView.isItemExpanded(obj) {
                return true
            } else {
                result.append(obj.naviPath)
                return false
            }
        }
        guard rootItem != nil else {return result}
        iterateGroups(rootItem!, callFunc: getPath)
        return result
    }

}

protocol SetupProtocol {

    var xComment:   String {get set}
    var xCommShow:  Bool {get set}
    var xCommSave:  Bool {get set}
    
    func lookFor(ident: String) -> Bool     //look for object with ident
    func checkFor(forSave: Bool) -> Bool    //check if show/save is allowed
}

class SetupObject: NSObject, NSCoding, SetupProtocol {
    
    var xComment:   String
    var xCommShow:  Bool
    var xCommSave:  Bool
    
    init(comment: String, commshow: Bool, commsave: Bool) {
        xComment = comment
        xCommShow = commshow
        xCommSave = commsave
    }

    required convenience init?(coder decoder: NSCoder) {
        guard let comment = decoder.decodeObjectForKey("xComment") as? String else {return nil}
        
        self.init(comment: comment, commshow: decoder.decodeBoolForKey("xCommShow"), commsave: decoder.decodeBoolForKey("xCommSave"))
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(xComment, forKey: "xComment")
        coder.encodeBool(xCommShow, forKey: "xCommShow")
        coder.encodeBool(xCommSave, forKey: "xCommSave")
    }
    
    func lookFor(ident: String) -> Bool {
        return xComment == ident
    }
    
    func checkFor(forSave: Bool) -> Bool {
        if forSave { return xCommSave }
        else {return xCommShow }
    }
}

extension Array where Element : SetupProtocol {

    func checkAllowed(ident: String, forSave: Bool) -> Bool {
    
        for elem in self {
            if elem.lookFor(ident) {
                return elem.checkFor(forSave)
            }
        }
        return false
    }
}

class SetupVC: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {

    //Global setup values
    var setupArray :        [SetupObject] = []   //array holding SetupObjects

    @IBOutlet weak var arrayController: NSArrayController!
    
    @IBOutlet weak var filetypeBox: FileTypeBox!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var resetSupressedAlerts = NSOffState    //Binding: Checkbox in setup
    
    override func viewWillAppear() {
        arrayController.removeObjects(setupArray as [AnyObject])

        guard let setupCntrl = view.window?.windowController as? SetupWC else {return}
        
        arrayController.addObjects(setupCntrl.userXCommObjects)
        filetypeBox.setFileTypeChecks(setupCntrl.fileTypeInclude)
        
        refreshOutlineView(setupCntrl)
    }
    
    class func showSetup(window: NSWindow) -> Int {
        NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = false
        return NSApp.runModalForWindow(window)
    }
    
    @IBAction func buttonCancelClicked(sender: NSButton) {
        NSUserDefaultsController.sharedUserDefaultsController().revert(self)
        NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
        NSApp.stopModalWithCode(0)
    }
    
    @IBAction func buttonOKClicked(sender: NSButton) {
        let setupCntrl = view.window?.windowController as? SetupWC
        if setupCntrl != nil {
            setupCntrl!.fileTypeInclude = filetypeBox.getFileTypeChecks()//set userdefaults
            setupCntrl!.userXCommObjects = setupArray
            setupCntrl!.excludeGroups = SetGroupsObject.getCollapsedPathes(outlineView)
        }
        
//Docu>: When "Show hidden alerts" is checked and setup is left with "OK", all hidden alerts are shown again
//>Docu
        if resetSupressedAlerts != NSOffState { //reset all hidden alerts
            resetSupressedAlerts = NSOffState
            ExtComments.plugin.resetHiddenAlerts()
        }
        
        NSUserDefaultsController.sharedUserDefaultsController().save(self)
        NSUserDefaultsController.sharedUserDefaultsController().appliesImmediately = true
        NSApp.stopModalWithCode(1)
    }
    
    @IBAction func addExtComment(sender: NSButton) {
        arrayController.addObject(SetupObject(comment: "new",commshow: true,commsave: true))
    }

    @IBOutlet weak var collectionView: NSCollectionView!
    @IBAction func delXComm(sender: NSButton) {
        let cvItem = sender.superview   //NSView?
        
        for (indx, _) in setupArray.enumerate() {
            if collectionView.itemAtIndex(indx)?.view == cvItem {
                arrayController.removeObject(setupArray[indx])
                break
            }
        }
    }

    //NSOutlineViewDelegate

    func expandGroups(cntrl: SetupWC) {
        SetGroupsObject.expandAll(outlineView, withExceptions: cntrl.excludeGroups)
    }
    
    func refreshOutlineView(cntrl: SetupWC) {
        SetGroupsObject.rootItem = SetGroupsObject(navigatorObj: nil, parent: nil)
        if outlineView != nil {outlineView.reloadData()}    //it's a must before view will appear!

        expandGroups(cntrl)
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let it = item as? SetGroupsObject {
            return it.children![index]}
        else {
            return SetGroupsObject.rootItem!.children![index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let it = item as? SetGroupsObject {
            return it.children!.count > 0
        }
        return true //should never happen
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let it = item as? SetGroupsObject {
            return it.children!.count
        }
        
        //first call with item == nil: lets say "how many root-objects do you have?"
        if SetGroupsObject.rootItem == nil {
            SetGroupsObject.rootItem = SetGroupsObject(navigatorObj: nil, parent: nil)
        }
        
        return SetGroupsObject.rootItem!.children!.count //numberOfChildren()
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn: NSTableColumn?, byItem: AnyObject?) -> AnyObject? {
        if let item = byItem as? SetGroupsObject {
            return item.groupName
        }
        return nil
    }
}