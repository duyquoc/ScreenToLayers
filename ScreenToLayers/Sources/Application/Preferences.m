//
//  Preferences.m
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "Preferences.h"
#import "Constants.h"

#pragma mark - Preferences Private

@interface Preferences ()

@property (weak) IBOutlet NSTextField *exportDirectoryLabel;
@property (weak) IBOutlet NSButton *startLoginCheckBox;

@end

#pragma mark - Preferences Implementation

@implementation Preferences

#pragma mark Singleton

+ (instancetype)sharedInstance {
    static Preferences *preferences = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preferences = [[self alloc] initWithWindowNibName:@"Preferences"];
    });
    return preferences;
}

#pragma mark Initializer

- (void)awakeFromNib {
    [super awakeFromNib];
    [self updateExportDirectoryLabel];
    [self updateStartAtLoginCheckBox];
}

#pragma mark Defaults

+ (BOOL)setupDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSInteger count = [ud integerForKey:LaunchCountKey];
    [ud setInteger:(count + 1) forKey:LaunchCountKey];
    
    if (count == 0) {
        [ud setBool:NO forKey:AutoLoginAtStartupKey];
        [ud setBool:YES forKey:AutoOpenFolderKey];
        [ud setBool:NO forKey:AutoOpenScreenshotKey];
        [ud setBool:YES forKey:PlayTimerSoundKey];
        [ud setBool:YES forKey:PlayFlashSoundKey];
    }
    
    return [ud synchronize];
}

+ (BOOL)shouldAutoLoginAtStartup {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:AutoLoginAtStartupKey];
}

+ (BOOL)shouldAutoOpenScreenshot {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:AutoOpenScreenshotKey];
}

+ (BOOL)shouldAutoOpenFolder {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:AutoOpenFolderKey];
}

+ (BOOL)shouldPlayTimerSound {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:PlayTimerSoundKey];
}

+ (BOOL)shouldPlayFlashSound {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:PlayFlashSoundKey];
}

+ (NSInteger)launchCount {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud integerForKey:LaunchCountKey];
}

#pragma mark Export URL

static BOOL _isDefaultExportDirectory;
static NSURL *_exportDirectoryURL;

+ (NSURL *)restoreDefaultExportDirectoryURL {
    NSSearchPathDirectory dir = NSPicturesDirectory;
    NSSearchPathDomainMask mask = NSUserDomainMask;
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(dir, mask, YES);
    NSString *path = [allPaths firstObject];
    path = [path stringByAppendingPathComponent:ApplicationName];
    
    _exportDirectoryURL = [[NSURL alloc] initFileURLWithPath:path];
    _isDefaultExportDirectory = YES;
    
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject: nil forKey:ExportDirectoryDataKey];
    
    return _exportDirectoryURL;
}

+ (void)setExportDirectoryURL:(NSURL *)URL {
    if (_exportDirectoryURL && !_isDefaultExportDirectory) {
        [_exportDirectoryURL stopAccessingSecurityScopedResource];
        _exportDirectoryURL = nil;
    }
    
    _exportDirectoryURL = URL;
    _isDefaultExportDirectory = NO;
    
    NSError *error;
    NSData *data = [URL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                            includingResourceValuesForKeys:nil
                                            relativeToURL:nil
                                                    error:&error];
    
    if (error || !URL.startAccessingSecurityScopedResource) {
        [Preferences showRestoreExportDirectoryAlert];
        [Preferences restoreDefaultExportDirectoryURL];
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:data forKey:ExportDirectoryDataKey];
    [ud synchronize];
}

+ (NSURL *)exportDirectoryURL {
    if (_exportDirectoryURL) {
        return _exportDirectoryURL;
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSData *data = [ud dataForKey:ExportDirectoryDataKey];
    if (!data) {
        return [self restoreDefaultExportDirectoryURL];
    }
    
    BOOL isStale;
    NSError *error;
    _isDefaultExportDirectory = NO;
    NSURLBookmarkFileCreationOptions opt;
    opt = NSURLBookmarkResolutionWithSecurityScope;
    _exportDirectoryURL = [NSURL URLByResolvingBookmarkData:data
                                                    options:opt
                                              relativeToURL:nil
                                        bookmarkDataIsStale:&isStale
                                                      error:&error];
    
    if (error || isStale) {
        [Preferences showRestoreExportDirectoryAlert];
        [Preferences restoreDefaultExportDirectoryURL];
        return _exportDirectoryURL;
    }
    
    [_exportDirectoryURL startAccessingSecurityScopedResource];
    return _exportDirectoryURL;
}

#pragma mark UI

- (void)updateExportDirectoryLabel {
    NSString *path = [Preferences exportDirectoryURL].path;
    path = [path stringByAbbreviatingWithTildeInPath];
    self.exportDirectoryLabel.stringValue = path;
}

- (void)updateStartAtLoginCheckBox {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL state = [ud boolForKey:AutoLoginAtStartupKey];
    self.startLoginCheckBox.state = state ? NSOnState : NSOffState;
}

+ (void)showRestoreExportDirectoryAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"An error ocurred";
    alert.informativeText = @"The app will restore the default export directory.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

+ (void)showLaunchAtStartupAlert:(BOOL)state {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"An error ocurred";
    [alert addButtonWithTitle:@"OK"];
    alert.informativeText = [NSString stringWithFormat:
                             @"Couldn't %@ %@ from login item list.",
                             state ? @"add" : @"remove",
                             ApplicationName];
    [alert runModal];
}

#pragma mark Actions

- (IBAction)toogleLaunchAtStartup:(id)sender {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    BOOL state = ![ud boolForKey:AutoLoginAtStartupKey];
    CFStringRef identifier = (__bridge CFStringRef)ApplicationHelperID;
    Boolean res = SMLoginItemSetEnabled(identifier, state);
    
    if (res) {
        [ud setBool:state forKey:AutoLoginAtStartupKey];
        [ud synchronize];
    } else {
        [Preferences showLaunchAtStartupAlert:state];
    }
    
    [self updateStartAtLoginCheckBox];
}

- (IBAction)chooseExportDirectory:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canCreateDirectories = YES;
    panel.canChooseFiles = NO;
    panel.allowsMultipleSelection = NO;
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }
        [Preferences setExportDirectoryURL:panel.URL];
        [self updateExportDirectoryLabel];
    }];
}

- (IBAction)resetExportDirectory:(id)sender {
    [Preferences restoreDefaultExportDirectoryURL];
    [self updateExportDirectoryLabel];
}

@end
