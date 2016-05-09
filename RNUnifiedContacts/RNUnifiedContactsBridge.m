//
//  RNUnifiedContactsBridge.m
//  RNUnifiedContacts
//
//  Created by Joshua Pinter on 2016-03-23.
//  Copyright © 2016 Joshua Pinter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

#import "RCTBridgeModule.h"


@interface RCT_EXTERN_MODULE(RNUnifiedContacts, NSObject)

//RCT_EXTERN_METHOD(getContact:(NSObject *)contact callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(userCanAccessContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(requestAccessToContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getContact:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(searchContacts:(NSString *)searchText callback:(RCTResponseSenderBlock)callback);

RCT_EXPORT_METHOD(openPrivacySettings) {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

@end