//
//  XComments.swift
//  ExtComments
//
//  Created by Wolfgang Domröse on 29.11.15.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

import Cocoa

enum XCommType {
    case xCommNone
    case xCommShort  (String, String)               //(ident, info)         <ignored> //ToDo: <comment until newline>
    case xCommLong  (String, String)                //(ident, info)         <ignored> /*ToDo: <comment> */ <ignored until newline>
    case xCommLongStart  (String, String)           //(ident, info)         <ignored> /* ToDo : <comment until newline>
    case xCommLongEnd (String)                      //(info)                <comment> */ <ignored until newline>
    case xCommSourceStart (String, String)          //(ident, info)         <ignored> //Docu–––: <comment until newline>
    case xCommSourceEnd                             //                      <ignored> //–––Docu <ignored until newline>
}

extension String {

    func rangeOfCharacterSequenceFromSet(charSet: NSCharacterSet, range: Range<Index>) -> Range<Index>? {
//INTERN>:
        /* Returns range of first sequence of Characters from charSet in string.
        range.startIndex = index of first Character in string that is member of charSet
        range.endIndex = index of firstCharacter (after start) that is NOT member of charSet.*/
//>INTERN
        
        //no empty range allowed
        guard range.startIndex != range.endIndex else {return nil}
        
        //find first character
        guard var charRange = self.rangeOfCharacterFromSet(charSet, options: NSStringCompareOptions.LiteralSearch, range: range) else {return nil}
        
        //check followers until not in charSet
        while charRange.endIndex.distanceTo(range.endIndex) > 0 &&
            self.rangeOfCharacterFromSet(charSet, options: NSStringCompareOptions.LiteralSearch, range: Range(start: charRange.endIndex, end: charRange.endIndex.successor())) != nil {
            charRange.endIndex = charRange.endIndex.successor()
        }
        //
        return charRange
    }
    
    func rangesOfParagraphs() -> [Range<Index>] {
//INTERN>:
        /* Returns array of ranges of paragraphs in string.
        NOT including newlineCharacterSet
        (U000A - U000D (LF, VT, FF, CR) && U0085 (NEL))*/
//>INTERN
        var result = [Range<Index>]()
        
        var range = Range(start: self.startIndex, end: self.startIndex)
        enum Parser {
            case waitNL, waitTXT
        }
        var state = Parser.waitNL
        
        for indx in self.characters.indices {
            switch self[indx] {
            case "\u{0A}","\u{0B}","\u{0C}","\u{0D}","\u{085}":
                if state == .waitNL {
                    range.endIndex = indx
                    result.append(range)
                    state = .waitTXT
                }
            default:
                if state == .waitTXT {
                    range.startIndex = indx
                    state = .waitNL
                }
             }
        }
        
        if state == .waitNL {
            range.endIndex = self.endIndex
            if range.startIndex.distanceTo(range.endIndex) > 0 {
                result.append(range)    
            }
            
        }
        return result
    }
    
