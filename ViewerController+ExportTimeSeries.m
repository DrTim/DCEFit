//
//  ViewerController+ExportTimeSeries.m
//  Test4DDuplicate
//
//  Created by Tim Allman on 2014-01-23.
//
//

#import "ViewerController+ExportTimeSeries.h"
#import "ProjectDefs.h"

#import <OsiriXAPI/DICOMExport.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/DicomDatabase.h>

#include <Log4m/Log4m.h>

@implementation ViewerController(ExportTimeSeries)

/*
 * Much of this is taken from ViewerController.exportAllImages:(NSString*)seriesName.
 * Some of the method calls may or may not be necessary but it appears to work as is.
 */

- (void)exportAllImages4D:(NSString *)seriesDescription
{
    NSString* loggerName = [[NSString stringWithUTF8String:LOGGER_NAME]
                            stringByAppendingString:@".ViewerController(ExportTimeSeries)"];
    Logger* logger_ = [[Logger newInstance:loggerName] autorelease];

    LOG4M_TRACE(logger_, @"Enter");

	if (exportDCM == nil)
        exportDCM = [[DICOMExport alloc] init];

    //Try to create a unique series number... Do you have a better idea??
    long seriesNumber = 5300 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute];
	[exportDCM setSeriesNumber:seriesNumber];
	[exportDCM setSeriesDescription: seriesDescription];

	LOG4M_INFO(logger_, @"Export 4D start. Series number: %ld; Series description %@",
               seriesNumber, seriesDescription);

	NSString *savedSeriesName = [dcmSeriesName stringValue]; // need for this is unknown
	[dcmSeriesName setStringValue: seriesDescription];
	NSMutableArray *producedFiles = [NSMutableArray array];
    short curMovieIndexSave = curMovieIndex; // save this so we can restore it

    // we have to use the instance variable curMovieIndex because the code in OsiriX that
    // exports the data uses it beyond our control.
    for (unsigned idx = 0; idx < maxMovieIndex; idx++)
    {
        [self setMovieIndex:idx];  // set curMovieIndex
        unsigned numImages = [pixList[curMovieIndex] count];
        for (unsigned idx = 0; idx < numImages; ++idx)
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

            if( [imageView flippedData])
                [imageView setIndex:(numImages - 1 - idx)];
            else
                [imageView setIndex:idx];

            [imageView sendSyncMessage: 0]; // need for this is unknown

            // dict is created autoreleased
            // first arg idicates whether to use screen image (YES) or memory (NO)
            NSDictionary* dict = [self exportDICOMFileInt:NO
                                                 withName:seriesDescription
                                               allViewers:NO];
            if (dict != nil)
                [producedFiles addObject:dict];
            
            [pool release];
        }
    }
	LOG4M_INFO(logger_, @"Export 4D end");

	if( [producedFiles count])
	{
        DicomDatabase* db = BrowserController.currentBrowser.database;

		[db addFilesAtPaths:[producedFiles valueForKey: @"file"]
          postNotifications:YES dicomOnly:YES rereadExistingItems:YES generatedByOsiriX: YES];
	}
    
	[dcmSeriesName setStringValue: savedSeriesName];
    [self setMovieIndex:curMovieIndexSave];
}

@end
