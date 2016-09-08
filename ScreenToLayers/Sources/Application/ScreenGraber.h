//
//  ScreenGraber.h
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

@import Cocoa;

extern NSString * const AppNameKey;
extern NSString * const WindowOriginKey;
extern NSString * const WindowSizeKey;
extern NSString * const WindowIDKey;
extern NSString * const WindowLevelKey;
extern NSString * const WindowOrderKey;

typedef NS_ENUM(NSUInteger, SingleWindowOptions) {
    SingleWindowOptionsAboveOnly     = 0,
    SingleWindowOptionsAboveIncluded = 1,
    SingleWindowOptionsOnly          = 2,
    SingleWindowOptionsBelowIncluded = 3,
    SingleWindowOptionsBelowOnly     = 4
};

@interface ScreenGraber : NSObject

#pragma mark Windows list

- (void)updateWindowList;
- (NSString *)nameOfWindowAtIndex:(NSInteger)index;
@property (readonly, strong, nonatomic) NSArray *windowList;

#pragma mark Grab screenshots

- (CGImageRef)newScreenshot;
- (CGImageRef)newScreenshotForWindowIndex:(NSInteger)index;
- (CGImageRef)newScreenshotForWindowsSelection:(NSIndexSet *)selection;
    
- (NSImage *)screenshot;
- (NSImage *)screenshotForWindowIndex:(NSInteger)index;
- (NSImage *)screenshotForWindowsSelection:(NSIndexSet *)selection;

#pragma mark Save screen

- (BOOL)saveScreenAsPSDToFileURL:(NSURL *)fileURL;

#pragma mark Settings

@property (nonatomic, getter=isTightFit) BOOL tightFit;
@property (nonatomic, getter=isImageOpaque) BOOL imageOpaque;
@property (nonatomic, getter=isShadowsOnly) BOOL shadowsOnly;
@property (nonatomic, getter=isCursorOnTop) BOOL cursorOnTop;
@property (nonatomic, getter=isDesktopWindowsEnabled) BOOL desktopWindowsEnabled;
@property (nonatomic, getter=isFramingEffectsEnabled) BOOL framingEffectsEnabled;
@property (nonatomic, getter=isOffscreenWindowsEnabled) BOOL offscreenWindowsEnabled;
- (void)setSingleWindowOptions:(SingleWindowOptions)windowOptions;

@end
