//
//  RRFNBackImageView.h
//  NBack
//
//  Created by Travis Nesland on 10/14/10.
//  Copyright 2010 smoooosh software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RRFNBackImageView : NSImageView {
    NSImage                                 *cue;
}
@property (assign)          NSImage         *cue;
@end
