//
//  RRFNBackImageView.m
//  NBack
//
//  Created by Travis Nesland on 10/14/10.
//  Copyright 2010 smoooosh software. All rights reserved.
//

#import "RRFNBackImageView.h"
#import "RRFNBackController.h"


@implementation RRFNBackImageView

@synthesize cue,delegate,subjectHasAlreadyResponded;

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
    
    // if the new cue is not nil...
    if(newCue) {
        // ... reset our user has responded flag
        subjectHasAlreadyResponded = NO;
    }
}

#pragma mark EVENT HANDLING

- (BOOL)acceptsFirstResponser {
    return YES;
}

- (void)keyDown: (NSEvent *)theEvent {
    // if this is the first response for this presentation
    if(!subjectHasAlreadyResponded) {
        // ... go ahead and process the event
        if([[theEvent characters] isEqualToString:@"1"]) {
            [delegate subjectAffirms: self];
            subjectHasAlreadyResponded = YES;
            return;
        }
        if([[theEvent characters] isEqualToString:@"3"]) {
            [delegate subjectDenies: self];
            subjectHasAlreadyResponded = YES;
            return;
        }
    } else { // subject already responded to this cue...
        // ...do nothing
    }
    // if we've made it here, we don't process the event...
    // ...give it to super just in case
    [super keyDown:theEvent];
}

@end
