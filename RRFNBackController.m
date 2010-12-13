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
#import "RRFNBackImageView.h"

#define DATA NSDictionary dictionaryWithObjectsAndKeys:
#define oTRUE [NSNumber numberWithBool:TRUE]
#define oFALSE [NSNumber numberWithBool:FALSE]
#define TRIALS [[definition valueForKey:RRFNBackTrialCountKey] integerValue]
#define TARGETS [[definition valueForKey:RRFNBackTargetCountKey] integerValue]
#define CUE_DIRECTORY [[definition valueForKey:RRFNBackCueDirectoryKey] stringByStandardizingPath]
#define CUE_DURATION [[definition valueForKey:RRFNBackCueDurationKey] unsignedIntegerValue] * 1000
#define ITI_DURATION [[definition valueForKey:RRFNBackInterTrialDurationKey] unsignedIntegerValue] * 1000
#define IBI_DURATION [[definition valueForKey:RRFNBackInterBlockDurationKey] unsignedIntegerValue] * 1000
#define TKLogToTemp(fmt, ...) [delegate logStringToDefaultTempFile:[NSString stringWithFormat:fmt, ##__VA_ARGS__]]

@implementation RRFNBackController
// add any member that has a property
@synthesize delegate,definition,errorLog,view,dataStorage,cueView,ibiPrompt,
promptView;

#pragma mark HOUSEKEEPING METHODS
/**
 Give back any memory that may have been allocated by this bundle
 */
- (void)dealloc {

    // RELEASE ANY ALLOCATED MEMORY
    [errorLog release]; errorLog=nil;    
    [availableCues release]; availableCues=nil;
    [blockSet release]; blockSet=nil;
    [block release]; block=nil;
    [ibiPrompt release]; ibiPrompt=nil;
    [zeroTarget release]; zeroTarget=nil;

    // CALL DEALLOC ON PARENT OBJECT
    [super dealloc];
}

#pragma mark REQUIRED PROTOCOL METHODS

/**
 Start the component - will receive this message from the component controller
 */
- (void)begin {
    // if we are cleared to begin...
    if([self isClearedToBegin]) {
        // start our sequence by getting our next (first) block set
        [self nextBlockSet:nil];
    } else { // something has gone wrong
        // tell our controller to raise an error and break our execution
        [delegate throwError:errorLog andBreak:YES];
    }
}

/**
 Return a string representation of the data directory
 */
- (NSString *)dataDirectory {
    return [[definition valueForKey:RRFNBackDataDirectoryKey]
            stringByStandardizingPath];
}

/**
 Return a string object representing all current errors in log form
 */
- (NSString *)errorLog {
    return errorLog;
}

/**
 Perform any and all error checking required by the component
 Retrun: YES if passed
 */
- (BOOL)isClearedToBegin {
    return YES; // this is the default; change as needed
}

/**
 Returns the file name containing the raw data that will be appended to the
 data file
 */
- (NSString *)rawDataFile {
    return [delegate defaultTempFile]; // this is the default implementation
}

/**
 Perform actions required to recover from crash using the given raw data
 passed as string
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
 Accept assignment for the component delegate - The component controller will
 assign itself as the delegate
 Note: The new delegate must adopt the TKComponentBundleDelegate protocol
 */
- (void)setDelegate: (id <TKComponentBundleDelegate> )aDelegate {
    delegate = aDelegate;
}

/**
 Perform any and all initialization required by component - load any nib files
 and perform all required initialization
 */
