////////////////////////////////////////////////////////////
//  RRFNBackController.m
//  RRFNBack
//  --------------------------------------------------------
//  Author: Travis Nesland
//  Created: 10/7/10
//  Copyright 2010, Residential Research Facility,
//  University of Kentucky. All Rights Reserved.
/////////////////////////////////////////////////////////////
#import "RRFNBackController.h"

@implementation RRFNBackController
@synthesize delegate,definition,errorLog,view; // add any member that has a property

#pragma mark HOUSEKEEPING METHODS
/**
 Give back any memory that may have been allocated by this bundle
 */
- (void)dealloc {
    [errorLog release]; errorLog=nil;
    // any additional release calls go here
    // ------------------------------------
    [availableCues release]; availableCues=nil;
    [blockSet release]; blockSet=nil;
    [block release]; block=nil;
    [super dealloc];
}

#pragma mark REQUIRED PROTOCOL METHODS

/**
 Start the component - will receive this message from the component controller
 */
- (void)begin {
    
}

/**
 Return a string representation of the data directory
 */
- (NSString *)dataDirectory {
    return [[definition valueForKey:RRFNBackDataDirectoryKey] stringByStandardizingPath];
}

/**
 Return a string object representing all current errors in log form
 */
- (NSString *)errorLog {
    return errorLog;
}

/**
 Perform any and all error checking required by the component - return YES if passed
 */
- (BOOL)isClearedToBegin {
    return YES; // this is the default; change as needed
}

/**
 Returns the file name containing the raw data that will be appended to the data file
 */
- (NSString *)rawDataFile {
    return [delegate defaultTempFile]; // this is the default implementation
}

/**
 Perform actions required to recover from crash using the given raw data passed as string
 */
- (void)recover {
    // if no recovery is needed, nothing need be done here
}

/**
 Accept assignment for the component definition
 */
- (void)setDefinition: (NSDictionary *)aDictionary {
    definition = aDictionary;
}

/**
 Accept assignment for the component delegate - The component controller will assign itself as the delegate
 Note: The new delegate must adopt the TKComponentBundleDelegate protocol
 */
- (void)setDelegate: (id <TKComponentBundleDelegate> )aDelegate {
    delegate = aDelegate;
}

/**
 Perform any and all initialization required by component - load any nib files and perform all required initialization
 */
- (void)setup {

    // --- RESET ERROR LOG
    [self setErrorLog:@""];

    // --- LOAD CUES
    [self loadCues];
    
    // --- LOAD BLOCK SET
    [self loadNewBlockSet];
    
    // --- LOAD BLOCK
    [self loadNewBlock];

    // --- LOAD NIB
    if([NSBundle loadNibNamed:RRFNBackMainNibNameKey owner:self]) {
        // interface initialization can go here
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        
    } else {
        // nib did not load
        [self registerError:@"Could not load Nib file"];
    }
}

/**
 Return YES if component should perform recovery actions
 */
- (BOOL)shouldRecover {
    return NO;  // this is the default; change if needed
}

/**
 Perform any and all finalization required by component
 */
- (void)tearDown {
    // any finalization should be done here:
    // - remove any temporary data files
}

/**
 Return the name of the current task
 */
- (NSString *)taskName {
    return [definition valueForKey:RRFNBackTaskNameKey];
}

/**
 Return the main view that should be presented to the subject
 */
- (NSView *)mainView {
    return view;
}

#pragma mark OPTIONAL PROTOCOL METHODS
/** Uncomment and implement the following methods if desired */
/**
 Run header if something other than default is required
 */
//- (NSString *)runHeader {
//
//}
/**
 Session header if something other than default is required
 */
//- (NSString *)sessionHeader {
//
//}
/**
 Summary data if desired
 */
//- (NSString *)summary {
//
//}

        
        

#pragma mark UTILITY METHODS
/** Add additional methods required for operation */
- (void)registerError: (NSString *)theError {
    // append the new error to the error log
    [self setErrorLog:[[errorLog stringByAppendingString:theError] stringByAppendingString:@"\n"]];
}

        

#pragma mark (ADD) STATES
/** Start the next cue if one exists */
- (void)nextCue {
    
}

/** Start the next block if one exists */
- (void)nextBlock {
    
}

/** Start the next block set if one exists */
- (void)nextBlockSet {
    
}

/** Start the ITI (inter-trial interval) */
- (void)ITI {
    
}

/** Start the IBI (inter-block interval) */
- (void)IBI {
    
}



#pragma mark (ADD) INITIALIZATION
/** Load cue images into memory - also register any errors encounterd
    @return YES on success, NO on failure
 */
