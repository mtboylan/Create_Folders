//
//  main.m
//  Create Folders
//
//  Created by Boylan, Matthew on 4/15/13.
//  Copyright (c) 2013 Our Sunday Visitor. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, (const char **)argv);
}