- (void)setup {
    

    // --- RESET ERROR LOG
    [self setErrorLog:@""];
    // --- CREATE EMPTY QUEUE FOR DATA
    [self setDataStorage:[NSMutableArray array]];
    // --- LOAD CUES
    [self loadCues];

    // --- LOAD NIB
    if([NSBundle loadNibNamed:RRFNBackMainNibNameKey owner:self]) {
        // interface initialization can go here
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        // hide all of our views
        [cueView setHidden:YES];
        [promptView setHidden:YES];
        
    } else {
        // nib did not load
        [self registerError:@"Could not load Nib file"];
    }
    
    // --- REGISTER FOR ANY NOTIFICATIONS
    // ... next cue notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(nextCue:)
            name:RRFNBackNextCueNotification
          object:nil];
    // ... iti notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(ITI:)
            name:RRFNBackBeginITINotification
          object:nil];
    // ... second tick notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
        selector:@selector(performSecondTick:)
            name:RRFNBackPerformTickNotification
          object:nil];
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
    
    // - remove observers for any notifications we may have registered
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
/** */
- (BOOL)formsTarget: (NSImage *)cue {
    // the zero case needs special handling...
    if(nValue==0) {
        return [[cue name] isEqualToString:[zeroTarget name]];
    }
    // if we are here, this is not the zero case, so...
    // first check if nValue and index is such that we can have a target
    if(blockIndex - nValue < 0) {
        // this can't be a target, since there is no n-back at this spot
        return NO;
    }
    return [[cue name] isEqualToString:
            [[block objectAtIndex:blockIndex-nValue] name]];
}

/** Add additional methods required for operation */
- (void)registerError: (NSString *)theError {
    // append the new error to the error log
    [self setErrorLog:[[errorLog stringByAppendingString:theError]
                       stringByAppendingString:@"\n"]];
}

- (void)performSecondTick: (id)params {
    // this only increments the displayed seconds,
    // it has no bearing on when the next component
    // starts . . . race conditions may exist, but
    // because this is only in charge of a prompt
    // it is of little concern
    // All we need to do to deal with this is change
    // the prompt when we have seconds left, and do nothing
    // when we are out of time
    // ...so if we have time left (presumably)
    if(secondCounter-- > 0) {
        // update the subject prompt
        // ...get all but the last of the user prompt
        NSString *tmp = [[ibiPrompt stringByTrimmingCharactersInSet:
                          [NSCharacterSet decimalDigitCharacterSet]] retain];
        // ...make new string w/ previous and new second tick
        [self setIbiPrompt:[tmp stringByAppendingString:
                            [NSString stringWithFormat:@"%d",secondCounter ]]];
        // ...let go of temporary string
        [tmp release]; tmp=nil;
        // schedule the next notification
        [[TKTimer appTimer] registerEventWithNotification:
         [NSNotification notificationWithName:
          RRFNBackPerformTickNotification object:self] 
                                                inSeconds:1 microSeconds:0];

    } else { // we have no time left...
             // ... don't do anything
    }
}

/** Write data kept in the temporary store to a temporary file
    This will include a summary for the previous block
    During execution, the component should be in an unknown state
 */
