//
//  Preferences.h
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

@interface Preferences : NSWindowController

#pragma mark Singleton

+ (instancetype)sharedInstance;

#pragma mark Defaults

+ (BOOL)setupDefaults;
+ (BOOL)shouldAutoLoginAtStartup;
+ (BOOL)shouldAutoOpenScreenshot;
+ (BOOL)shouldAutoOpenFolder;
+ (BOOL)shouldPlayTimerSound;
+ (BOOL)shouldPlayFlashSound;
+ (NSInteger)launchCount;
+ (NSURL *)exportDirectoryURL;

@end
