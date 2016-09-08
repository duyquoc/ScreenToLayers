//
//  AppController.h
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface AppController : NSObject <NSApplicationDelegate>

#pragma mark Actions

- (IBAction)grabScreenshot:(id)sender;
- (IBAction)grabScreenshotWithDelay:(id)sender;
- (IBAction)openOutputsFolder:(id)sender;
- (IBAction)showWindowsList:(id)sender;

- (IBAction)contactCustomerSupport:(id)sender;
- (IBAction)openApplicationWebsite:(id)sender;
- (IBAction)openAppStorePage:(id)sender;
- (IBAction)openGitHubPage:(id)sender;

- (IBAction)showPreferences:(id)sender;
- (IBAction)showPresentation:(id)sender;

@end