    func searchForXcomStart(searchRange: Range<Index>) -> XCommType {
        guard let slashRange = self.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "/"), options: NSStringCompareOptions.LiteralSearch, range: searchRange)
            else {return .xCommNone}

        guard slashRange.startIndex.distanceTo(searchRange.endIndex) >= 4 else {return .xCommNone}
        
        guard let colonRange = self.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: ":"), options: NSStringCompareOptions.LiteralSearch, range: Range(start: slashRange.startIndex.advancedBy(2), end: searchRange.endIndex))
            else {return .xCommNone}
        
        var ident = self.substringWithRange(Range(start: slashRange.startIndex.advancedBy(2), end: colonRange.startIndex))
        
        guard ident.characters.count > 0 else {return .xCommNone}
        
        let isSourceXComm = ident.hasSuffix(">")
        if isSourceXComm {
            ident.removeAtIndex(ident.endIndex.predecessor())
        }
        
        //line is now looking like xxx/?<ident>:zzzzzz
        
        //test for only whitespaces before slash:
        guard (self.substringWithRange(Range(start: searchRange.startIndex, end: slashRange.startIndex))).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" else {return .xCommNone}
        
        var info = self.substringWithRange(Range(start: colonRange.endIndex, end: searchRange.endIndex))
        info = info.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        
        switch self[slashRange.startIndex.successor()] {
            case "/":   //it's a short one
                if isSourceXComm {
                    return .xCommSourceStart (ident, info)
                } else {
                    return .xCommShort (ident, info)
                }
            case "*":   //it's a long one
                let closeRange = info.rangeOfString("*/")
                if closeRange != nil {
                    info.removeRange(closeRange!)
                }
                if isSourceXComm {
                    //must be closed
                    if closeRange == nil {return .xCommNone}
                    else {
                        return .xCommSourceStart (ident, info)
                    }
                } else {
                    //may be closed
                    if closeRange == nil {
                        return .xCommLongStart (ident, info)
                    } else {
                        return .xCommLong (ident, info)
                    }
                }
        default:    //ident not valid
            return .xCommNone
        }
    }
    
    func searchForXcomSourceEnd(ident: String, searchRange: Range<Index>) -> XCommType {
        guard let identRange = self.rangeOfString(">" + ident, options: NSStringCompareOptions.LiteralSearch, range: searchRange, locale: nil) else {return .xCommNone}
        
        guard searchRange.startIndex.distanceTo(identRange.startIndex) >= 2 else {return .xCommNone}
        
        guard self[identRange.startIndex.advancedBy(-2)] == "/" else {return .xCommNone}
        
        //test for only whitespaces before slash:
        guard (self.substringWithRange(Range(start: searchRange.startIndex, end: identRange.startIndex.advancedBy(-2)))).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" else {return .xCommNone}

        switch self[identRange.startIndex.predecessor()] {
        case "/":       //it's a short end
            return .xCommSourceEnd
        case "*":       //it's a long end?
            guard (self.rangeOfString("*/", options: NSStringCompareOptions.LiteralSearch, range: Range(start: identRange.endIndex, end: searchRange.endIndex), locale: nil) != nil) else {return .xCommNone}
            return .xCommSourceEnd
        default:
            return .xCommNone
        }
        
    }

    func searchForXcomLongEnd(searchRange: Range<Index>) -> XCommType {
        guard let endRange = self.rangeOfString("*/", options: NSStringCompareOptions.LiteralSearch, range: searchRange, locale: nil) else {return .xCommNone}
        
        let info = self.substringWithRange(Range(start: searchRange.startIndex, end: endRange.startIndex))
        return .xCommLongEnd (info)
    }
}

class XCommItem: NSObject {
    var parent: XCommItem?
    var txt:    String
    static let dummy = XCommItem(parentItem: nil, line: "???")
    
    init(parentItem: XCommItem?, line: String) {
        parent = parentItem
        txt = line
    }
    
    func numChildren() -> Int {
        return 0
    }
    
    func child(index: Int) -> XCommItem {
        return XCommItem.dummy      //should never happen -> extremely careful
    }
    
    func getLOC() -> (String, NSRange)? {
        guard let xCommMain = parent as? XCommMain else {return nil}
        guard let filePath = xCommMain.url.path else {return nil}
        guard let fileRange = NSRange(byStringRange: xCommMain.range) else {return nil}
        return (filePath,fileRange)
    }
}

class XCommMain: XCommItem {
    var items = [XCommItem]()
    var url:    NSURL
    var range:  Range<String.Index>
    
    init(parentItem: XCommItem, fileURL: NSURL, mainLine: String, txtRange: Range<String.Index>) {
        url = fileURL
        range = txtRange
        super.init(parentItem: parentItem, line: mainLine)
    }
    
    func add(sublines: [String]) {
        for line in sublines {
            let item = XCommItem(parentItem: self, line: line)
            items.append(item)
        }
    }
    
    override func numChildren() -> Int {
        return items.count
    }
    
    override func child(index: Int) -> XCommItem {
        return items.at(index) ?? XCommItem.dummy   //should never happen -> extremely careful
    }
    