- (void)writeStoredData {
    
    // ___BLOCK SUMMARY___
    // vars to get
    NSUInteger correctRespTarget = 0;
    NSUInteger errorRespTarget = 0;
    NSUInteger correctRespNonTarget = 0;
    NSUInteger errorRespNonTarget = 0;
    NSUInteger nonRespTarget = 0;
    NSUInteger nonRespNonTarget = 0;
    NSUInteger correctRespTargetTotLatency = 0;
    NSUInteger errorRespTargetTotLatency = 0;
    NSUInteger correctRespNonTargetTotLatency = 0;
    NSUInteger errorRespNonTargetTotLatency = 0;
    // get 'em vars . . . for every record in our temp storage
    for(NSDictionary *trialInfo in dataStorage) {
        // ...if user claimed target condition
        if([[trialInfo valueForKey:@"ResponseType"] isEqualToString:@"Y"]) {
            // check whether right or wrong
            if([[trialInfo valueForKey:@"TrialType"] isEqualToString:@"T"]) {
                // user said target - trial is target (correct target)
                // ...so increment...
                correctRespTarget++;
                // ...and add to latency for this type
                correctRespTargetTotLatency += 
              [[trialInfo valueForKey:@"Latency"] unsignedIntegerValue];
            } else {
                // user said target - but trial non-target (error non-target)
                // ...so increment...
                errorRespNonTarget++;
                // ...and add latency for this type
                errorRespNonTargetTotLatency += 
              [[trialInfo valueForKey:@"Latency"] unsignedIntegerValue];
            }
            continue; // go back to the for loop for the next record
        }
        // ...if user claimed non-target condition
        if([[trialInfo valueForKey:@"ResponseType"] isEqualToString:@"N"]) {
            // check whether right or wrong
            if([[trialInfo valueForKey:@"TrialType"] isEqualToString:@"NT"]) {
                // user said no target - trial is non-target
                // (correct non-target)
                // ...so increment...
                correctRespNonTarget++;
                // ...and add to latency for this type
                correctRespNonTargetTotLatency +=
              [[trialInfo valueForKey:@"Latency"] unsignedIntegerValue];
            } else {
                // user said no target - but trial is target (error target)
                // ...so increment...
                errorRespTarget++;
                // ...and add to latency for this type
                errorRespTargetTotLatency += 
              [[trialInfo valueForKey:@"Latency"] unsignedIntegerValue];
            }
            continue; // go back to the for loop for the next record
        }
        // at this point we can assume the user provided no response
        // so check the trial type
        if([[trialInfo valueForKey:@"TrialType"] isEqualToString:@"T"]) {
            // user provided no response for target
            // ...increment that counter...
            nonRespTarget++;
        } else {
            // type can be assumed to be Non-Target because that is all
            // that remains
            nonRespNonTarget++;
        }
    }
    
    // calculate avg latency from total in microseconds for each type
    // declare our vars
    TKTime correctRespTargetAvgLatency = new_time_marker(0,0);
    TKTime errorRespTargetAvgLatency = new_time_marker(0,0);
    TKTime correctRespNonTargetAvgLatency = new_time_marker(0,0);
    TKTime errorRespNonTargetAvgLatency = new_time_marker(0,0);
    // get'em vars
    if(correctRespTarget) {
      correctRespTargetAvgLatency =
      time_from_microseconds(correctRespTargetTotLatency/correctRespTarget);
    }
    if(errorRespTarget) {
      errorRespTargetAvgLatency = 
      time_from_microseconds(errorRespTargetTotLatency/errorRespTarget);
    }
    if(correctRespNonTarget) {
      correctRespNonTargetAvgLatency =
    time_from_microseconds(correctRespNonTargetTotLatency/correctRespNonTarget);
    }
    if(errorRespNonTarget) {
      errorRespNonTargetAvgLatency =
      time_from_microseconds(errorRespNonTargetTotLatency/errorRespNonTarget);
    }

    // log an empty string for newline to seperate blocks in logfile
    TKLogToTemp(@"");
    
    // create the log summary
    TKLogToTemp(@"N-VALUE: %d", nValue);
    TKLogToTemp(@"CORRECT TARGET RESP: %d", correctRespTarget);
    TKLogToTemp(@"CORRECT NON-TARGET RESP: %d", correctRespNonTarget);
    TKLogToTemp(@"ERROR TARGET RESP: %d", errorRespTarget);
    TKLogToTemp(@"ERROR NON-TARGET RESP: %d", errorRespNonTarget);
    TKLogToTemp(@"CORRECT TARGET RESP AVG LATENCY: %d.%d",
                correctRespTargetAvgLatency.seconds,
                correctRespTargetAvgLatency.microseconds);
    TKLogToTemp(@"CORRECT NON-TARGET RESP AVG LATENCY: %d.%d",
                correctRespNonTargetAvgLatency.seconds,
                correctRespNonTargetAvgLatency.microseconds);
    TKLogToTemp(@"ERROR TARGET RESP AVG LATENCY: %d.%d",
                errorRespTargetAvgLatency.seconds,
                errorRespTargetAvgLatency.microseconds);
    TKLogToTemp(@"ERROR NON-TARGET RESP AVG LATENCY: %d.%d",
                errorRespNonTargetAvgLatency.seconds,
                errorRespNonTargetAvgLatency.microseconds);
    TKLogToTemp(@"NON-RESP TARGET: %d", nonRespTarget);
    TKLogToTemp(@"NON-RESP NON-TARGET: %d", nonRespNonTarget);
    
    // log raw data
    // header row
    TKLogToTemp(@"RESP:\tTYPE:\tLATENCY:\tIMAGE:");
    TKLogToTemp(@"----\t----\t-------\t\t-----");
    for(NSDictionary *record in dataStorage) {
      // get latency value
      NSInteger tempLatency = [[record valueForKey:@"Latency"] integerValue];
      // if latency exists...
      if(tempLatency) {
        TKLogToTemp(@"%@\t%@\t%d\t\t%@",
                    [record valueForKey:@"ResponseType"],
                    [record valueForKey:@"TrialType"],
                    tempLatency/1000,
                    [record valueForKey:@"ImageName"]);
      } else { // if no latency value exists...
        TKLogToTemp(@"%@\t%@\t%@\t\t%@",
                    [record valueForKey:@"ResponseType"],
                    [record valueForKey:@"TrialType"],
                    @"(null)",
                    [record valueForKey:@"ImageName"]);
      } // end of iffi
    }   // end of for loop
    
    // empty our data storage for our next block
    [dataStorage removeAllObjects];
}

            
                
                
    
