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
    // set image size equal to frame size
    [cue setSize:[[self frame] size]];
    // draw the image
    [cue drawInRect:[self frame] fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    
}

- (void)setCue: (NSImage *)newCue {
    // point to the new cue
    cue = newCue;
    // update screen
    [self setNeedsDisplay:YES];
    
}

#pragma mark EVENT HANDLING

- (BOOL)acceptsFirstResponser {
    return YES;
}

@end
