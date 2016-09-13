//
//  AppController.m
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "AppController.h"
#import "ListController.h"
#import "ScreenGraber.h"
#import "Presentation.h"
#import "PSDWriter.h"
#import "Preferences.h"
#import "Constants.h"

#pragma mark AppController Private

@interface AppController ()

@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong) NSStatusItem *statusItem;
@property (strong) ScreenGraber *graber;
@property (strong) NSSound *flashSound;
@property (strong) NSSound *timerSound;
@property (assign) NSInteger timerCount;
@property (strong) NSImage *defaultImage;
@property (strong) NSImage *progressImage;
@property (assign) CGFloat progressDegrees;

@end

#pragma mark AppController Implementation

@implementation AppController

#pragma mark Initializers

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timerCount = -1;
        self.graber = [[ScreenGraber alloc] init];
        self.graber.cursorOnTop = true;
        
        self.flashSound = [NSSound soundNamed:@"CaptureEndSound"];
        self.timerSound = [NSSound soundNamed:@"Tink"];
        self.timerSound.volume = 0.3;
        
        self.defaultImage = [NSImage imageNamed:@"ButtonTemplate"];
        [self updateProgressDegrees:nil];
    }
    return self;
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [Preferences setupDefaults];
    
    [self setupStatusItem];
    [self registerHotKeys];
    
    if ([Preferences launchCount] == 1) {
        [self showPreferences:nil];
        [self showPresentation:nil];
    }
}

#pragma mark Hotkeys

static OSStatus _hotKeyEventHandler(EventHandlerCallRef h, EventRef event, void *p) {
    EventHotKeyID hotKeyID;
    OSStatus err = GetEventParameter(event,
                                     kEventParamDirectObject,
                                     typeEventHotKeyID,
                                     nil,
                                     sizeof(EventHotKeyID),
                                     nil,
                                     &hotKeyID);
    if (err)
        return err;
    
    switch (hotKeyID.id) {
        case 1: [NSApp sendAction:@selector(grabScreenshot:) to:nil from:nil];          break;
        case 2: [NSApp sendAction:@selector(grabScreenshotWithDelay:) to:nil from:nil]; break;
        default: break;
    }
    return YES;
}

- (void)registerHotKeys {
    EventHotKeyRef hotKeyRef;
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType = {kEventClassKeyboard, kEventHotKeyPressed};
    
    InstallApplicationEventHandler(&_hotKeyEventHandler, 1, &eventType, NULL, NULL);
    EventTargetRef target = GetApplicationEventTarget();
    
    hotKeyID.signature='htk1';
    hotKeyID.id = 1;
    RegisterEventHotKey(kVK_ANSI_5, cmdKey+shiftKey, hotKeyID, target, 0, &hotKeyRef);
    
    hotKeyID.signature='htk2';
    hotKeyID.id = 2;
    RegisterEventHotKey(kVK_ANSI_6, cmdKey+shiftKey, hotKeyID, target, 0, &hotKeyRef);
    
}

#pragma mark Status item

- (void)setupStatusItem {
    NSStatusBar *sb = [NSStatusBar systemStatusBar];
    self.statusItem = [sb statusItemWithLength:26];
    self.statusItem.image = self.defaultImage;
    self.statusItem.menu = self.statusMenu;
    self.statusItem.highlightMode = YES;
}

- (void)updateBarWithTimer {
    self.statusItem.image = nil;
    self.statusItem.title = [NSString stringWithFormat:@"%ld", self.timerCount];
}

- (void)updateBarWithProgress {
    self.statusItem.image = self.progressImage;
    self.statusItem.title = nil;
}

- (void)restoreBarWithImage {
    self.statusItem.image = self.defaultImage;
    self.statusItem.title = nil;
}

#pragma mark Screenshot

- (NSURL *)screenshotsDirectoryURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *directoryURL = [Preferences exportDirectoryURL];
    [fm createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    return directoryURL;
}

