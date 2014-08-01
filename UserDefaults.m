//
//  UserDefaults.m
//  Registration
//
//  Created by Tim Allman on 2012-09-26.
//
//

#import <Log4m/LogLevel.h>

#import "UserDefaults.h"
#import "ProjectDefs.h"
#import "RegistrationParams.h"

// General program defaults
NSString* const LoggerLevelKey = @"LoggerLevel";
NSString* const NumberOfThreadsKey = @"NumberOfThreads";
NSString* const UseDefaultNumberOfThreadsKey = @"UseDefaultNumberOfThreads";

// general registration parameters
NSString* const RegistrationSequenceKey = @"RegistrationSequence";
NSString* const FixedImageNumberKey = @"FixedImageNumber";
NSString* const SeriesDescriptionKey = @"SeriesDescription";

// rigid registration parameters
//NSString* const RigidRegEnabledKey = @"RigidRegEnabled";
NSString* const RigidRegMultiresLevelsKey = @"RigidRegMultiresLevels";
NSString* const RigidRegMetricKey = @"RigidRegMetric";
NSString* const RigidRegOptimizerKey = @"RigidRegOptimizer";
NSString* const RigidRegMMIHistogramBinsKey = @"RigidRegMMIHistogramBins";
NSString* const RigidRegMMISampleRateKey = @"RigidRegMMISampleRate";
NSString* const RigidRegLBFGSBCostConvergenceKey = @"RigidRegLBFGSBCostConvergence";
NSString* const RigidRegLBFGSBGradientToleranceKey = @"RigidRegLBFGSBGradientTolerance";
NSString* const RigidRegLBFGSGradientConvergenceKey = @"RigidRegLBFGSGradientConvergence";
NSString* const RigidRegLBFGSDefaultStepSizeKey = @"RigidRegLBFGSDefaultStepSize";
NSString* const RigidRegRSGDMinStepSizeKey = @"RigidRegRSGDMinStepSize";
NSString* const RigidRegRSGDMaxStepSizeKey = @"RigidRegRSGDMaxStepSize";
NSString* const RigidRegRSGDRelaxationFactorKey = @"RigidRegRSGDRelaxationFactor";
NSString* const RigidRegVersorOptTransScaleKey = @"RigidRegVersorOptTransScale";
NSString* const RigidRegVersorOptMinStepSizeKey = @"RigidRegVersorOptMinStepSize";
NSString* const RigidRegVersorOptMaxStepSizeKey = @"RigidRegVersorOptMaxStepSize";
NSString* const RigidRegVersorOptRelaxationFactorKey = @"RigidRegVersorOptRelaxationFactor";
NSString* const RigidRegMaxIterKey = @"RigidRegMaxIter";

// deformable regitration parameters
NSString* const DeformRegShowFieldKey = @"DeformRegShowField";

// BSpline specific
//NSString* const BsplineRegEnabledKey = @"BsplineRegEnabled";
NSString* const BsplineRegMaxIterKey = @"BsplineRegMaxIter";
NSString* const BsplineRegMultiresLevelsKey = @"BsplineRegMultiresLevels";
NSString* const BsplineRegGridSizeArrayKey = @"BsplineRegGridSizeArray";
NSString* const BsplineRegMetricKey = @"BsplineRegMetric";
NSString* const BsplineRegOptimizerKey = @"BsplineRegOptimizer";
NSString* const BsplineRegMMIHistogramBinsKey = @"BsplineRegMMIHistogramBins";
NSString* const BsplineRegMMISampleRateKey = @"BsplineRegMMISampleRate";
NSString* const BsplineRegLBFGSBCostConvergenceKey = @"BsplineRegLBFGSBCostConvergence";
NSString* const BsplineRegLBFGSBGradientToleranceKey = @"BsplineRegLBFGSBGradientTolerance";
NSString* const BsplineRegLBFGSDefaultStepSizeKey = @"BsplineRegLBFGSDefaultStepSize";
NSString* const BsplineRegLBFGSGradientConvergenceKey = @"BsplineRegRSGDGradientConvergence";
NSString* const BsplineRegRSGDMinStepSizeKey = @"BsplineRegRSGDMinStepSize";
NSString* const BsplineRegRSGDMaxStepSizeKey = @"BsplineRegRSGDMaxStepSize";
NSString* const BsplineRegRSGDRelaxationFactorKey = @"BsplineRegRSGDRelaxationFactor";

