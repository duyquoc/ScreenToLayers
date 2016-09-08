//
//  ListController.m
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "ListController.h"
#import "ScreenGraber.h"

static void *ListControllerKVOContext = &ListControllerKVOContext;

#pragma mark - ListController Private

@interface ListController () {
	IBOutlet NSImageView *outputView;
	IBOutlet NSArrayController *arrayController;
}

@property (strong) ScreenGraber *graber;
@property (weak) IBOutlet NSButton *listOffscreenWindows;
@property (weak) IBOutlet NSButton *listDesktopWindows;
@property (weak) IBOutlet NSButton *imageFramingEffects;
@property (weak) IBOutlet NSButton *imageOpaqueImage;
@property (weak) IBOutlet NSButton *imageShadowsOnly;
@property (weak) IBOutlet NSButton *imageTightFit;
@property (weak) IBOutlet NSMatrix *singleWindow;

@end

#pragma mark - ListController Implementation

@implementation ListController

#pragma mark Singleton

+ (instancetype)sharedController {
    static ListController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[self alloc] initWithWindowNibName:@"ListWindow"];
    });
    return controller;
}

#pragma mark Initializers

- (void)dealloc {
    [arrayController removeObserver:self forKeyPath:@"selectionIndexes"];
}

- (void)awakeFromNib {
    self.graber = [[ScreenGraber alloc] init];
    self.graber.tightFit = YES;
    
    [arrayController addObserver:self
                      forKeyPath:@"selectionIndexes"
                         options:0
                         context:&ListControllerKVOContext];
    
    
    [[self window] makeKeyAndOrderFront:self];
    [self performSelectorOnMainThread:@selector(updateWindowList)
                           withObject:self
                        waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(updateImageWithAllScreen)
                           withObject:self
                        waitUntilDone:NO];
}

#pragma mark Update data

- (void)updateWindowList {
    [self.graber updateWindowList];
    arrayController.content = self.graber.windowList;
}

- (void)updateImageWithSelection {
    NSImage *image = nil;
	NSIndexSet *selection = [arrayController selectionIndexes];
    if([selection count] == 1) {
        image = [self.graber screenshotForWindowIndex:selection.firstIndex];
	} else if ([selection count] != 0){
        image = [self.graber screenshotForWindowsSelection:selection];
	}
    outputView.image = image;
}

- (void)updateImageWithAllScreen {
    outputView.image = [self.graber screenshot];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if (context == &ListControllerKVOContext) {
        [_singleWindow setEnabled:[[arrayController selectedObjects] count] <= 1];
        [self updateImageWithSelection];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Actions

- (IBAction)toggleOffscreenWindows:(id)sender {
    self.graber.offscreenWindowsEnabled = ([sender intValue] == NSOnState);
	[self updateWindowList];
	[self updateImageWithSelection];
}

- (IBAction)toggleDesktopWindows:(id)sender {
    self.graber.desktopWindowsEnabled = ([sender intValue] == NSOnState);
	[self updateWindowList];
    [self updateImageWithSelection];
}

- (IBAction)toggleFramingEffects:(id)sender {
    self.graber.framingEffectsEnabled = ([sender intValue] == NSOnState);
	[self updateImageWithSelection];
}

- (IBAction)toggleOpaqueImage:(id)sender {
    self.graber.imageOpaque = ([sender intValue] == NSOnState);
	[self updateImageWithSelection];
}

- (IBAction)toggleShadowsOnly:(id)sender {
    self.graber.shadowsOnly = ([sender intValue] == NSOnState);
	[self updateImageWithSelection];
}

- (IBAction)toggleTightFit:(id)sender {
    self.graber.tightFit = ([sender intValue] == NSOnState);
	[self updateImageWithSelection];
}

- (IBAction)updateSingleWindowOption:(id)sender {
    [self.graber setSingleWindowOptions:[_singleWindow selectedRow]];
	[self updateImageWithSelection];
}

- (IBAction)grabScreenShot:(id)sender {
    arrayController.selectionIndexes = [[NSIndexSet alloc] init];
	[self updateImageWithAllScreen];
}

- (IBAction)refreshWindowList:(id)sender {
	[self updateWindowList];
	[self updateImageWithSelection];
}

- (IBAction)exportImage:(id)sender {
    NSImage *image = outputView.image;
    if (!image) {
        NSBeep();
        return;
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    [panel setAllowedFileTypes:@[@"png"]];
    [panel beginSheetModalForWindow:[self window]  completionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }
        
        CGRect imageRect;
        CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:nil hints:nil];
        NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
        NSData *pngData = [imageRep representationUsingType:NSPNGFileType properties:@{}];
        [pngData writeToURL:panel.URL atomically:YES];
     }];
}

@end