#pragma mark (ADD) STATES
/** Start the next cue if one exists */
- (void)nextCue: (id)params {

    // check the state we are coming from
    if(state==RRFNBackStateTypeITI) {
        // ...we are coming from an ITI
        // ...(in other words, we are coming from a previous trial)
        if(![cueView subjectHasAlreadyResponded]) {
            // ...but the subject did not respond...
            if([self formsTarget:currentCue]) {
                // ...to a target trial
                [dataStorage addObject:[DATA @"T", @"TrialType",
                                        [currentCue name],@"ImageName",nil]];
            } else {
                // ...to a non-target trial
                [dataStorage addObject:[DATA @"NT", @"TrialType",
                                        [currentCue name],@"ImageName",nil]];
            }
        // no else branch - if the subject did respond, it has already been
        // handled    
        }
    } else { // the state is assumed to be RRFNBackStateTypeIBI
             // (no previous trial)
        // ...hide the user time prompt
        [timeView setHidden:YES];
    }
    
    // if there is another cue to get
    if(++blockIndex < [block count]) {
        // get the new cue
        currentCue = [block objectAtIndex:blockIndex];

        // determine if cue is target
        // for normal (non-zero) case
        if(nValue!=0) {
          isTarget = 
          blockIndex < nValue || 
          [[currentCue name] isEqualToString:
           [[block objectAtIndex:blockIndex-nValue] name]];
        } else { // zero case
          isTarget = [[currentCue name]
                      isEqualToString:[zeroTarget name]];
        }
        

        
        // update state
        state = RRFNBackStateTypePresentation;
        
        // schedule the beginning of the ITI after cue
        [[TKTimer appTimer]
         registerEventWithNotification:
         [NSNotification notificationWithName:
          RRFNBackBeginITINotification object:self]
                             inSeconds:0
                          microSeconds:CUE_DURATION];

        // reset time marker
        cueStartTime = current_time_marker();
        
        // display the cue
        [cueView setCue:currentCue];
        [cueView setHidden:NO];
        // make the cue view the key view
        [[view window] makeFirstResponder:cueView];
        
    } else { // no more cues
        // we are now in an unknown state
        // marking this prevents responses when
        // we are not prepared to process them
        state = RRFNBackStateTypeUnknown;
        // write our temp data to file
        [self writeStoredData];
        // next block
        [self nextBlock:nil];
    }
    
}       // END OF NEXT_CUE:

/** Start the next block if one exists */
- (void)nextBlock: (id)params {
    
    // get our next block...
    // if there are any nValues left in the block set
    if([blockSet count]>0) {

        // get the next nValue
        // ...pick an index at random from blockSet array
        NSInteger idx = arc4random()%[blockSet count];
        // ...store the new nValue
        nValue = [[blockSet objectAtIndex:idx] integerValue];
        // ...remove the value we are using from the block set
        [blockSet removeObjectAtIndex:idx];

        // load the new block using the new nValue
        [self loadNewBlock];
        
        // begin the IBI
        [self IBI:nil];
                    
    } else { // there are no nValues left in the block set
        // .....get the next block set
        [self nextBlockSet:nil];
    }
}       // END OF NEXT_BLOCK:

/** Start the next block set if one exists */
- (void)nextBlockSet: (id)params {
    
    // if we still have iterations to run
    // (repeatCounter has not expired)
    if(repeatCounter<[[definition valueForKey:RRFNBackBlockSetCountKey]
                      integerValue]) {
        // ...then, if we can succesfully load a new block set
        if([self loadNewBlockSet]) {
            // increment block set counter
            repeatCounter++;
            // ...start the next block
            [self nextBlock:nil];
        } else { // there was an error generating block set
            // ...report error
            [self registerError:@"Unable to generate new block set"];
        }
    } else { // repeat counter has expired
        // ...then we are done
        [delegate componentDidFinish:self];
    }
    
}       // END OF NEXT_BLOCK_SET:

