//
//  UserDefaults.h
//  Registration
//
//  Created by Tim Allman on 2012-09-26.
//
//

#import <Foundation/Foundation.h>
#import "Region2D.h"

/**
 * Keys for the dictionary holding the user defaults.
 */
extern NSString* const FixedImageNumberKey;
extern NSString* const SeriesDescriptionKey;

// rigid registration parameters
extern NSString* const RigidRegEnabledKey;
extern NSString* const RigidRegMultiresLevelsKey;
extern NSString* const RigidRegMetricKey;
extern NSString* const RigidRegOptimizerKey;
extern NSString* const RigidRegMMIHistogramBinsKey;
extern NSString* const RigidRegMMISampleRateKey;
extern NSString* const RigidRegLBFGSBCostConvergenceKey;
extern NSString* const RigidRegLBFGSBGradientToleranceKey;
extern NSString* const RigidRegLBFGSGradientConvergenceKey;
extern NSString* const RigidRegLBFGSDefaultStepSizeKey;
extern NSString* const RigidRegRSGDMinStepSizeKey;
extern NSString* const RigidRegRSGDMaxStepSizeKey;
extern NSString* const RigidRegRSGDRelaxationFactorKey;
extern NSString* const RigidRegVersorOptTransScaleKey;
extern NSString* const RigidRegVersorOptMinStepSizeKey;
extern NSString* const RigidRegVersorOptMaxStepSizeKey;
extern NSString* const RigidRegVersorOptRelaxationFactorKey;
extern NSString* const RigidRegMaxIterKey;

// deformable regitration parameters
extern NSString* const DeformRegEnabledKey;
extern NSString* const DeformShowFieldKey;
extern NSString* const DeformRegMultiresLevelsKey;
extern NSString* const DeformRegGridSizeArrayKey;
extern NSString* const DeformRegMetricKey;
extern NSString* const DeformRegOptimizerKey;
extern NSString* const DeformRegMMIHistogramBinsKey;
extern NSString* const DeformRegMMISampleRateKey;
extern NSString* const DeformRegLBFGSBCostConvergenceKey;
extern NSString* const DeformRegLBFGSBGradientToleranceKey;
extern NSString* const DeformRegLBFGSGradientConvergenceKey;
extern NSString* const DeformRegLBFGSDefaultStepSizeKey;
extern NSString* const DeformRegRSGDMinStepSizeKey;
extern NSString* const DeformRegRSGDMaxStepSizeKey;
extern NSString* const DeformRegRSGDRelaxationFactorKey;
extern NSString* const DeformRegMaxIterKey;

@class RegistrationParams;

/**
 * This class holds the user defaults for the plugin. It was created to 
 * separate the defaults for the plugin from those of OsiriX.
 *
 * The class is implemented as a singleton and the single application
 * wide instance is accessed with the +(UserDefaults*)instance method.
 */

@interface UserDefaults : NSObject
{
    Logger* logger_;
}

/**
 * The access method for the single instance of the UserDefaults class.
 * @returns Pointer to the instance.
 */
+ (UserDefaults*)sharedInstance;

/**
 * The defaults are stored as a dictionary during program execution. Key-Value
 * entries may be changed or added as needed.
 *
 * @returns The dictionary used to store default values.
 */
- (NSMutableDictionary*)dictionary;


/**
 * Saves the user defaults to disk, first updating the dictionary with the data.
 * @param data An instance of RegistrationData.
 */
- (void)save:(RegistrationParams*)data;

/**
 * Does the key exist in the defaults dictionary?
 * @param key The key we are looking for
 * @returns YES if the key exists, NO otherwise
 */
- (BOOL)keyExists:(NSString*)key;

/**
 * Get a BOOL value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (BOOL)booleanForKey:(NSString*)key;

/**
 * Set the BOOL value corresponding to key. If the key exists, the value will be 
 * updated.
 * @param value The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setBoolean:(BOOL)value forKey:(NSString*)key;

/**
 * Get an NSInteger value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (NSInteger)integerForKey:(NSString*)key;

/**
 * Set the NSInteger value corresponding to key. If the key exists, the value will be
 * updated.
 * @param value The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setInteger:(int)value forKey:(NSString*)key;

/**
 * Get an NSUInteger value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (unsigned)unsignedIntegerForKey:(NSString*)key;

/**
 * Set the NSUInteger value corresponding to key. If the key exists, the value will be
 * updated.
 * @param value The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setUnsignedInteger:(unsigned)value forKey:(NSString*)key;

/**
 * Get a float value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (float)floatForKey:(NSString*)key;

/**
 * Set the float value corresponding to key. If the key exists, the value will be
 * updated.
 * @param value The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setFloat:(float)value forKey:(NSString*)key;

/**
 * Get a double value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (float)doubleForKey:(NSString*)key;

/**
 * Set the double value corresponding to key. If the key exists, the value will be
 * updated.
 * @param value The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setDouble:(float)value forKey:(NSString*)key;

/**
 * Get a NSString value corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (NSString*)stringForKey:(NSString*)key;

/**
 * Set the NSString value corresponding to key. If the key exists, the value will be
 * updated.
 * @param string The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setString:(NSString*)string forKey:(NSString*)key;

/**
 * Get an NSRect corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (NSRect)rectForKey:(NSString*)key;

/**
 * Set the NSObject corresponding to key. If the key exists, the value will be
 * updated.
 * @param rect The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setRect:(NSRect)rect forKey:(NSString*)key;

/**
 * Get an NSRect corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (Region2D*)regionForKey:(NSString*)key;

/**
 * Set the NSObject corresponding to key. If the key exists, the value will be
 * updated.
 * @param region The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setRegion:(Region2D*)region forKey:(NSString*)key;

/**
 * Get an NSObject corresponding to the key.
 * If the key does not exist an exception will be thrown.
 *
 * @param key The key used to store the value.
 * @returns The value corresponding to the key.
 */
- (id)objectForKey:(NSString*)key;

/**
 * Set the NSObject corresponding to key. If the key exists, the value will be
 * updated.
 * @param data The value we wish to store.
 * @param key The key with which we wish to use to store the value.
 */
- (void)setObject:(id)data forKey:(NSString*)key;

@end
