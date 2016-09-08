//
//  Presentation.m
//  ScreenToLayers
//
//  Created by Jeremy Vizzini.
//  This software is released subject to licensing conditions as detailed in Licence.txt.
//

#import "Presentation.h"
#import "Constants.h"


#pragma mark - Presentation Private

@interface Presentation ()

@end

#pragma mark - Presentation Implementation

@implementation Presentation

#pragma mark Singleton

+ (instancetype)sharedInstance {
    static Presentation *presentation = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        presentation = [[self alloc] initWithWindowNibName:@"Presentation"];
    });
    return presentation;
}

#pragma mark Initializer

- (void)awakeFromNib {
    [super awakeFromNib];
}

@end
