//
//  RegistrationParams.m
//  DCEFit
//
//  Created by Tim Allman on 2013-04-11.
//
//

#import "RegistrationParams.h"
#import "UserDefaults.h"

@implementation RegistrationParams

// General registration parameters
@synthesize numImages;
@synthesize fixedImageNumber;
@synthesize slicesPerImage;
@synthesize flippedData;
@synthesize seriesDescription;
@synthesize fixedImageRegion;
@synthesize fixedImageMask;

// rigid registration parameters
@synthesize rigidRegEnabled;
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
@synthesize rigidRegMaxIter;

// deformable regitration parameters
@synthesize deformRegEnabled;
@synthesize deformShowField;
@synthesize deformRegMultiresLevels;
@synthesize deformRegGridSize;
@synthesize deformRegMetric;
@synthesize deformRegOptimizer;
@synthesize deformRegMMIHistogramBins;
@synthesize deformRegMMISampleRate;
@synthesize deformRegLBFGSBCostConvergence;
@synthesize deformRegLBFGSBGradientTolerance;
@synthesize deformRegLBFGSGradientConvergence;
@synthesize deformRegLBFGSDefaultStepSize;
@synthesize deformRegRSGDMinStepSize;
@synthesize deformRegRSGDMaxStepSize;
@synthesize deformRegRSGDRelaxationFactor;
@synthesize deformRegMaxIter;

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
    [rigidRegMaxIter release];
    [deformRegGridSize release];
    [deformRegMMIHistogramBins release];
    [deformRegMMISampleRate release];

    [deformRegLBFGSBCostConvergence release];
    [deformRegLBFGSBGradientTolerance release];
    [deformRegLBFGSGradientConvergence release];
    [deformRegLBFGSDefaultStepSize release];
    [deformRegRSGDMinStepSize release];
    [deformRegRSGDMaxStepSize release];
    [deformRegRSGDRelaxationFactor release];

    [deformRegMaxIter release];

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

    // Rigid registration parameters
    self.rigidRegEnabled = [def booleanForKey:RigidRegEnabledKey];
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

    self.rigidRegMaxIter = [NSMutableArray arrayWithArray:
                            [def objectForKey:RigidRegMaxIterKey]];

    // Rigid registration parameters
    self.deformRegEnabled = [def booleanForKey:DeformRegEnabledKey];
    self.deformShowField = [def booleanForKey:DeformShowFieldKey];
    self.deformRegMultiresLevels = [def unsignedIntegerForKey:DeformRegMultiresLevelsKey];
    self.deformRegMetric = [def integerForKey:DeformRegMetricKey];
    self.deformRegOptimizer = [def integerForKey:DeformRegOptimizerKey];
    self.deformRegGridSize = [NSMutableArray arrayWithArray:
                              [def objectForKey:DeformRegGridSizeKey]];
    self.deformRegMMIHistogramBins = [NSMutableArray arrayWithArray:
                                      [def objectForKey:DeformRegMMIHistogramBinsKey]];
    self.deformRegMMISampleRate = [NSMutableArray arrayWithArray:
                                   [def objectForKey:DeformRegMMISampleRateKey]];

    self.deformRegLBFGSBCostConvergence = [NSMutableArray arrayWithArray:
                                          [def objectForKey:DeformRegLBFGSBCostConvergenceKey]];
    self.deformRegLBFGSBGradientTolerance = [NSMutableArray arrayWithArray:
                                            [def objectForKey:DeformRegLBFGSBGradientToleranceKey]];
    self.deformRegLBFGSGradientConvergence = [NSMutableArray arrayWithArray:
                                             [def objectForKey:DeformRegLBFGSGradientConvergenceKey]];
    self.deformRegLBFGSDefaultStepSize = [NSMutableArray arrayWithArray:
                                         [def objectForKey:DeformRegLBFGSDefaultStepSizeKey]];

    self.deformRegRSGDMinStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:DeformRegRSGDMinStepSizeKey]];
    self.deformRegRSGDMaxStepSize = [NSMutableArray arrayWithArray:
                                    [def objectForKey:DeformRegRSGDMaxStepSizeKey]];
    self.deformRegRSGDRelaxationFactor = [NSMutableArray arrayWithArray:
                                          [def objectForKey:DeformRegRSGDRelaxationFactorKey]];
    
    self.deformRegMaxIter = [NSMutableArray arrayWithArray:
                             [def objectForKey:DeformRegMaxIterKey]];
}

- (unsigned)sliceNumberToIndex:(unsigned)number
{
    if (flippedData)
        return slicesPerImage - number;
    else
        return number - 1;
}

- (unsigned)indexToSliceNumber:(unsigned int)index
{
    if (flippedData)
        return slicesPerImage - index;
    else
        return index + 1;
}

@end
