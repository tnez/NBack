////////////////////////////////////////////////////////////
//  RRFNBackController.h
//  RRFNBack
//  --------------------------------------------------------
//  Author: Travis Nesland
//  Created: 10/7/10
//  Copyright 2010, Residential Research Facility,
//  University of Kentucky. All Rights Reserved.
/////////////////////////////////////////////////////////////
#import <Cocoa/Cocoa.h>
#import <TKUtility/TKUtility.h>

@interface RRFNBackController : NSObject <TKComponentBundleLoading> {

    // PROTOCOL MEMBERS //////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////    
    NSDictionary                                                *definition;
    id                                                          delegate;
    NSString                                                    *errorLog;
    IBOutlet NSView                                             *view;

    // ADDITIONAL MEMBERS ////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////
    NSArray                                                     *availableCues;
    NSInteger                                                   nValue;
    NSMutableArray                                              *blockSet;
    NSArray                                                     *block;
    NSInteger                                                   blockIndex;
    
    
}

// PROTOCOL PROPERTIES ///////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
@property (assign)              NSDictionary                    *definition;
@property (assign)              id <TKComponentBundleLoading>   delegate;
@property (nonatomic, retain)   NSString                        *errorLog;
@property (assign)              IBOutlet NSView                 *view;

// ADDITIONAL PROPERTIES /////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////



#pragma mark REQUIRED PROTOCOL METHODS
/** Start the component - will receive this message from the component controller */
- (void)begin;

/** Return a string representation of the data directory */
- (NSString *)dataDirectory;

/** Return a string object representing all current errors in log form */
- (NSString *)errorLog;

/** Perform any and all error checking required by the component - return YES if passed */
- (BOOL)isClearedToBegin;

/** Returns the file name containing the raw data that will be appended to the data file */
- (NSString *)rawDataFile;

/** Perform actions required to recover from crash using the given raw data passed as string */
- (void)recover;

/** Accept assignment for the component definition */
- (void)setDefinition: (NSDictionary *)aDictionary;

/** Accept assignment for the component delegate - The component controller will assign itself as the delegate
    Note: The new delegate must adopt the TKComponentBundleDelegate protocol
 */
- (void)setDelegate: (id <TKComponentBundleDelegate> )aDelegate;

/** Perform any and all initialization required by component - load any nib files and perform all required initialization */
- (void)setup;

/** Return YES if component should perform recovery actions */
- (BOOL)shouldRecover;

/** Return the name for the current task */
- (NSString *)taskName;

/** Perform any and all finalization required by component */
- (void)tearDown;

/** Return the main view that should be presented to the subject */
- (NSView *)mainView;




#pragma mark OPTIONAL PROTOCOL METHODS
// UNCOMMENT ANY OF THE FOLLOWING METHODS IF THEIR BEHAVIOR IS DESIRED //
/////////////////////////////////////////////////////////////////////////

/** Run header if something other than default is required */
//- (NSString *)runHeader;

/** Session header if something other than default is required */
//- (NSString *)sessionHeader;

/** Summary data if desired */
//- (NSString *)summary;




#pragma mark UTILITY METHODS
/** Add the error to an ongoing error log */
- (void)registerError: (NSString *)theError;




#pragma mark (ADD) STATES
/** Start the next cue if one exists */
- (void)nextCue;

/** Start the next block if one exists */
- (void)nextBlock;

/** Start the next block set if one exists */
- (void)nextBlockSet;

/** Start the ITI */
- (void)ITI;

/** Start the IBI (inter-block interval) */
- (void)IBI;




#pragma mark (ADD) INITIALIZATION
/** Load cue images into memory */
- (BOOL)loadCues;

/** Initialize new block set */
- (BOOL)loadNewBlockSet;

/**  Initialize new block */
- (BOOL)loadNewBlock;




#pragma mark Preference Keys
// HERE YOU DEFINE KEY REFERENCES FOR ANY PREFERENCE VALUES                 //
// ex: extern NSString * const RRFNBackNameOfPreferenceKey;     //
//////////////////////////////////////////////////////////////////////////////
extern NSString * const RRFNBackTaskNameKey;
extern NSString * const RRFNBackDataDirectoryKey;
extern NSString * const RRFNBackBlockSetCountKey;
extern NSString * const RRFNBackCueDirectoryKey;
extern NSString * const RRFNBackCueDurationKey;
extern NSString * const RRFNBackInterBlockDurationKey;
extern NSString * const RRFNBackInterTrialDurationKey;
extern NSString * const RRFNBackMaxNConditionKey;
extern NSString * const RRFNBackMinNConditionKey;
extern NSString * const RRFNBackResponseTypeKey;
extern NSString * const RRFNBackTargetCountKey;
extern NSString * const RRFNBackTrialCountKey;




#pragma mark Internal Strings
// HERE YOU DEFINE KEYS FOR CONSTANT STRINGS //
///////////////////////////////////////////////
extern NSString * const RRFNBackMainNibNameKey;




#pragma mark Enumerated Values
// HERE YOU CAN DEFINE ENUMERATED VALUES
/////////////////////////////////////////
typedef NSInteger RRFNBackStateType;
enum {
    RRFNBackStateTypePresentation   = 1,
    RRFNBackStateTypeITI            = 2,
    RRFNBackStateTypeIBI            = 3,
    RRFNBackStateTypeUnknown        = 0
};


@end
