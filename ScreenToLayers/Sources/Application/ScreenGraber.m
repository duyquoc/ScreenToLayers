//
//  ScreenGraber.m
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "ScreenGraber.h"
#import "PSDWriter.h"

NSString * const AppNameKey      = @"applicationName";
NSString * const WindowOriginKey = @"windowOrigin";
NSString * const WindowSizeKey   = @"windowSize";
NSString * const WindowIDKey     = @"windowID";
NSString * const WindowLevelKey  = @"windowLevel";
NSString * const WindowOrderKey  = @"windowOrder";

#pragma mark - Helpers

static inline
void ChangeBits(uint32_t *currentBits, uint32_t flagsToChange, BOOL setFlags) {
    if(setFlags) {
        *currentBits = *currentBits | flagsToChange;
    } else {
        *currentBits = *currentBits & ~flagsToChange;
    }
}

#pragma mark - ScreenGraber Private

@interface ScreenGraber ()

@property (assign) CGRect imageBounds;
@property (assign) CGWindowListOption listOptions;
@property (assign) CGWindowListOption windowOptions;
@property (assign) CGWindowImageOption imageOptions;
@property (strong) NSMutableArray *prunedWindowList;

@end

#pragma mark - ScreenGraber Implementation

@implementation ScreenGraber

- (instancetype)init {
    self = [super init];
    if (self) {
        self.imageBounds = CGRectInfinite;
        self.listOptions = kCGWindowListOptionOnScreenOnly;
        self.imageOptions = 0;
        self.windowOptions = kCGWindowListOptionIncludingWindow;
        self.prunedWindowList = [NSMutableArray array];
    }
    return self;
}

#pragma mark Image generation

static
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    ScreenGraber *grabber = (__bridge ScreenGraber *)context;
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if (sharingState == kCGWindowSharingNone) {
        return;
    }
    
    NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
    outputEntry[AppNameKey] = [NSString stringWithFormat:@"%@ (%@)",
                                entry[(id)kCGWindowOwnerName] ?: @"((unknwown))",
                                entry[(id)kCGWindowOwnerPID]];;
    
    CGRect bounds;
    CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)entry[(id)kCGWindowBounds], &bounds);
    outputEntry[WindowOriginKey] = [NSString stringWithFormat:@"%.0f/%.0f",
                                    bounds.origin.x,
                                    bounds.origin.y];
    outputEntry[WindowSizeKey] = [NSString stringWithFormat:@"%.0f*%.0f",
                                  bounds.size.width,
                                  bounds.size.height];
    
    outputEntry[WindowIDKey] = entry[(id)kCGWindowNumber];
    outputEntry[WindowLevelKey] = entry[(id)kCGWindowLayer];
    outputEntry[WindowOrderKey] = @(grabber.prunedWindowList.count);
    
    [grabber.prunedWindowList addObject:outputEntry];
}

- (CFArrayRef)newWindowListFromSelectedObjects:(NSArray *)selectedObjects {
    NSArray *sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:WindowOrderKey ascending:YES]];
    NSArray *sortedSelection = [selectedObjects sortedArrayUsingDescriptors:sortDescriptors];
    
    NSInteger i = 0, count = [sortedSelection count];
    const void *windowIDs[count];
    for (NSMutableDictionary *entry in sortedSelection) {
        windowIDs[i++] = (void *)[entry[WindowIDKey] unsignedIntegerValue];
    }
    
    CFArrayRef windowIDsArray = CFArrayCreate(kCFAllocatorDefault,
                                              (const void **)windowIDs,
                                              [sortedSelection count],
                                              NULL);
    return windowIDsArray;
}

#pragma mark Windows list

- (void)updateWindowList {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(self.listOptions, kCGNullWindowID);
    [self.prunedWindowList removeAllObjects];
    CFArrayApplyFunction(windowList,
                         CFRangeMake(0, CFArrayGetCount(windowList)),
                         &WindowListApplierFunction,
                         (__bridge void *)(self));
    CFRelease(windowList);
}

- (NSString *)nameOfWindowAtIndex:(NSInteger)index {
    return self.prunedWindowList[index][AppNameKey];
}

- (NSArray *)windowList {
    return self.prunedWindowList;
}

#pragma mark Grab screenshot

- (CGImageRef)newScreenshot {
    CGImageRef imageRef = CGWindowListCreateImage(CGRectInfinite,
                                                  kCGWindowListOptionOnScreenOnly,
                                                  kCGNullWindowID,
                                                  kCGWindowImageDefault);
    return imageRef;
}

- (CGImageRef)newScreenshotForWindowIndex:(NSInteger)index {
    NSDictionary *windowDict = self.prunedWindowList[index];
    CGWindowID windowID = (CGWindowID)[windowDict[WindowIDKey] unsignedIntegerValue];
    CGImageRef imageRef = CGWindowListCreateImage(self.imageBounds,
                                                  self.windowOptions,
                                                  windowID,
                                                  self.imageOptions);
    return imageRef;
}

- (CGImageRef)newScreenshotForWindowsSelection:(NSIndexSet *)selection {
    NSArray *objects = [self.prunedWindowList objectsAtIndexes:selection];
    CFArrayRef windowIDs = [self newWindowListFromSelectedObjects:objects];
    CGImageRef imageRef = CGWindowListCreateImageFromArray(self.imageBounds,
                                                           windowIDs,
                                                           self.imageOptions);
    CFRelease(windowIDs);
    return imageRef;
}

