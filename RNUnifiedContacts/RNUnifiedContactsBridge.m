//
//  RNUnifiedContactsBridge.m
//  RNUnifiedContacts
//
//  Created by Joshua Pinter on 2016-03-23.
//  Copyright © 2016 Joshua Pinter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(RNUnifiedContacts, NSObject)

//RCT_EXTERN_METHOD(getContact:(NSObject *)contact callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(getContacts:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(searchContacts:(NSString *)searchText callback:(RCTResponseSenderBlock)callback);

RCT_EXTERN_METHOD(addEvent:(NSString *)name location:(NSString *)location date:(nonnull NSNumber *)date callback:(RCTResponseSenderBlock)callback);

@end