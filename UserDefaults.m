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

// general registration parameters
NSString* const FixedImageNumberKey = @"FixedImageNumber";
NSString* const SeriesDescriptionKey = @"SeriesDescription";

// rigid registration parameters
NSString* const RigidRegEnabledKey = @"RigidRegEnabled";
NSString* const RigidRegMultiresLevelsKey = @"RigidRegMultiresLevels";
NSString* const RigidRegMetricKey = @"RigidRegMetric";
NSString* const RigidRegOptimizerKey = @"RigidRegOptimizer";
NSString* const RigidRegMMIHistogramBinsKey = @"RigidRegMMIHistogramBins";
NSString* const RigidRegMMISampleRateKey = @"RigidRegMMISampleRate";
NSString* const RigidRegLBFGSBCostConvergenceKey = @"RigidRegLBFGSBCostConvergence";
NSString* const RigidRegLBFGSBGradientToleranceKey = @"RigidRegLBFGSBGradientTolerance";
NSString* const RigidRegLBFGSGradientConvergenceKey = @"RigidRegLBFGSGradientConvergence";
NSString* const RigidRegLBFGSDefaultStepSizeKey = @"RigidRegLBFGSDefaultStepSize";
NSString* const RigidRegRSGDMinStepSizeKey = @"RigidRegRSGDMinStepSizeKey";
NSString* const RigidRegRSGDMaxStepSizeKey = @"RigidRegRSGDMaxStepSizeKey";
NSString* const RigidRegRSGDRelaxationFactorKey = @"RigidRegRSGDRelaxationFactor";
NSString* const RigidRegVersorOptTransScaleKey = @"RigidRegVersorOptTransScale";
NSString* const RigidRegVersorOptMinStepSizeKey = @"RigidRegVersorOptMinStepSize";
NSString* const RigidRegVersorOptMaxStepSizeKey = @"RigidRegVersorOptMaxStepSize";
NSString* const RigidRegVersorOptRelaxationFactorKey = @"RigidRegVersorOptRelaxationFactor";
NSString* const RigidRegMaxIterKey = @"RigidRegMaxIter";

