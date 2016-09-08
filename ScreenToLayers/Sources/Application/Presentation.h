//
//  Presentation.h
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

@interface Presentation : NSWindowController

#pragma mark Singleton

+ (instancetype)sharedInstance;

@end