    override func getLOC() -> (String, NSRange)? {
        guard let filePath = url.path else {return nil}
        guard let fileRange = NSRange(byStringRange: range) else {return nil}
        return (filePath,fileRange)
    }
}

class XCommGroup: XCommItem {
    var mains = [XCommMain]()
    
    init(ident: String) {
        super.init(parentItem: nil, line: ident)
    }
    
    func add(fileURL: NSURL, range: Range<String.Index>, mainLine: String, subLines: [String]) {
        let main = XCommMain(parentItem: self, fileURL: fileURL, mainLine: mainLine, txtRange: range)
        main.add(subLines)
        mains.append(main)
    }
    
    override func numChildren() -> Int {
        return mains.count
    }
    
    override func child(index: Int) -> XCommItem {
        return mains.at(index) ?? XCommItem.dummy   //should never happen -> extremely careful
    }
    
    override func getLOC() -> (String, NSRange)? {
        return nil  //not defined on this level
    }
    
    func formatContent(whereURL: NSURL?) -> String {
        var content = String()
        var oldPath = ""
        
        for main in mains {
            var mainContent = ""
            if whereURL == nil || whereURL! == main.url {
                if whereURL == nil {
                    if oldPath != main.url.path ?? "" {
                        oldPath = main.url.path ?? ""
                        mainContent += oldPath + "\n\n"
                    }
                }
                mainContent += main.txt + "\n"
                for sub in main.items {
                    mainContent += sub.txt + "\n"
                }
            }
            if mainContent != "" {
                mainContent += "\n\n"
                content += txt + ": \n\n" + mainContent
            }
            
        }
        return content
    }
}

class XComment: NSObject {
    var ident:      String
    var info:       String
    var subInfo:    [String]
    var range:      Range<String.Index>     //range of ident in file content string
    
    init(byIdent: String, withInfo: String, contentRange: Range<String.Index>, forSave: Bool) {
        ident = byIdent
        info = forSave ? withInfo : withInfo.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        range = contentRange
        subInfo = []
        super.init()
    }
    
    func addInfo(addInfo: String, addRange: Range<String.Index>, forSave: Bool) {
        
        func isContentFree(txt: String) -> Bool {   //check with trimmed strings!
            if txt == "" {return true}
            if txt == "/*" {return true}
            if txt == "*/" {return true}
            if txt == "//" {return true}
            return false
        }
        
        range.endIndex = addRange.endIndex
        if forSave {
            subInfo.append(addInfo)
            return
        }
        
        let trimmedInfo = addInfo.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if subInfo.count == 0 && isContentFree(info) {
            info = trimmedInfo  //avoid empty Strings at start
        } else if !isContentFree(trimmedInfo) {subInfo.append(trimmedInfo)}
    }
}

class XCommInFile: NSObject {
    var xComments = [XComment]()
    
