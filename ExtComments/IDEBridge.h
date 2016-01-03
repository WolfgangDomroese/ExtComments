//
//  IDEBridge.h
//  ExtComments
//
//  Created by Wolfgang Domröse on 02.11.15.
//  Adapted from several open source projects.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

#ifndef IDEBridge_h
#define IDEBridge_h

#import "IDEHeader.h"

@interface IDEBridge: NSObject
+ (IDEEditor*)currentEditor: (id) xcodeWindowController;
+ (NSInteger)editorType: (id) xcodeEditor;  //0 = none; 1 = IDESourceCodeEditor; 2 = IDESourceCodeComparisonEditor
+ (NSTextView*)currentTextView: (id) xcodeEditor;
+ (IDESourceCodeDocument*)currentSourceCodeDocument: (id) xcodeEditor;
+ (IDEStructureNavigator*)xcodeProjectNavigator: (id) xcodeWindowController;
+ (NSArray*)naviChildren: (id) item;
+ (NaviObjectType)naviObjType: (id) item;
+ (NSString*)navigItemName: (id) item;
+ (NSURL*)navigItemURL: (id) item;
@end

#endif /* IDEBridge_h */