/** Start the ITI (inter-trial interval) */
- (void)ITI: (id)params {

    // hide the image, but leave the cue view there to handle
    // key events . . . the current cue is still held by us
    // so this will not mess up our target checking
    [cueView setCue:nil];

    // schedule the beginning of the next trial
    [[TKTimer appTimer] registerEventWithNotification:
     [NSNotification notificationWithName:RRFNBackNextCueNotification
                                   object:self]
                                            inSeconds:0
                                         microSeconds:ITI_DURATION];
    
    // update state
    state = RRFNBackStateTypeITI;

}

/** Start the IBI (inter-block interval) */
- (void)IBI: (id)params {
    
    // update state
    state=RRFNBackStateTypeIBI;
    
    // remove the cue view
    [cueView setHidden:YES];
    
    #ifdef DEBUG
    NSLog(@"\n\nIteration %d\n",repeatCounter);
    for(NSDictionary *item in dataStorage) {
        NSLog(@"%@",[item description]);
    }
    #endif

    // ready prompt subject prompt...
    secondCounter = IBI_DURATION / (1000 * 1000); // IBI duration as seconds
    // ...non-zero case
    if(nValue) {
        [self setIbiPrompt:
         [NSString stringWithFormat:
          @"Enter '1' when the image is the same as the image %d-back\n...begin in: %d",
          nValue, secondCounter ]];
    } else { // zero case
        [self setIbiPrompt:
         [NSString stringWithFormat:
          @"Enter '1' when the %@ is displayed\n...begin in: %d",
          [zeroTarget name], secondCounter ]];
    }
    // display prompt
    [promptView setHidden:NO];

    // schedule the beginning of the next block
    [[TKTimer appTimer]
     registerEventWithNotification:
     [NSNotification notificationWithName:
      RRFNBackNextCueNotification object:self]
                                inSeconds: 0
                             microSeconds:IBI_DURATION];

    // begin the ticking seconds countdown
    [[TKTimer appTimer]
     registerEventWithNotification:
     [NSNotification notificationWithName:
      RRFNBackPerformTickNotification object:self]
                                   inSeconds:1
                                microSeconds:0];

}       // END IBI:



#pragma mark (ADD) HANDLERS
/** If appropriate log the affirmation and result (correct?) */
- (void)subjectAffirms: (id)sender {
    // if we are in appropriate state (CUE or ITI)
    if(state == RRFNBackStateTypePresentation ||
       state == RRFNBackStateTypeITI) {
        // check if subject is correct
        if([self formsTarget:currentCue]) {
            // ...subject is correct (claims target - is target)
            [dataStorage addObject:
             [DATA @"Y", @"ResponseType",@"T", @"TrialType",
              [NSNumber numberWithUnsignedInteger:
               time_as_microseconds(time_since(cueStartTime))],@"Latency",
              [currentCue name],@"ImageName",nil]];
            #ifdef DEBUG
            NSLog(@"User has correctly affirmed");
            #endif
        } else {
            // ...subject is incorrect (claims target - not target)
            [dataStorage addObject:
             [DATA @"Y", @"ResponseType",@"NT", @"TrialType",
              [NSNumber numberWithUnsignedInteger:
               time_as_microseconds(time_since(cueStartTime))],@"Latency",
              [currentCue name],@"ImageName",nil]];
            #ifdef DEBUG
            NSLog(@"User has incorrectly affirmed");
            #endif
        }
        
    } else {
        // we are not in a state where we accept user input
        // . . . do nothing
    }
}

