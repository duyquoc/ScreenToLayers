//
//  AppDelegate.m
//  ScreenToLayersHelper
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "AppDelegate.h"
#import "Constants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:ApplicationID]) {
            alreadyRunning = YES;
            break;
        }
    }
    
    if (!alreadyRunning) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSMutableArray *components = [[path pathComponents] mutableCopy];
        [components removeLastObject]; // Helper app name
        [components removeLastObject]; // LoginItems folder
        [components removeLastObject]; // Library folder
        [components removeLastObject]; // Contents folder
        [components removeLastObject]; // Main app folder
        [components addObject:[ApplicationName stringByAppendingPathExtension:@"app"]];
        NSString *newPath = [NSString pathWithComponents:components];
        [[NSWorkspace sharedWorkspace] launchApplication:newPath];
    }
    [NSApp terminate:nil];
}

@end