// Demons specific
//NSString* const DemonsRegEnabledKey = @"DemonsRegEnabled";
NSString* const DemonsRegMaxIterKey = @"DemonsRegMaxIter";
NSString* const DemonsRegMultiresLevelsKey = @"DemonsRegMultiresLevels";
NSString* const DemonsRegMaxRMSErrorKey = @"DemonsRegMaxRMSError";
NSString* const DemonsRegHistogramBinsKey = @"DemonsRegHistogramBins";
NSString* const DemonsRegHistogramMatchPointsKey = @"DemonsRegHistogramMatchPoints";
NSString* const DemonsRegStandardDeviationsKey = @"DemonsRegStandardDeviations";


static NSMutableDictionary *defaultsDict;
static NSString* bundleId;
static NSUserDefaults* defaults;
static UserDefaults* sharedInstance;

@implementation UserDefaults

+ (void)initialize
{
    // We'll use this as a singleton so we set up the shared instance here.
    static BOOL initialised = NO;
    if (!initialised)
    {
        initialised = YES;
        sharedInstance = [[UserDefaults alloc] init];
    }
    
    // Initialise the user defaults pointer.
    defaults = [[NSUserDefaults alloc] init];
    
    // We use the Bundle Identifier to store our defaults.
    bundleId = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    
    // These are the initial "factory" settings. They will appear as the
    // defaults settings on the first running of the program
    NSDictionary* factoryDict = [self createFactoryDefaults];

    // We now get whatever may have been stored before.
    NSMutableDictionary* curDefaultsDict = [[defaults persistentDomainForName:bundleId] mutableCopy];

    // Remove any invalid keys/objects and reset the defaults
    [self removeObsoleteKeysFrom:curDefaultsDict using:factoryDict];
    [defaults setPersistentDomain:curDefaultsDict forName:bundleId];
   
    defaultsDict = [factoryDict mutableCopy];
    [defaultsDict addEntriesFromDictionary:curDefaultsDict];

    // Give back the memory
    [curDefaultsDict release];
    
    //LOG4M_TRACE(logger_, @".initialize: Set defaults %@ for domain %@", defaultsDict, bundleId);
}