// deformable regitration parameters
NSString* const DeformRegEnabledKey = @"DeformRegEnable";
NSString* const DeformShowFieldKey = @"DeformShowField";
NSString* const DeformRegMultiresLevelsKey = @"DeformRegMultiresLevels";
NSString* const DeformRegGridSizeArrayKey = @"DeformRegGridSizeArray";
NSString* const DeformRegMetricKey = @"DeformRegMetric";
NSString* const DeformRegOptimizerKey = @"DeformRegOptimizer";
NSString* const DeformRegMMIHistogramBinsKey = @"DeformRegMMIHistogramBins";
NSString* const DeformRegMMISampleRateKey = @"DeformRegMMISampleRate";
NSString* const DeformRegLBFGSBCostConvergenceKey = @"DeformRegLBFGSBCostConvergence";
NSString* const DeformRegLBFGSBGradientToleranceKey = @"DeformRegLBFGSBGradientTolerance";
NSString* const DeformRegLBFGSDefaultStepSizeKey = @"DeformRegLBFGSDefaultStepSize";
NSString* const DeformRegLBFGSGradientConvergenceKey = @"DeformRegRSGDGradientConvergence";
NSString* const DeformRegRSGDMinStepSizeKey = @"DeformRegRSGDMinStepSizeKey";
NSString* const DeformRegRSGDMaxStepSizeKey = @"DeformRegRSGDMaxStepSizeKey";
NSString* const DeformRegRSGDRelaxationFactorKey = @"DeformRegRSGDRelaxationFactor";
NSString* const DeformRegMaxIterKey = @"DeformRegMaxIter";

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
     [NSNumber numberWithInt:MAX_THREADS], NumberOfThreadsKey,
     [NSNumber numberWithUnsignedInt:1], FixedImageNumberKey,
     @"Registered with DCEFit", SeriesDescriptionKey,

     [NSNumber numberWithBool:YES], RigidRegEnabledKey,
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

     [NSNumber numberWithBool:YES], DeformRegEnabledKey,
     [NSNumber numberWithBool:NO], DeformShowFieldKey,
     [NSNumber numberWithUnsignedInt:3], DeformRegMultiresLevelsKey,
     [NSNumber numberWithInt:MattesMutualInformation], DeformRegMetricKey,
     [NSNumber numberWithInt:LBFGSB], DeformRegOptimizerKey,
     [NSArray arrayWithObjects:[NSArray arrayWithObjects:@21, @21, @21, nil],
                               [NSArray arrayWithObjects:@15, @15, @15, nil],
                               [NSArray arrayWithObjects:@11, @11, @11, nil],
                               [NSArray arrayWithObjects:@9, @9, @9, nil], nil], DeformRegGridSizeArrayKey,
     [NSArray arrayWithObjects:@50, @50, @50, @50, nil], DeformRegMMIHistogramBinsKey,
     [NSArray arrayWithObjects:@1.0, @1.0, @1.0, @1.0, nil], DeformRegMMISampleRateKey,
     [NSArray arrayWithObjects:@1e9, @1e9, @1e9, @1e9, nil], DeformRegLBFGSBCostConvergenceKey,
     [NSArray arrayWithObjects:@0.0, @0.0, @0.0, @0.0, nil], DeformRegLBFGSBGradientToleranceKey,
     [NSArray arrayWithObjects:@1e-5, @1e-4, @1e-3, @1e-3, nil],
                               DeformRegLBFGSGradientConvergenceKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], DeformRegLBFGSDefaultStepSizeKey,
     [NSArray arrayWithObjects:@1e-6, @1e-5, @1e-4, @1e-4, nil], DeformRegRSGDMinStepSizeKey,
     [NSArray arrayWithObjects:@1e-1, @1e-1, @1e-1, @1e-1, nil], DeformRegRSGDMaxStepSizeKey,
     [NSArray arrayWithObjects:@0.5, @0.5, @0.5, @0.5, nil], DeformRegRSGDRelaxationFactorKey,
     [NSArray arrayWithObjects:@300, @200, @100, @100, nil], DeformRegMaxIterKey,

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

    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.fixedImageNumber]
                     forKey:FixedImageNumberKey];
    [defaultsDict setObject:data.seriesDescription
                     forKey:SeriesDescriptionKey];

    [defaultsDict setObject:[NSNumber numberWithBool:data.rigidRegEnabled]
                     forKey:RigidRegEnabledKey];
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

    [defaultsDict setObject:[NSNumber numberWithBool:data.deformRegEnabled]
                     forKey:DeformRegEnabledKey];
    [defaultsDict setObject:[NSNumber numberWithBool:data.deformShowField]
                     forKey:DeformShowFieldKey];
    [defaultsDict setObject:[NSNumber numberWithUnsignedInt:data.deformRegMultiresLevels]
                     forKey:DeformRegMultiresLevelsKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.deformRegMetric]
                     forKey:DeformRegMetricKey];
    [defaultsDict setObject:[NSNumber numberWithInt:data.deformRegOptimizer]
                     forKey:DeformRegOptimizerKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegGridSizeArray]
                     forKey:DeformRegGridSizeArrayKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegMMIHistogramBins]
                     forKey:DeformRegMMIHistogramBinsKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegMMISampleRate]
                     forKey:DeformRegMMISampleRateKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegLBFGSBCostConvergence]
                     forKey:DeformRegLBFGSBCostConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegLBFGSBGradientTolerance]
                     forKey:DeformRegLBFGSBGradientToleranceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegLBFGSGradientConvergence]
                     forKey:DeformRegLBFGSGradientConvergenceKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegLBFGSDefaultStepSize]
                     forKey:DeformRegLBFGSDefaultStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegRSGDMinStepSize]
                     forKey:DeformRegRSGDMinStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegRSGDMaxStepSize]
                     forKey:DeformRegRSGDMaxStepSizeKey];
    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegRSGDRelaxationFactor]
                     forKey:DeformRegRSGDRelaxationFactorKey];

    [defaultsDict setObject:[NSArray arrayWithArray:data.deformRegMaxIter]
                     forKey:DeformRegMaxIterKey];

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


