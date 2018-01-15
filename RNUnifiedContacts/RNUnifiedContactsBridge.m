//
//  RNUnifiedContactsBridge.m
//  RNUnifiedContacts
//
//  Created by Joshua Pinter on 2016-03-23.
//  Copyright © 2016 Joshua Pinter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

#import <React/RCTBridgeModule.h>
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

#import <React/RCTViewManager.h>

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

// Contacts
RCT_EXTERN_METHOD(getContact:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(searchContacts:(NSString *)searchText callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(addContact:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(updateContact:(NSString *)identifier contactData:(NSDictionary *)contactData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(deleteContact:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

// Groups
RCT_EXTERN_METHOD(getGroup:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getGroups:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(contactsInGroup:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(addGroup:(NSDictionary *)groupData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(updateGroup:(NSString *)identifier groupData:(NSDictionary *)groupData callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(deleteGroup:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(addContactsToGroup:(NSString *)identifier contactIdentifiers:(NSArray *)contactIdentifiers callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(removeContactsFromGroup:(NSString *)identifier contactIdentifiers:(NSArray *)contactIdentifiers callback:(RCTResponseSenderBlock)callback);

// Generic
RCT_EXTERN_METHOD(userCanAccessContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(requestAccessToContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(generateHash:(NSString *)identifier callback:(RCTResponseSenderBlock)callback);

RCT_EXPORT_METHOD(openPrivacySettings) {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

//Picker
RCT_EXTERN_METHOD(pickContact:(NSDictionary *)data
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject);

RCT_EXTERN_METHOD(pickContacts:(NSDictionary *)data
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject);
@end