    init(byURL: NSURL, forSave: Bool, allowedComments: [SetupObject]) {
        
        super.init()
        
        do {
            let content = try String(contentsOfURL: byURL)
            let lineRanges = content.rangesOfParagraphs()

            var waitIdent = ""
            
            enum ParserState {case parserWaitStart, parserReadToLongEnd, parserIgnoreUntilLongEnd, parserReadToSourceEnd, parserIgnoreUntilSourceEnd}
            var parserState = ParserState.parserWaitStart
            
            for lineRange in lineRanges {
                switch parserState {
                case .parserWaitStart:
                    switch content.searchForXcomStart(lineRange) {
                    case .xCommShort(let ident, let info):
                        if allowedComments.checkAllowed(ident, forSave: forSave) {xComments.append(XComment(byIdent: ident, withInfo: info, contentRange: lineRange, forSave: forSave))}
                        //no change in parserState
                    case .xCommLong(let ident, let info):
                        if allowedComments.checkAllowed(ident, forSave: forSave) {xComments.append(XComment(byIdent: ident, withInfo: info, contentRange: lineRange, forSave: forSave))}
                        //no change in parserState
                    case .xCommLongStart(let ident, let info):
                        if allowedComments.checkAllowed(ident, forSave: forSave) {
                            xComments.append(XComment(byIdent: ident, withInfo: info, contentRange: lineRange, forSave: forSave))
                            parserState = .parserReadToLongEnd
                        } else {parserState = .parserIgnoreUntilLongEnd}
                    case .xCommSourceStart(let ident, let info):
                        if allowedComments.checkAllowed(ident + ">", forSave: forSave) {
                            xComments.append(XComment(byIdent: ident + ">", withInfo: info, contentRange: lineRange, forSave: forSave))
                            waitIdent = ident
                            parserState = .parserReadToSourceEnd
                        } else {parserState = .parserIgnoreUntilSourceEnd}
                    default:
                        break
                    }
                case .parserReadToLongEnd, .parserIgnoreUntilLongEnd:
                    switch content.searchForXcomLongEnd(lineRange) {
                    case .xCommLongEnd (let info):
                        guard parserState == .parserReadToLongEnd && xComments.count > 0 else {break}
                        xComments.last!.addInfo(info, addRange: lineRange, forSave: forSave)
                        parserState = .parserWaitStart
                    case .xCommNone:
                        guard parserState == .parserReadToLongEnd && xComments.count > 0 else {break}
                        xComments.last!.addInfo(content.substringWithRange(lineRange), addRange: lineRange, forSave: forSave)
                    default:    //should never happen
                        break
                    }
                    break
                case .parserReadToSourceEnd, .parserIgnoreUntilSourceEnd:
                    switch content.searchForXcomSourceEnd(waitIdent, searchRange: lineRange) {
                    case .xCommSourceEnd:
                        guard parserState == .parserReadToSourceEnd && xComments.count > 0 else {break}
                        xComments.last!.addInfo("", addRange: lineRange, forSave: forSave)
                        parserState = .parserWaitStart
                    case .xCommNone:
                        guard parserState == .parserReadToSourceEnd && xComments.count > 0 else {break}
                        xComments.last!.addInfo(content.substringWithRange(lineRange), addRange: lineRange, forSave: forSave)
                    default:    //should never happen
                        break
                    }
                }
            }
            
        } catch {}
    }
}

class XCommInProject: NSObject {
    var xCommGroupArray = [XCommGroup]()        //array needed for outline-view
    var urlArray = [NSURL]()                    //needed for save when sorted by sourcefile
    
    init(byFiles: [NSURL], forSave: Bool, allowedComments: [SetupObject]) {
        urlArray = byFiles
        for url in byFiles {
            let xCommInFile = XCommInFile(byURL: url, forSave: forSave, allowedComments: allowedComments)
            for xComment in xCommInFile.xComments {
                var group = xCommGroupArray.filter({return $0.txt == xComment.ident}).at(0)
                if group == nil {
                    group = XCommGroup(ident: xComment.ident)
                    xCommGroupArray.append(group!)
                }
                group!.add(url, range: xComment.range, mainLine: xComment.info, subLines: xComment.subInfo)
            }
        }
    }
    
    func formatContent() -> String {
        var content = String()
        
        let setupCntrl = ExtComments.plugin.setupWindowController
        
        if setupCntrl.saveSortedByFiles {
            for url in urlArray {
                var groupContent = ""
                for group in xCommGroupArray {
                    groupContent += group.formatContent(url)
                }
                if groupContent != "" {
                    content += (url.path ?? "") + "\n" + groupContent
                }
            }
        } else {
            for group in xCommGroupArray {
                content += group.formatContent(nil)
            }
        }
        return content
    }
    
    func writeToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["txt"]
        savePanel.allowsOtherFileTypes = false
        
        var saveURL : NSURL?
        var content : String = ""
        
        guard savePanel.runModal() == NSFileHandlingPanelOKButton else {return}
        
        saveURL = savePanel.URL
        guard saveURL != nil else {return}
        
        content = formatContent()
        
        do {
            try content.writeToURL(saveURL!, atomically: false, encoding: NSUTF8StringEncoding)
        } catch {}
        
    }
}
