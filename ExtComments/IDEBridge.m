//
//  IDEBridge.m
//  ExtComments
//
//  Created by Wolfgang Domröse on 02.11.15.
//  Adapted from several open source projects.
//  Copyright © 2015 Wolfgang Domröse. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IDEHeader.h"
#import "IDEBridge.h"

@implementation IDEBridge

+ (id)currentEditor: (id) xcodeWindowController
{
    if ([xcodeWindowController
         isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)xcodeWindowController;
        IDEEditorArea* editorArea = [workspaceController editorArea];
        IDEEditorContext* editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}

+ (NSInteger)editorType: (id) xcodeWindowController;  //0 = none; 1 = Standard Editor; 2 = Assistant Editor
{
    if ([xcodeWindowController
         isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)xcodeWindowController;
        IDEEditorArea* editorArea = [workspaceController editorArea];
        return [editorArea editorMode] + 1;
    }
    return 0;
}

+ (id)currentTextView: (id) xcodeEditor
{
    if ([xcodeEditor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor* editor = xcodeEditor;
        return [editor textView];
    }
    if ([xcodeEditor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor* editor = xcodeEditor;
        return [editor keyTextView];
    }
    return nil;
}

+ (id) currentSourceCodeDocument: (id) xcodeEditor
{
    if ([xcodeEditor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor* editor = xcodeEditor;
        return [editor sourceCodeDocument];
    }
    if ([xcodeEditor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor* editor = xcodeEditor;
        id currentDocument = [editor primaryDocument];
        if ([currentDocument isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            return currentDocument;
        }
        return nil;
    }
    return nil;
}

+ (IDEStructureNavigator*)xcodeProjectNavigator: (id) xcodeWindowController
{
    if ([xcodeWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)xcodeWindowController;
        IDEWorkspaceTabController *workspaceTabController = [workspaceController activeWorkspaceTabController];
        IDENavigatorArea *navigatorArea = [workspaceTabController navigatorArea];
        id currentNavigator = [navigatorArea currentNavigator];
        
        if ([currentNavigator isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
            IDEStructureNavigator *structureNavigator = currentNavigator;
            return structureNavigator;
        }
    }
    return nil;
}

+ (NSArray*)naviChildren: (id) item
{
    if ([item isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
        IDEStructureNavigator *structureNavigator = item;
        return [NSArray arrayWithArray:structureNavigator.objects];
    }
    if ([item isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")] ||
        [item isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
        IDENavigableItem *navigableItem = item;
        return [NSArray arrayWithArray:navigableItem.childItems];
    }
    return [NSArray array];
}

+ (NaviObjectType)naviObjType: (id) item
{
    if ([item isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {return NaviObjectTypeGroup;}
    if ([item isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")]) {return NaviObjectTypeContainer;}
    if ([item isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {return NaviObjectTypeNavigator;}
    if ([item isKindOfClass:NSClassFromString(@"IDEFileReferenceNavigableItem")]) {return NaviObjectTypeFile;}
    
    return NaviObjectTypeUnknown;
}

+ (NSString*)navigItemName: (id) item
{
    if ([item isKindOfClass:NSClassFromString(@"IDENavigableItem")]) {
        IDENavigableItem *navig = item;
        NSString* text = navig.name;
        return text;
    }
    return @"";
}

+ (NSURL*)navigItemURL: (id) item
{
    if ([item isKindOfClass:NSClassFromString(@"IDEFileNavigableItem")]) {
        IDEFileNavigableItem *fileItem = item;
        return fileItem.fileURL;
    }
    return nil;
}

@end