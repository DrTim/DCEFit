//
//  RegistrationParams.m
//  DCEFit
//
//  Created by Tim Allman on 2013-04-11.
//
//

#import "ProjectDefs.h"
#import "RegistrationParams.h"
#import "UserDefaults.h"

@implementation RegistrationParams

// Plugin configuration parameters
@synthesize loggerLevel;
@synthesize numberOfThreads;
@synthesize maxNumberOfThreads;
@synthesize useDefaultNumberOfThreads;

// General registration parameters
@synthesize regSequence;
@synthesize numImages;
@synthesize fixedImageNumber;
@synthesize slicesPerImage;
@synthesize flippedData;
@synthesize seriesDescription;
@synthesize fixedImageRegion;
@synthesize fixedImageMask;

// rigid registration parameters
//@synthesize rigidRegEnabled;
@synthesize rigidRegMultiresLevels;
@synthesize rigidRegMetric;
@synthesize rigidRegOptimizer;
@synthesize rigidRegMMIHistogramBins;
@synthesize rigidRegMMISampleRate;
@synthesize rigidRegLBFGSBCostConvergence;
@synthesize rigidRegLBFGSBGradientTolerance;
@synthesize rigidRegLBFGSGradientConvergence;
@synthesize rigidRegLBFGSDefaultStepSize;
@synthesize rigidRegRSGDMinStepSize;
@synthesize rigidRegRSGDMaxStepSize;
@synthesize rigidRegRSGDRelaxationFactor;
@synthesize rigidRegVersorOptTransScale;
@synthesize rigidRegVersorOptMinStepSize;
@synthesize rigidRegVersorOptMaxStepSize;
@synthesize rigidRegVersorOptRelaxationFactor;
@synthesize rigidRegMaxIter;

// deformable registration parameters
@synthesize deformShowField;

// B-spline registration parameters
@synthesize bsplineRegGridSizeArray;
@synthesize bsplineRegMetric;
@synthesize bsplineRegOptimizer;
@synthesize bsplineRegMMIHistogramBins;
@synthesize bsplineRegMMISampleRate;
@synthesize bsplineRegLBFGSBCostConvergence;
@synthesize bsplineRegLBFGSBGradientTolerance;
@synthesize bsplineRegLBFGSGradientConvergence;
@synthesize bsplineRegLBFGSDefaultStepSize;
@synthesize bsplineRegRSGDMinStepSize;
@synthesize bsplineRegRSGDMaxStepSize;
@synthesize bsplineRegRSGDRelaxationFactor;
//@synthesize bsplineRegEnabled;
@synthesize bsplineRegMaxIter;
@synthesize bsplineRegMultiresLevels;

// Demons registration parameters
@synthesize demonsRegHistogramBins;
@synthesize demonsRegHistogramMatchPoints;
@synthesize demonsRegMaxRMSError;
@synthesize demonsRegStandardDeviations;
//@synthesize demonsRegEnabled;
@synthesize demonsRegMaxIter;
@synthesize demonsRegMultiresLevels;

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialise this instance from the user defaults
        [self setFromUserDefaults];
        self.flippedData = NO;
        self.fixedImageRegion = [Region2D regionFromString:@"{{0, 0}, {0, 0}}"];
        self.fixedImageMask = [[[NSMutableArray alloc] init] autorelease];
        [self setupLogger];

        LOG4M_TRACE(logger_, @"init");
    }

    return self;
}

- (void)dealloc
{
    [fixedImageMask release];
    [rigidRegMMIHistogramBins release];
    [rigidRegMMISampleRate release];

    [rigidRegLBFGSBCostConvergence release];
    [rigidRegLBFGSBGradientTolerance release];
    [rigidRegLBFGSGradientConvergence release];
    [rigidRegLBFGSDefaultStepSize release];
    [rigidRegRSGDMinStepSize release];
    [rigidRegRSGDMaxStepSize release];
    [rigidRegRSGDRelaxationFactor release];
    [rigidRegVersorOptMinStepSize release];
    [rigidRegVersorOptMaxStepSize release];
    [rigidRegVersorOptRelaxationFactor release];
    [rigidRegVersorOptTransScale release];
    [rigidRegMaxIter release];

    [bsplineRegGridSizeArray release];
    [bsplineRegMMIHistogramBins release];
    [bsplineRegMMISampleRate release];

    [bsplineRegLBFGSBCostConvergence release];
    [bsplineRegLBFGSBGradientTolerance release];
    [bsplineRegLBFGSGradientConvergence release];
    [bsplineRegLBFGSDefaultStepSize release];
    [bsplineRegRSGDMinStepSize release];
    [bsplineRegRSGDMaxStepSize release];
    [bsplineRegRSGDRelaxationFactor release];
    [bsplineRegMaxIter release];

    [demonsRegMaxIter release];
    [demonsRegMaxRMSError release];
    
    [logger_ release];
    [super dealloc];
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".RegistrationParams"];
    logger_ = [[Logger newInstance:loggerName] retain];
}