- (NSString *)filenameForCurrentDate {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH-mm-ss";
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (NSURL *)psdURLForCurrentDate {
    NSURL *dirURL = [self screenshotsDirectoryURL];
    NSString *filename = [self filenameForCurrentDate];
    NSURL *fileURL = [dirURL URLByAppendingPathComponent:filename];
    return [fileURL URLByAppendingPathExtension:@"psd"];
}

- (void)saveScreenToFile {
    NSURL *fileURL = [self psdURLForCurrentDate];
    if (![self.graber saveScreenAsPSDToFileURL:fileURL]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"An error ocurred";
        [alert addButtonWithTitle:@"OK"];
        alert.informativeText = @"Couldn't grab the screen.";
        [alert runModal];
        return;
    }
    
    if ([Preferences shouldAutoOpenFolder]) {
        [[NSWorkspace sharedWorkspace] openURL:[self screenshotsDirectoryURL]];
    }
    if ([Preferences shouldAutoOpenScreenshot]) {
        [[NSWorkspace sharedWorkspace] openURL:fileURL];
    }
}

#pragma mark Timers

- (void)updateProgressDegrees:(NSTimer *)timer {
    CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
    NSRect rect = NSMakeRect(0.0,
                             0.0,
                             self.defaultImage.size.width * scale,
                             self.defaultImage.size.height * scale);
    NSPoint center = NSMakePoint(rect.size.width / 2.0 ,
                                 rect.size.height / 2.0);
    
    self.progressImage = [[NSImage alloc] initWithSize:rect.size];
    [self.progressImage lockFocus];
    [[NSColor blackColor] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:center
                                     radius:6.5
                                 startAngle:self.progressDegrees
                                   endAngle:self.progressDegrees + 270.0];
    [path setLineWidth:2.0];
    [path stroke];
    [self.progressImage unlockFocus];
    
    self.progressDegrees += -10.0;
    [self updateBarWithProgress];
}

- (void)updateScreenshotTimer:(NSTimer *)timer {
    if (self.timerCount != 0) {
        [self updateBarWithTimer];
        self.timerCount--;
        if ([Preferences shouldPlayTimerSound]) {
            [self.timerSound play];
        }
        return;
    }
    
    self.timerCount = -1;
    [timer invalidate];
    [self grabScreenshot: nil];
}

#pragma mark Actions

- (IBAction)grabScreenshot:(id)sender {
    if (self.timerCount != -1) {
        return;
    }
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.04
                                                      target:self
                                                    selector:@selector(updateProgressDegrees:)
                                                    userInfo:nil repeats:YES];
    
    if ([Preferences shouldPlayFlashSound]) {
        [self.flashSound play];
    }
    
    int queueId = DISPATCH_QUEUE_PRIORITY_BACKGROUND;
    dispatch_async(dispatch_get_global_queue(queueId, 0), ^{
        [self saveScreenToFile];
        dispatch_async(dispatch_get_main_queue(), ^{
            [timer invalidate];
            [self restoreBarWithImage];
        });
    });
}

- (IBAction)grabScreenshotWithDelay:(id)sender {
    if (self.timerCount != -1) {
        return;
    }
    
    self.timerCount = 5;
    [self updateBarWithTimer];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateScreenshotTimer:)
                                   userInfo:nil
                                    repeats:YES];
}

- (IBAction)openOutputsFolder:(id)sender {
    NSURL *dirURL = [self screenshotsDirectoryURL];
    [[NSWorkspace sharedWorkspace] openURL:dirURL];
}

- (IBAction)showWindowsList:(id)sender {
    [[ListController sharedController] showWindow:sender];
}

- (IBAction)showPreferences:(id)sender {
    [[Preferences sharedInstance] showWindow:sender];
}

- (IBAction)showPresentation:(id)sender {
    [[Presentation sharedInstance] showWindow:sender];
}

- (IBAction)contactCustomerSupport:(id)sender {
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNameComposeEmail];
    service.recipients = @[SupportAddress];
    service.subject = [NSString stringWithFormat:@"[%@] support", ApplicationName];
    [service performWithItems:@[]];
}

- (IBAction)openApplicationWebsite:(id)sender {
    NSURL *websiteURL = [NSURL URLWithString:WebsiteStringURL];
    [[NSWorkspace sharedWorkspace] openURL:websiteURL];
}

- (IBAction)openAppStorePage:(id)sender {
    NSURL *websiteURL = [NSURL URLWithString:AppStoreStringURL];
    [[NSWorkspace sharedWorkspace] openURL:websiteURL];
}

- (IBAction)openGitHubPage:(id)sender {
    NSURL *websiteURL = [NSURL URLWithString:GitHubStringURL];
    [[NSWorkspace sharedWorkspace] openURL:websiteURL];
}

@end