+ (NSDictionary*)createFactoryDefaults
{
    NSDictionary* d =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:LOG4M_LEVEL_DEBUG], LoggerLevelKey,
     [NSNumber numberWithInt:MAX_32BIT_THREADS], NumberOfThreadsKey,
     [NSNumber numberWithBool:YES], UseDefaultNumberOfThreadsKey,
     [NSNumber numberWithInt:Demons], RegistrationSequenceKey,
     [NSNumber numberWithUnsignedInt:1], FixedImageNumberKey,
     @"Registered with DCEFit", SeriesDescriptionKey,

     [NSNumber numberWithUnsignedInt:2], RigidRegMultiresLevelsKey,
     [NSNumber numberWithInt:MattesMutualInformation], RigidRegMetricKey,
     [NSNumber numberWithInt:LBFGSB], RigidRegOptimizerKey,
     [NSArray arrayWithObjects:@50, @50, @50, @50, nil], RigidRegMMIHistogramBinsKey,
     [NSArray arrayWithObjects:@1.0, @1.0, @1.0, @1.0, nil], RigidRegMMISampleRateKey,
     [NSArray arrayWithObjects:@1e9, @1e9, @1e9, @1e9, nil], RigidRegLBFGSBCostConvergenceKey,
     [NSArray arrayWithObjects:@0.0, @0.0, @0.0, @0.0, nil], RigidRegLBFGSBGradientToleranceKey,
     [NSArray arrayWithObjects:@1e-5, @1e-5, @1e-5, @1e-5, nil], RigidRegLBFGSGradientConvergenceKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], RigidRegLBFGSDefaultStepSizeKey,
     [NSArray arrayWithObjects:@1e-6, @1e-5, @1e-4, @1e-4, nil], RigidRegRSGDMinStepSizeKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], RigidRegRSGDMaxStepSizeKey,
     [NSArray arrayWithObjects:@0.5, @0.5, @0.5, @0.5, nil], RigidRegRSGDRelaxationFactorKey,

     [NSArray arrayWithObjects:@1e-3, @1e-3, @1e-3, @1e-3, nil], RigidRegVersorOptTransScaleKey,
     [NSArray arrayWithObjects:@1e-6, @1e-5, @1e-4, @1e-4, nil], RigidRegVersorOptMinStepSizeKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], RigidRegVersorOptMaxStepSizeKey,
     [NSArray arrayWithObjects:@0.5, @0.5, @0.5, @0.5, nil], RigidRegVersorOptRelaxationFactorKey,
     [NSArray arrayWithObjects:@300, @200, @100, @100, nil], RigidRegMaxIterKey,

     [NSNumber numberWithBool:NO], DeformRegShowFieldKey,

     [NSArray arrayWithObjects:@300, @200, @100, @100, nil], BsplineRegMaxIterKey,
     [NSNumber numberWithUnsignedInt:3], BsplineRegMultiresLevelsKey,
     [NSNumber numberWithInt:MattesMutualInformation], BsplineRegMetricKey,
     [NSNumber numberWithInt:LBFGSB], BsplineRegOptimizerKey,
     [NSArray arrayWithObjects:[NSArray arrayWithObjects:@21, @21, @21, nil],
                               [NSArray arrayWithObjects:@15, @15, @15, nil],
                               [NSArray arrayWithObjects:@11, @11, @11, nil],
                               [NSArray arrayWithObjects:@9, @9, @9, nil], nil], BsplineRegGridSizeArrayKey,
     [NSArray arrayWithObjects:@50, @50, @50, @50, nil], BsplineRegMMIHistogramBinsKey,
     [NSArray arrayWithObjects:@1.0, @1.0, @1.0, @1.0, nil], BsplineRegMMISampleRateKey,
     [NSArray arrayWithObjects:@1e9, @1e9, @1e9, @1e9, nil], BsplineRegLBFGSBCostConvergenceKey,
     [NSArray arrayWithObjects:@0.0, @0.0, @0.0, @0.0, nil], BsplineRegLBFGSBGradientToleranceKey,
     [NSArray arrayWithObjects:@1e-5, @1e-4, @1e-3, @1e-3, nil],
                               BsplineRegLBFGSGradientConvergenceKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], BsplineRegLBFGSDefaultStepSizeKey,
     [NSArray arrayWithObjects:@1e-6, @1e-5, @1e-4, @1e-4, nil], BsplineRegRSGDMinStepSizeKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], BsplineRegRSGDMaxStepSizeKey,
     [NSArray arrayWithObjects:@0.5, @0.5, @0.5, @0.5, nil], BsplineRegRSGDRelaxationFactorKey,

     [NSArray arrayWithObjects:@100, @80, @60, @50, nil], DemonsRegMaxIterKey,
     [NSNumber numberWithUnsignedInt:2], DemonsRegMultiresLevelsKey,
     [NSArray arrayWithObjects:@1.0, @0.6, @0.4, @0.2, nil], DemonsRegMaxRMSErrorKey,
     [NSNumber numberWithUnsignedInt:1000], DemonsRegHistogramBinsKey,
     [NSNumber numberWithUnsignedInt:10], DemonsRegHistogramMatchPointsKey,
     [NSNumber numberWithFloat:1.0], DemonsRegStandardDeviationsKey,

     nil];
    
    return d;
}

+ (UserDefaults*)sharedInstance
{
    return sharedInstance;
}

+ (void)removeObsoleteKeysFrom:(NSMutableDictionary*)currentDict using:(NSDictionary*)validDict
{
    // Create an array of all of the valid keys.
    NSArray* validKeys = [validDict allKeys];

    // Create array of current keys, some of which may be invalid
    NSArray* dictKeys = [currentDict allKeys];
    for (NSString* key in dictKeys)
    {
        if (![validKeys containsObject:key])
            [currentDict removeObjectForKey:key];
        [currentDict class];
    }
}