- (NSImage *)screenshot {
    CGImageRef imageRef = [self newScreenshot];
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    CGImageRelease(imageRef);
    return image;
}

- (NSImage *)screenshotForWindowIndex:(NSInteger)index {
    CGImageRef imageRef = [self newScreenshotForWindowIndex:index];
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    CGImageRelease(imageRef);
    return image;
}

- (NSImage *)screenshotForWindowsSelection:(NSIndexSet *)selection {
    CGImageRef imageRef = [self newScreenshotForWindowsSelection:selection];
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    CGImageRelease(imageRef);
    return image;
}

#pragma mark Save screen

- (BOOL)saveScreenAsPSDToFileURL:(NSURL *)fileURL {
    CGFloat scaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    NSRect frame = [[NSScreen mainScreen] frame];
    frame.size.width *= scaleFactor;
    frame.size.height *= scaleFactor;
    
    [self updateWindowList];
    PSDWriter *writer = [[PSDWriter alloc] initWithDocumentSize:frame.size];
    
    CGImageRef imageRef = [self newScreenshot];
    writer.flattenedData = CGImageGetData(imageRef);
    CGImageRelease(imageRef);
    
    
    for (NSInteger i = self.windowList.count - 1; i >= 0; i--) {
        NSString *name = [self nameOfWindowAtIndex:i];
        imageRef = [self newScreenshotForWindowIndex:i];
        [writer addLayerWithCGImage:imageRef andName:name andOpacity:1.0 andOffset:CGPointZero];
        CGImageRelease(imageRef);
    }
    
    if (self.cursorOnTop) {
        CGPoint offset = [NSEvent mouseLocation];
        offset = CGPointMake(offset.x * scaleFactor, offset.y * scaleFactor);
        offset.y = [NSScreen mainScreen].frame.size.height * scaleFactor - offset.y;
        NSImage *image = [NSCursor currentCursor].image;
        CGImageRef imageRef = [image CGImageForProposedRect:NULL context:nil hints:nil];
        [writer addLayerWithCGImage:imageRef andName:@"Cursor" andOpacity:1.0 andOffset:offset];
    }
    
    NSData *psdData = [writer createPSDData];
    if (!psdData) {
        NSLog(@"Cannot create PSD file from screen.");
        return NO;
    }
    if (![psdData writeToURL:fileURL atomically:YES]) {
        NSLog(@"Cannot write PSD file at URL %@", fileURL);
        return NO;
    }
    
    return YES;
}

#pragma mark Settings

- (void)setOffscreenWindowsEnabled:(BOOL)flag {
    ChangeBits(&_listOptions, kCGWindowListOptionOnScreenOnly, !flag);
}

- (BOOL)isOffscreenWindowsEnabled {
    return !(_listOptions & kCGWindowListOptionOnScreenOnly);
}

- (void)setDesktopWindowsEnabled:(BOOL)flag {
    ChangeBits(&_listOptions, kCGWindowListExcludeDesktopElements, !flag);
}

- (BOOL)isDesktopWindowsEnabled {
    return !(_listOptions & kCGWindowListExcludeDesktopElements);
}

- (void)setFramingEffectsEnabled:(BOOL)flag {
    ChangeBits(&_imageOptions, kCGWindowImageBoundsIgnoreFraming, flag);
}

- (BOOL)isFramingEffectsEnabled {
    return (_imageOptions & kCGWindowImageBoundsIgnoreFraming);
}

- (void)setImageOpaque:(BOOL)flag {
    ChangeBits(&_imageOptions, kCGWindowImageShouldBeOpaque, flag);
}

- (BOOL)isImageOpaque {
    return (_imageOptions & kCGWindowImageShouldBeOpaque);
}

- (void)setShadowsOnly:(BOOL)flag {
    ChangeBits(&_imageOptions, kCGWindowImageOnlyShadows, flag);
}

- (BOOL)isShadowsOnly {
    return (_imageOptions & kCGWindowImageOnlyShadows);
}

- (void)setTightFit:(BOOL)flag {
    _imageBounds = (flag) ? CGRectNull : CGRectInfinite;
}

- (BOOL)isTightFit {
    return CGRectIsNull(_imageBounds);
}

- (void)setSingleWindowOptions:(SingleWindowOptions)windowOptions {
    CGWindowListOption options = 0;
    switch(windowOptions) {
        case SingleWindowOptionsAboveOnly:
            options = kCGWindowListOptionOnScreenAboveWindow;
            break;
        case SingleWindowOptionsAboveIncluded:
            options = kCGWindowListOptionOnScreenAboveWindow | kCGWindowListOptionIncludingWindow;
            break;
        case SingleWindowOptionsOnly:
            options = kCGWindowListOptionIncludingWindow;
            break;
        case SingleWindowOptionsBelowIncluded:
            options = kCGWindowListOptionOnScreenBelowWindow | kCGWindowListOptionIncludingWindow;
            break;
        case SingleWindowOptionsBelowOnly:
            options = kCGWindowListOptionOnScreenBelowWindow;
            break;
        default:
            break;
    }
    self.windowOptions = options;
}

@end
