//
//  RegisterImage.h
//  DCEFit
//
//  Created by Tim Allman on 2013-06-04.
//
//

#import <Foundation/Foundation.h>

#import "RegistrationManager.h"

#include "ItkTypedefs.h"
#include "ItkRegistrationParams.h"

@class Logger;

@interface RegisterImageOp : NSOperation <NSAlertDelegate>
{
    BOOL finished_;
    BOOL executing_;
    BOOL waitingForAnswer_;

    RegistrationManager* manager;
    ItkRegistrationParams* params;
    ProgressWindowController* progController;
    Image3DType::Pointer image;

    Logger* logger_;
}

- (id)initWithManager:(RegistrationManager*)regManager
   ProgressController:(ProgressWindowController*)controller;

- (void)start;

- (BOOL)isFinished;

- (BOOL)isExecuting;

- (BOOL)isConcurrent;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;

@end
