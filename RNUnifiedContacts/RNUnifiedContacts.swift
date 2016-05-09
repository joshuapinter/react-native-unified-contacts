//
//  RNUnifiedContacts.swift
//  RNUnifiedContacts
//
//  Created by Joshua Pinter on 2016-03-23.
//  Copyright © 2016 Joshua Pinter. All rights reserved.
//

import Contacts
import ContactsUI
import Foundation

@objc(RNUnifiedContacts)
class RNUnifiedContacts: NSObject {

  //  iOS Reference: https://developer.apple.com/library/ios/documentation/Contacts/Reference/CNContact_Class/#//apple_ref/doc/constant_group/Metadata_Keys
  
  let keysToFetch = [
//    CNContactBirthdayKey,
//    CNContactDatesKey,
//    CNContactDepartmentNameKey,
//    CNContactEmailAddressesKey,
    CNContactFamilyNameKey,
    CNContactGivenNameKey,
    CNContactImageDataAvailableKey,
//    CNContactImageDataKey,
//    CNContactInstantMessageAddressesKey,
//    CNContactJobTitleKey,
    CNContactMiddleNameKey,
    CNContactNamePrefixKey,
    CNContactNameSuffixKey,
    CNContactNicknameKey,
//    CNContactNonGregorianBirthdayKey,
//    CNContactNoteKey,
    CNContactOrganizationNameKey,
    CNContactPhoneNumbersKey,
//    CNContactPhoneticFamilyNameKey,
//    CNContactPhoneticGivenNameKey,
//    CNContactPhoneticMiddleNameKey,
//    CNContactPostalAddressesKey,
//    CNContactPreviousFamilyNameKey,
//    CNContactRelationsKey,
//    CNContactSocialProfilesKey,
    CNContactThumbnailImageDataKey,
    CNContactTypeKey,
//    CNContactUrlAddressesKey
  ]
  
  
  @objc func userCanAccessContacts(callback: (NSObject) -> ()) -> Void {
    let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
    
    switch authorizationStatus{
      case .NotDetermined, .Restricted, .Denied:
        callback([false])
      
      
      case .Authorized:
        callback([true])
    }
  }
  
  @objc func requestAccessToContacts(callback: (NSObject) -> ()) -> Void {
    userCanAccessContacts() { (userCanAccessContacts) in
      
      if (userCanAccessContacts == [true]) {
        callback([true])
        
        return
      }
      
      CNContactStore().requestAccessForEntityType(CNEntityType.Contacts) { (userCanAccessContacts, error) in
        
        if (userCanAccessContacts) {
          callback([true])
          return
        }
        else {
          callback([false])
            
          return
        }
        
      }
      
    }

  }

  
  // Pseudo overloads getContacts but with no searchText.
  // Makes it easy to get all the Contacts with not passing anything.
  // NOTE: I tried calling the two methods the same but it barfed. It should be
  //   allowed but perhaps how React Native is handling it, it won't work. PR 
  //   possibility.
  //
  @objc func getContacts(callback: (NSObject) -> ()) -> Void {
    searchContacts(nil) { (result: NSObject) in
      callback(result)
    }
  }
  
  @objc func searchContacts(searchText: String?, callback: (NSObject) -> ()) -> Void {
    
    let contactStore = CNContactStore()
    
    do {
      
      var cNContacts = [CNContact]()
      
      let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
      
      fetchRequest.sortOrder = CNContactSortOrder.GivenName
      
      try contactStore.enumerateContactsWithFetchRequest(fetchRequest) { (cNContact, pointer) -> Void in

        if !cNContact.givenName.isEmpty {  // Ignore any Contacts that don't have a Given Name. Garbage Contact.
          
          if searchText == nil {
            // Add all Contacts if no searchText is provided.
            cNContacts.append(cNContact)
          }
          else {
            // If the Contact contains the search string then add it.
            if self.contactContainsText( cNContact, searchText: searchText! ) {
              cNContacts.append(cNContact)
            }
          }
        }
      }
      
      var contacts = [NSDictionary]();
      
      for cNContact in cNContacts {
        contacts.append( convertCNContactToDictionary(cNContact) )
      }

      callback([NSNull(), contacts])
    }
    catch let error as NSError {
      NSLog("Problem getting unified Contacts")
      NSLog(error.localizedDescription)
      
      callback([error.localizedDescription, NSNull()])
    }
    
  }
  
  //
  //  @objc func getContact(contact: NSObject, callback: (NSObject) -> () ) -> Void {
  //
  //    let contact = [
  //      "firstName": "firstName2",
  //      "lastName": "lastName2"
  //    ]
  //
  //    callback(contact)
  //    
  //  }
  //
  
  
  
  
  /////////////
  // PRIVATE //
  
  func contactContainsText( cNContact: CNContact, searchText: String ) -> Bool {
    let searchText   = searchText.lowercaseString;
    let textToSearch = cNContact.givenName.lowercaseString + " " + cNContact.familyName.lowercaseString
    
    if searchText.isEmpty || textToSearch.containsString(searchText) {
      return true
    }
    else {
      return false
    }
  }
  
  func convertCNContactToDictionary(cNContact: CNContact) -> NSDictionary {
    
    var contact = [String: AnyObject]()
    
    contact["identifier"]         = cNContact.identifier
    contact["givenName"]          = cNContact.givenName
    contact["familyName"]         = cNContact.familyName
    contact["imageDataAvailable"] = cNContact.imageDataAvailable
    
    if (cNContact.thumbnailImageData != nil) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedStringWithOptions([])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String
      
//      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
//      contact["imageData"] = imageDataAsBase64String
    }
    
    contact["phoneNumbers"] = generatePhoneNumbers(cNContact)
    
    let contactAsNSDictionary = contact as NSDictionary
    
    return contactAsNSDictionary
  }
  
  func generatePhoneNumbers(cNContact: CNContact) -> [AnyObject] {
    var phoneNumbers: [AnyObject] = []
    
    for cNContactPhoneNumber in cNContact.phoneNumbers {
      
      var phoneNumber = [String: AnyObject]()
      
      let cNPhoneNumber = cNContactPhoneNumber.value as! CNPhoneNumber
      
      phoneNumber["identifier"]  = cNContactPhoneNumber.identifier
      phoneNumber["label"]       = CNLabeledValue.localizedStringForLabel( cNContactPhoneNumber.label )
      phoneNumber["stringValue"] = cNPhoneNumber.stringValue
      phoneNumber["countryCode"] = cNPhoneNumber.valueForKey("countryCode") as! String
      phoneNumber["digits"]      = cNPhoneNumber.valueForKey("digits") as! String
      
      phoneNumbers.append( phoneNumber )
    }
    
    return phoneNumbers
  }
  

}