- (void) setupLogger
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".UserDefaults"];
    logger_ = [[Logger newInstance:loggerName] retain];
}


+ (NSMutableDictionary*)defaultsDictionary
{
    return defaultsDict;
}

- (void)saveRegParams:(RegistrationParams*)data
{
    LOG4M_TRACE(logger_, @"Enter");

    // Set the values and keys that currently exist in the data.
    // This needs to be kept synchronized with the +initialize method
    [defaultsDict setObject:[NSNumber numberWithInt:data.loggerLevel]
                     forKey:LoggerLevelKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.numberOfThreads]
                     forKey:NumberOfThreadsKey];

    [defaultsDict setObject:[NSNumber numberWithInt:data.regSequence]
                     forKey:RegistrationSequenceKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.fixedImageNumber]
                     forKey:FixedImageNumberKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.fixedImageNumber]
                     forKey:FixedImageNumberKey];
    [defaultsDict setObject:data.seriesDescription
                     forKey:SeriesDescriptionKey];

    //[defaultsDict setObject:[NSNumber numberWithBool:data.rigidRegEnabled]
    //                 forKey:RigidRegEnabledKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.rigidRegMultiresLevels]
                     forKey:RigidRegMultiresLevelsKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.rigidRegMetric]
                     forKey:RigidRegMetricKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.rigidRegOptimizer]
                     forKey:RigidRegOptimizerKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegMMIHistogramBins]
                     forKey:RigidRegMMIHistogramBinsKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegMMISampleRate]
                     forKey:RigidRegMMISampleRateKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegLBFGSBCostConvergence]
                     forKey:RigidRegLBFGSBCostConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegLBFGSBGradientTolerance]
                     forKey:RigidRegLBFGSBGradientToleranceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegLBFGSGradientConvergence]
                     forKey:RigidRegLBFGSGradientConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegLBFGSDefaultStepSize]
                     forKey:RigidRegLBFGSDefaultStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegRSGDMinStepSize]
                     forKey:RigidRegRSGDMinStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegRSGDMaxStepSize]
                     forKey:RigidRegRSGDMaxStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegRSGDRelaxationFactor]
                     forKey:RigidRegRSGDRelaxationFactorKey];

    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegVersorOptTransScale]
                     forKey:RigidRegVersorOptTransScaleKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegVersorOptMinStepSize]
                     forKey:RigidRegVersorOptMinStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegVersorOptMaxStepSize]
                     forKey:RigidRegVersorOptMaxStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegVersorOptRelaxationFactor]
                     forKey:RigidRegVersorOptRelaxationFactorKey];

    [defaultsDict setObject:[NSArray arrayWithArray:data.rigidRegMaxIter]
                     forKey:RigidRegMaxIterKey];

    [defaultsDict setObject:[NSNumber numberWithBool:data.deformShowField]
                     forKey:DeformRegShowFieldKey];

    //    [defaultsDict setObject:[NSNumber numberWithBool:data.bsplineRegEnabled]
    //                     forKey:BsplineRegEnabledKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.bsplineRegMultiresLevels]
                     forKey:BsplineRegMultiresLevelsKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegMaxIter]
                     forKey:BsplineRegMaxIterKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.bsplineRegMetric]
                     forKey:BsplineRegMetricKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.bsplineRegOptimizer]
                     forKey:BsplineRegOptimizerKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegGridSizeArray]
                     forKey:BsplineRegGridSizeArrayKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegMMIHistogramBins]
                     forKey:BsplineRegMMIHistogramBinsKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegMMISampleRate]
                     forKey:BsplineRegMMISampleRateKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegLBFGSBCostConvergence]
                     forKey:BsplineRegLBFGSBCostConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegLBFGSBGradientTolerance]
                     forKey:BsplineRegLBFGSBGradientToleranceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegLBFGSGradientConvergence]
                     forKey:BsplineRegLBFGSGradientConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegLBFGSDefaultStepSize]
                     forKey:BsplineRegLBFGSDefaultStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegRSGDMinStepSize]
                     forKey:BsplineRegRSGDMinStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegRSGDMaxStepSize]
                     forKey:BsplineRegRSGDMaxStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.bsplineRegRSGDRelaxationFactor]
                     forKey:BsplineRegRSGDRelaxationFactorKey];