- (void)setFromUserDefaults
{
    LOG4M_TRACE(logger_, @"Enter");
    
    // Set the values based upon the user defaults
    UserDefaults* def = [UserDefaults sharedInstance];

    // General parameters
    self.fixedImageNumber = [def integerForKey:FixedImageNumberKey];
    self.seriesDescription = [def stringForKey:SeriesDescriptionKey];
    self.regSequence = [def integerForKey:RegistrationSequenceKey];

    // Rigid registration parameters
    //self.rigidRegEnabled = [def booleanForKey:RigidRegEnabledKey];
    self.rigidRegMultiresLevels = [def unsignedIntegerForKey:RigidRegMultiresLevelsKey];
    self.rigidRegMetric = [def integerForKey:RigidRegMetricKey];
    self.rigidRegOptimizer = [def integerForKey:RigidRegOptimizerKey];
    self.rigidRegMMIHistogramBins = [NSMutableArray arrayWithArray:
                                     [def objectForKey:RigidRegMMIHistogramBinsKey]];
    self.rigidRegMMISampleRate = [NSMutableArray arrayWithArray:
                                  [def objectForKey:RigidRegMMISampleRateKey]];


    self.rigidRegLBFGSBCostConvergence = [NSMutableArray arrayWithArray:
                                          [def objectForKey:RigidRegLBFGSBCostConvergenceKey]];
    self.rigidRegLBFGSBGradientTolerance = [NSMutableArray arrayWithArray:
                                            [def objectForKey:RigidRegLBFGSBGradientToleranceKey]];

    self.rigidRegLBFGSGradientConvergence = [NSMutableArray arrayWithArray:
                                             [def objectForKey:RigidRegLBFGSGradientConvergenceKey]];
    self.rigidRegLBFGSDefaultStepSize = [NSMutableArray arrayWithArray:
                                         [def objectForKey:RigidRegLBFGSDefaultStepSizeKey]];

    self.rigidRegRSGDMinStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:RigidRegRSGDMinStepSizeKey]];
    self.rigidRegRSGDMaxStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:RigidRegRSGDMaxStepSizeKey]];
    self.rigidRegRSGDRelaxationFactor= [NSMutableArray arrayWithArray:
                                        [def objectForKey:RigidRegRSGDRelaxationFactorKey]];

    self.rigidRegVersorOptMinStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:RigidRegVersorOptMinStepSizeKey]];
    self.rigidRegVersorOptMaxStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:RigidRegVersorOptMaxStepSizeKey]];
    self.rigidRegVersorOptRelaxationFactor= [NSMutableArray arrayWithArray:
                                             [def objectForKey:RigidRegVersorOptRelaxationFactorKey]];
    self.rigidRegVersorOptTransScale = [NSMutableArray arrayWithArray:
                                             [def objectForKey:RigidRegVersorOptTransScaleKey]];

    self.rigidRegMaxIter = [NSMutableArray arrayWithArray:
                            [def objectForKey:RigidRegMaxIterKey]];

    // Deformable registration parameters
    self.deformShowField = [def booleanForKey:DeformRegShowFieldKey];

    // BSpline registration
    //self.bsplineRegEnabled = [def booleanForKey:BsplineRegEnabledKey];

    self.bsplineRegMaxIter = [NSMutableArray arrayWithArray:
                             [def objectForKey:BsplineRegMaxIterKey]];
    self.bsplineRegMultiresLevels = [def unsignedIntegerForKey:BsplineRegMultiresLevelsKey];
    self.bsplineRegMetric = [def integerForKey:BsplineRegMetricKey];
    self.bsplineRegOptimizer = [def integerForKey:BsplineRegOptimizerKey];
    self.bsplineRegGridSizeArray = [NSMutableArray arrayWithArray:
                              [def objectForKey:BsplineRegGridSizeArrayKey]];
    self.bsplineRegMMIHistogramBins = [NSMutableArray arrayWithArray:
                                      [def objectForKey:BsplineRegMMIHistogramBinsKey]];
    self.bsplineRegMMISampleRate = [NSMutableArray arrayWithArray:
                                   [def objectForKey:BsplineRegMMISampleRateKey]];

    self.bsplineRegLBFGSBCostConvergence = [NSMutableArray arrayWithArray:
                                          [def objectForKey:BsplineRegLBFGSBCostConvergenceKey]];
    self.bsplineRegLBFGSBGradientTolerance = [NSMutableArray arrayWithArray:
                                            [def objectForKey:BsplineRegLBFGSBGradientToleranceKey]];
    self.bsplineRegLBFGSGradientConvergence = [NSMutableArray arrayWithArray:
                                             [def objectForKey:BsplineRegLBFGSGradientConvergenceKey]];
    self.bsplineRegLBFGSDefaultStepSize = [NSMutableArray arrayWithArray:
                                         [def objectForKey:BsplineRegLBFGSDefaultStepSizeKey]];

    self.bsplineRegRSGDMinStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:BsplineRegRSGDMinStepSizeKey]];
    self.bsplineRegRSGDMaxStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:BsplineRegRSGDMaxStepSizeKey]];
    self.bsplineRegRSGDRelaxationFactor = [NSMutableArray arrayWithArray:
                                          [def objectForKey:BsplineRegRSGDRelaxationFactorKey]];

    // Demons registration
    //self.demonsRegEnabled = [def booleanForKey:DemonsRegEnabledKey];
    self.demonsRegMaxIter = [NSMutableArray arrayWithArray:
                              [def objectForKey:DemonsRegMaxIterKey]];
    self.demonsRegMultiresLevels = [def unsignedIntegerForKey:DemonsRegMultiresLevelsKey];
    self.demonsRegMaxRMSError = [NSMutableArray arrayWithArray:
                                 [def objectForKey:DemonsRegMaxRMSErrorKey]];
    self.demonsRegHistogramBins = [def unsignedIntegerForKey:DemonsRegHistogramBinsKey];
    self.demonsRegHistogramMatchPoints = [def unsignedIntegerForKey:DemonsRegHistogramMatchPointsKey];
    self.demonsRegStandardDeviations = [def floatForKey:DemonsRegStandardDeviationsKey];
}

- (BOOL)isRigidRegEnabled
{
    return ((regSequence == Rigid) || (regSequence == RigidBSpline));
}

- (BOOL)isBsplineRegEnabled
{
    return ((regSequence == BSpline) || (regSequence == RigidBSpline));
}

- (BOOL)isDemonsRegEnabled
{
    return (regSequence == Demons);
}

@end
