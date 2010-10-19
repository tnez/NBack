//
//  RRFNBackImageView.m
//  NBack
//
//  Created by Travis Nesland on 10/14/10.
//  Copyright 2010 smoooosh software. All rights reserved.
//

#import "RRFNBackImageView.h"


@implementation RRFNBackImageView

@synthesize cue;

#pragma mark IMAGE AND DRAWING CODE

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here...
    [[self image] drawInRect:[self bounds] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];

}

- (void)setCue: (NSImage *)newCue {
    // set the image using new cue
    [self setImage:newCue];
    [self setImageFrameStyle:NSImageFramePhoto];
    [self setImageScaling:NSScaleProportionally];
    [self setImageAlignment:NSImageAlignCenter];
    
    // update display
    [self setNeedsDisplay];
}

#pragma mark EVENT HANDLING

- (BOOL)acceptsFirstResponser {
    return YES;
}

- (void)keyDown: (NSEvent *)theEvent {
    if([[theEvent characters] isEqualToString:@"1"]) {
        [delegate subjectAffirms: self];
    }
    if([[theEvent characters] isEqualToString:@"3"]) {
        [delegate subjectDenies: self];
    }
}

@end
