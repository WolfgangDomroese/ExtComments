//
//  NSObject_Extension.swift
//
//  Created by Wolfgang Domröse on 31.10.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//
//INTERN>:
/*
To check again, if plugin is going to load, reset defaults:
Terminal: "defaults delete com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-7.2" -> Do not forget to update XCode-version in this line!

After Xcode-Update, you must give an additional value in Info.plist DVTPlugInCompatibilityUUIDs. To find the new UUID, read it from Xcode Info.plist:
Terminal: "defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID"

For production: update value of "Bundle version" in Info.plist to latest Xcode-version

To remove a (crashing) plugin, you can remove from Finder or
Terminal: cd ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/
rm -r XComment.xcplugin/

Debugging: You can debug by running the plugin! Another Xcode will be opened that stops at breakpoints!

Logging: By Default there is one log at success and some error-logs.
*/
//>INTERN

import Cocoa

extension NSObject {
    
    class func pluginDidLoad(bundle: NSBundle) {    //called by Xcode if plugin is loaded successfully
        guard let appName = NSBundle.mainBundle().infoDictionary?["CFBundleName"]  else {
            NSLog("ExtComments: pluginDidLoad: appName == nil")
            return
        }
        guard appName as! String == "Xcode" else {
            NSLog("ExtComments: pluginDidLoad: appName != Xcode")
            return
        }
        let bundleVersion : String = bundle.infoDictionary?["CFBundleShortVersionString"] as! String
        NSLog("ExtComments: pluginDidLoad (version \(bundleVersion))")
        ExtComments.plugin.start(bundle)
    }
    
}

//extension of Array, just to avoid runtime errors by returning nil if index not valid!
extension Array {
    
    func at(index: Int) -> Element? {
        return ((index >= 0) && (index < count)) ? self[index] : nil
    }
    
}

//Split by multiple separators. Returns separators.count + 1 substrings
extension String {
    
    func splitBySeparators(separators: [String]) -> [String] {
        var copy: String = self //make a copy for mutation
        var result: [String] = [String]()
        
        for sep in separators {
            var arr = copy.componentsSeparatedByString(sep)
            result.append(arr[0])    //at least one arr available
            copy = ""
            if arr.count > 1 {
                copy = arr[1]
                while arr.count > 2 {   //repair if more then one separation
                    copy += sep + arr[2]
                    arr.removeAtIndex(2)
                }
            }
        }
        result.append(copy)
        return result
    }
    
}

extension NSUserDefaults {
    
    func removeEntriesContaining(contains: String) {    //removes certain settings e.g. to unhide alerts
        for key in dictionaryRepresentation().keys {
            if key.containsString(contains) {
                removeObjectForKey(key)
            }
        }
    }
    
}

extension NSRange {
    
    init?(byStringRange: Range<String.Index>) {     //get NSRange from String.Range
        let txtarr = byStringRange.description.componentsSeparatedByString("..<")
        if txtarr.count != 2 {return nil}
        guard let start = Int(txtarr[0]) else {return nil}
        guard let end = Int(txtarr[1]) else {return nil}
        guard end > start else {return nil}
        
        self.location = start
        self.length = end - start
    }
    
}
