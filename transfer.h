#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "RCTBridgeModule.h"
#import "RCTLog.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@interface Transfer : NSObject <RCTBridgeModule, NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>
@end