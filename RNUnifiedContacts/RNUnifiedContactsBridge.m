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

// Label constants for phone numbers and emails
- (NSDictionary *)constantsToExport
{
  return @{
          @"phoneNumberLabel": @{
              @"HOME"     : @"home",
              @"WORK"     : @"work",
              @"MOBILE"   : @"mobile",
              @"IPHONE"   : @"iPhone",
              @"MAIN"     : @"main",
              @"HOME_FAX" : @"home fax",
              @"WORK_FAX" : @"work fax",
              @"PAGER"    : @"pager",
              @"OTHER"    : @"other",
              },
          @"emailAddressLabel": @{
              @"HOME"     : @"home",
              @"WORK"     : @"work",
              @"ICLOUD"   : @"iCloud",
              @"OTHER"    : @"other",
              },
         };
}

RCT_EXTERN_METHOD(getContact:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(searchContacts:(NSString *)searchText callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(addContact:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(updateContact:(NSString *)identifier contactData:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(deleteContact:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(userCanAccessContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(requestAccessToContacts:(RCTResponseSenderBlock)callback);

RCT_EXPORT_METHOD(openPrivacySettings) {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}



@end