- (BOOL)loadCues {
    
    // if no cue directory was provided throw error and return
    if([[definition valueForKey:RRFNBackCueDirectoryKey] isEqualToString:@""] ||
        [definition valueForKey:RRFNBackCueDirectoryKey] == nil) {
        [self registerError:@"No cue directory provided"];
        return NO;
    }

    // try to get the file paths for all the image files
    NSError *myError = nil;
    NSArray *tempCues = nil;        
    tempCues = [[[NSFileManager defaultManager]
                 contentsOfDirectoryAtPath:[definition valueForKey:RRFNBackCueDirectoryKey] error:&myError] retain];
    // if there was an error getting the file names...
    if(myError) {
        [self registerError:[NSString stringWithFormat:@"Could not load cues from Directory: %@\n%@",
                             [definition valueForKey:RRFNBackCueDirectoryKey],
                             [myError localizedDescription]]];
        // since we are going to return, we must first relase our temp objects
        [tempCues release];
        [myError release];
        return NO;
    }
    
    // if we've made it here we've at least loaded file paths for the images
    // ...begin error checking those images
    // ...create a temporary heap on which to pile cues
    NSMutableArray *heap = [[NSMutableArray alloc] init];
    
    // add images to the heap if valid
    NSImage *image;
    for(NSString *img_path in tempCues) {
        // stop processing if this is a hidden file (begins with dot)
        if([img_path hasPrefix:@"."]) {
            continue;   // go to next iteration of for loop
        }
        image = [[NSImage alloc] initByReferencingFile:
                             [[definition valueForKey:RRFNBackCueDirectoryKey] stringByAppendingPathComponent:img_path]];
        if([image isValid]) {
            // if the image is valid add it to the heap
            [heap addObject:image];
            // and set the name of the image to file name
            [image setName:[img_path stringByDeletingPathExtension]];
        } else {
            // else, register the error
            [self registerError:[NSString stringWithFormat:@"Could not load image file: %@",img_path]];
        }
        // release the image object (it will be held on to by the array)
        [image release];
    }
    
    // move cues from heap to their permanent storage array
    availableCues = [[NSArray alloc] initWithArray:(NSArray *)heap];
    
    // report if there are less than two cues . . . if so, n-back will not make sense
    if([availableCues count] < 2) {
        [self registerError:@"Less than two cues have been loaded, this is problematic"];
    }
    
    // release remaining temporary objects
    [heap release];
    [tempCues release];
    
    // return success (even if non-fatal errors have been reported)
    return YES;
}

/** Create a new block set - register any errors encounterd
    @return YES on success, NO on failure
 */
- (BOOL)loadNewBlockSet {

    // get our min and max condition values
    NSInteger min_n = [[definition valueForKey:RRFNBackMinNConditionKey] integerValue];
    NSInteger max_n = [[definition valueForKey:RRFNBackMaxNConditionKey] integerValue];
    
    // perform checks on min and max values
    if( max_n < min_n || min_n < 0 ) {
        [self registerError:@"Could not create block set - Max and/or Min values are invalid"];
        return NO;
    }

    // create a simple mutable array [0,1,2,3] representing n-back conditions
    // ----------------------------------------------------------------------
    // ... release our old block set (if any)
    [blockSet release]; blockSet = nil;
    // ... create new (empty) block set
    blockSet = [[NSMutableArray alloc] init];
    
    // ... for n-values min through max ...
    for(NSInteger i = min_n; i <= max_n; i++) {
        // add the value to our block set
        [blockSet addObject:[NSNumber numberWithInteger:i]];
    }
    
    return YES;
}

/** Create a new block - register any errors encounterd
    @return YES on success, NO on failure
 */
- (BOOL)loadNewBlock {

    // grab values for trials and targets
    NSInteger trials = [[definition valueForKey:RRFNBackTrialCountKey] integerValue];
    NSInteger targets = [[definition valueForKey:RRFNBackTargetCountKey] integerValue];
    
    // release old block if one exists
    [block release]; block = nil;
    
    // create new (empty) mutable arrray to hold temp cues
    NSMutableArray *tempBlock = nil;
    tempBlock = [[NSMutableArray alloc] init];
    
    // populate temp block with random sequence of images
    NSInteger selectedCue = (NSInteger)nil;
    // ... for each intended trial ...
    for(NSInteger i=0; i<trials; i++) {
        // ...grab a cue at random and put into next spot in block
        selectedCue = arc4random()%[availableCues count];
        // TODO: remove debug line
        [tempBlock addObject:[availableCues objectAtIndex:selectedCue]];
        NSLog(@"Selected Cue: %@ From Index: %d",[[tempBlock objectAtIndex:i] name],selectedCue);
    }
    
    // TODO: check array for unintentional n-backs
    
    
    // TODO: populate targets
    
    [tempBlock release]; tempBlock = nil;
    return YES;
}




#pragma mark Preference Keys
// HERE YOU DEFINE KEY REFERENCES FOR ANY PREFERENCE VALUES
// ex: NSString * const RRFNBackNameOfPreferenceKey = @"RRFNBackNameOfPreference"
NSString * const RRFNBackTaskNameKey = @"RRFNBackTaskName";
NSString * const RRFNBackDataDirectoryKey = @"RRFNBackDataDirectory";
NSString * const RRFNBackBlockSetCountKey = @"RRFNBackBlockSetCount";
NSString * const RRFNBackCueDirectoryKey = @"RRFNBackCueDirectory";
NSString * const RRFNBackCueDurationKey = @"RRFNBackCueDuration";
NSString * const RRFNBackInterBlockDurationKey = @"RRFNBackInterBlockDuration";
NSString * const RRFNBackInterTrialDurationKey = @"RRFNBackInterTrialDuration";
NSString * const RRFNBackMaxNConditionKey = @"RRFNBackMaxNCondition";
NSString * const RRFNBackMinNConditionKey = @"RRFNBackMinNCondition";
NSString * const RRFNBackResponseTypeKey = @"RRFNBackResponseType";
NSString * const RRFNBackTargetCountKey = @"RRFNBackTargetCount";
NSString * const RRFNBackTrialCountKey = @"RRFNBackTrialCount";




#pragma mark Internal Strings
// HERE YOU DEFINE KEYS FOR CONSTANT STRINGS //
///////////////////////////////////////////////
NSString * const RRFNBackMainNibNameKey = @"RRFNBackMainNib";
        
       
        
@end