//    [defaultsDict setObject:[NSNumber numberWithBool:data.demonsRegEnabled]
//                     forKey:DemonsRegEnabledKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.demonsRegMultiresLevels]
                     forKey:DemonsRegMultiresLevelsKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.demonsRegMaxIter]
                     forKey:DemonsRegMaxIterKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.demonsRegMaxRMSError]
                     forKey:DemonsRegMaxRMSErrorKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.demonsRegHistogramBins]
                     forKey:DemonsRegHistogramBinsKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.demonsRegHistogramMatchPoints]
                     forKey:DemonsRegHistogramMatchPointsKey];
    [defaultsDict setObject:[NSNumber numberWithFloat:data.demonsRegStandardDeviations]
                     forKey:DemonsRegStandardDeviationsKey];


    // Set the current values for for next time
    [defaults setPersistentDomain: defaultsDict forName: bundleId];
}

- (void)saveDefaults:(NSMutableDictionary *)data
{
    LOG4M_TRACE(logger_, @"Enter");

    // Set the values and keys that currently exist in the data.
    // This needs to be kept synchronized with the +initialize method
    [defaultsDict addEntriesFromDictionary:data];

    // Set the current values for for next time
    [defaults setPersistentDomain: defaultsDict forName: bundleId];
}

- (void)dealloc
{
    LOG4M_TRACE(logger_, @"Enter");

    [logger_ release];
    [defaultsDict release];

    [super dealloc];
}

- (BOOL)keyExists:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	return ([defaultsDict valueForKey:key] != NULL);
}

-(BOOL)booleanForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
	NSNumber* value = [defaultsDict valueForKey:key];
    return [value boolValue];
}

-(void)setBoolean:(BOOL)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithBool:value] forKey:key];
}

-(NSInteger)integerForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	NSNumber* value = [defaultsDict valueForKey:key];
    return [value intValue];
}

-(void)setInteger:(int)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithInt: value] forKey:key];
}

-(unsigned)unsignedIntegerForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

	NSNumber* value = [defaultsDict valueForKey:key];
    return [value unsignedIntValue];
}

-(void)setUnsignedInteger:(unsigned)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %d, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithUnsignedInteger: value] forKey:key];
}

-(float)floatForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

    NSNumber* value = [defaultsDict valueForKey:key];
    return [value floatValue];
}

-(void)setFloat:(float)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %f, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithFloat:value] forKey:key];
}

-(float)doubleForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);

    NSNumber* value = [defaultsDict valueForKey:key];
    return [value floatValue];
}

-(void)setDouble:(float)value forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %f, key = %@", value, key);

	[defaultsDict setValue:[NSNumber numberWithDouble:value] forKey:key];
}

-(NSString*)stringForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
    return [defaultsDict valueForKey:key];
}

-(void)setString:(NSString*)string forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %@, key = %@", string, key);
    
	[defaultsDict setValue:[NSString stringWithString:string] forKey:key];
}

-(NSRect)rectForKey:(NSString *)key
{
    NSString* rectStr = [self stringForKey:key];
    return NSRectFromString(rectStr);
}

-(void)setRect:(NSRect)rect forKey:(NSString *)key
{
    NSString* rectStr = NSStringFromRect(rect);
    [self setString:rectStr forKey:key];
}

-(Region2D*)regionForKey:(NSString *)key
{
    NSString* regStr = [self stringForKey:key];
    return [Region2D regionFromString:regStr];
}

-(void)setRegion:(Region2D *)region forKey:(NSString *)key
{
    NSString* regStr = [region asString];
    [self setString:regStr forKey:key];
}

-(id)objectForKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"key = %@", key);
    
    return [defaultsDict valueForKey:key];
}

-(void)setObject:(id)data forKey:(NSString*)key
{
    LOG4M_TRACE(logger_, @"value = %@, key = %@", data, key);
    
	[defaultsDict setValue:data forKey:key];
}

@end