- (void)subjectDenies: (id)sender {
    // if we are in appropriate state (CUE or ITI)
    if(state == RRFNBackStateTypePresentation ||
       state == RRFNBackStateTypeITI) {
        // ...then check if subject is correct
        if(![self formsTarget:currentCue]) {

            // ...subject is correct (claims not target - is not target)
            [dataStorage addObject:
             [DATA @"N", @"ResponseType",@"NT", @"TrialType",
              [NSNumber numberWithUnsignedInteger:
               time_as_microseconds(time_since(cueStartTime))],@"Latency",
              [currentCue name],@"ImageName",nil]];
            #ifdef DEBUG
            NSLog(@"User has correctly denied");
            #endif
        } else { // user has incorrectly denied target
            // ...subject is incorrect (claims not target - is target)
            [dataStorage addObject:
             [DATA @"N", @"ResponseType",@"T", @"TrialType",
              [NSNumber numberWithUnsignedInteger:
               time_as_microseconds(time_since(cueStartTime))],@"Latency",
              [currentCue name],@"ImageName",nil]];
            #ifdef DEBUG
            NSLog(@"User has incorrectly denied");
            #endif
        }
    } else {
        // we are not in a state where we accept user input
        // . . . do nothing
    }
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
    tempCues = 
      [[[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:CUE_DIRECTORY error:&myError] retain];
    
    // if there was an error getting the file names...
    if(myError) {
        [self registerError:
         [NSString stringWithFormat:
          @"Could not load cues from Directory: %@\n%@",
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
        image =
          [[NSImage alloc] initByReferencingFile:
           [CUE_DIRECTORY stringByAppendingPathComponent:img_path]];
        if([image isValid]) {
            #ifdef DEBUNG
            NSLog(@"Image: %@",[image description]);
            #endif
            // if the image is valid add it to the heap
            [heap addObject:image];
            // and set the name of the image to file name
            [image setName:[img_path stringByDeletingPathExtension]];
        } else {
            // else, register the error
            [self registerError:
             [NSString stringWithFormat:
              @"Could not load image file: %@",img_path]];
        }
        // release the image object (it will be held on to by the array)
        [image release]; image = nil;
    }
    
    // move cues from heap to their permanent storage array
    availableCues = [[NSArray alloc] initWithArray:(NSArray *)heap];
    
    // report if there are less than two cues . . . if so, n-back will not
    // make sense
    if([availableCues count] < 2) {
        [self registerError:
         @"Less than two cues have been loaded, this is problematic"];
    }
    
    // release remaining temporary objects
    [heap release]; heap = nil;
    [tempCues release]; tempCues = nil;
    
    // return success (even if non-fatal errors have been reported)
    return YES;
}

/** Create a new block set - register any errors encounterd
    @return YES on success, NO on failure
 */
- (BOOL)loadNewBlockSet {

    // get our min and max condition values
    NSInteger min_n =
      [[definition valueForKey:RRFNBackMinNConditionKey] integerValue];
    NSInteger max_n = 
      [[definition valueForKey:RRFNBackMaxNConditionKey] integerValue];
    
    // perform checks on min and max values
    if( max_n < min_n || min_n < 0 ) {
        [self registerError:
         @"Could not create block set - Max and/or Min values are invalid"];
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
    
    // if for some reason we don't have available cues
    if(![availableCues count]) {
        //...register error
        [self registerError:@"Could not load block: no cues available"];
        return NO;
    }

    // grab values for trials and targets
    NSInteger trials = 
      [[definition valueForKey:RRFNBackTrialCountKey] integerValue];
    NSInteger targets = 
      [[definition valueForKey:RRFNBackTargetCountKey] integerValue];
    
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
        [tempBlock addObject:[availableCues objectAtIndex:selectedCue]];
    }
    
    // create an array representing the targets
    NSMutableArray *targetBlock = nil;
    targetBlock = [[NSMutableArray alloc] init];
    // create an NSNumber which will hold temporary attempts
    NSNumber *attempt = nil;
    // for every intended target add an entry to the target block
    // representing where it should occur...
    for(NSInteger i=0; i<targets; i++) {
        // below represents random num modded by target count less nValue
        // which yields random spread 0 through trials-nValue
        // and then the result of that is summed with the nValue
        // resulting in a spread from nth trial to last trial - 1
        attempt = 
          [NSNumber numberWithInteger:arc4random()%(trials-nValue)+nValue];
        // check that this attempt has not already been added:
        // while the attempt is already in target block...
        while([targetBlock containsObject:attempt]) {
            // ...get a new value
            attempt = 
              [NSNumber numberWithInteger:arc4random()%(trials-nValue)+nValue];
        }
        // add the now valid attempt to the target block
        [targetBlock addObject:attempt];
    }
    // sort the array in ascending order
    [targetBlock sortUsingSelector:@selector(compare:)];
    
    // organize the block with reference to target/non-target
    // for the normal (non-zero) case
    if(nValue) {
        // ...for each spot in the temporary block starting at the first
        // ...possible target
        for(NSInteger i=nValue;i<[tempBlock count];i++) {
            // ...if this should be a target
            if([targetBlock containsObject:[NSNumber numberWithInteger:i]]) {
                // ...make the cue equal to the n-back cue
                [tempBlock replaceObjectAtIndex:i withObject:
                 [tempBlock objectAtIndex:i-nValue]];
            } else { // ...if this should not be a target
                // ...while this spot is an accidental target
                while([[[tempBlock objectAtIndex:i] name] isEqualToString:
                       [[tempBlock objectAtIndex:i-nValue] name]]) {
                    //...generate a random cue
                    [tempBlock replaceObjectAtIndex:i
                                         withObject:
                     [availableCues objectAtIndex:
                      arc4random()%[availableCues count]]];
                }
            }
        }
    } else { // the zero case
        zeroTarget=
          [availableCues objectAtIndex:arc4random()%[availableCues count]];

        // ...for each spot in the temp block
        for(NSInteger i=0;i<[tempBlock count];i++) {
            // ...if this should be a target
            if([targetBlock containsObject:[NSNumber numberWithInteger:i]]) {
                // ...make cue equal to zero target cue
                [tempBlock replaceObjectAtIndex:i withObject:zeroTarget];
            } else { // ...if this should not be a target
                // ...while the cue is equal to target
                while([[[tempBlock objectAtIndex:i] name]
                       isEqualToString:[zeroTarget name]]) {
                    // ...randomly select a new cue
                    [tempBlock replaceObjectAtIndex:i 
                                         withObject:
                     [availableCues objectAtIndex:
                      arc4random()%[availableCues count]]];
                }
            }
        }
    }

    // copy the tempBlock over to our real block
    [block release]; block=nil;
    block = [[NSArray alloc] initWithArray:tempBlock];
    
    // reset block index
    blockIndex = -1;
    
    // give back temp resources
    [targetBlock release]; targetBlock = nil;
    [tempBlock release]; tempBlock = nil;

    // success
    return YES;
}



#pragma mark Notifications
NSString * const RRFNBackNextCueNotification =      @"RRFNBackNextCue";
NSString * const RRFNBackBeginITINotification =     @"RRFNBackBeginITI";
NSString * const RRFNBackPerformTickNotification =  @"RRFNBackPerformTick";



#pragma mark Preference Keys
// HERE YOU DEFINE KEY REFERENCES FOR ANY PREFERENCE VALUES
// ex: NSString * const RRFNBackNameOfPreferenceKey = @"RRFNBackNameOfPreference"
NSString * const RRFNBackTaskNameKey =              @"RRFNBackTaskName";
NSString * const RRFNBackDataDirectoryKey =         @"RRFNBackDataDirectory";
NSString * const RRFNBackBlockSetCountKey =         @"RRFNBackBlockSetCount";
NSString * const RRFNBackCueDirectoryKey =          @"RRFNBackCueDirectory";
NSString * const RRFNBackCueDurationKey =           @"RRFNBackCueDuration";
NSString * const RRFNBackInterBlockDurationKey =    @"RRFNBackInterBlockDuration";
NSString * const RRFNBackInterTrialDurationKey =    @"RRFNBackInterTrialDuration";
NSString * const RRFNBackMaxNConditionKey =         @"RRFNBackMaxNCondition";
NSString * const RRFNBackMinNConditionKey =         @"RRFNBackMinNCondition";
NSString * const RRFNBackResponseTypeKey =          @"RRFNBackResponseType";
NSString * const RRFNBackTargetCountKey =           @"RRFNBackTargetCount";
NSString * const RRFNBackTrialCountKey =            @"RRFNBackTrialCount";




#pragma mark Internal Strings
// HERE YOU DEFINE KEYS FOR CONSTANT STRINGS //
///////////////////////////////////////////////
NSString * const RRFNBackMainNibNameKey =           @"RRFNBackMainNib";
        
       

@end
