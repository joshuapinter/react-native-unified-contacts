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
    
    let keysToFetch = [ CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataAvailableKey, CNContactThumbnailImageDataKey ]
    
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
    let phoneNumbers = NSMutableArray()
    
    contact["identifier"]         = cNContact.identifier
    contact["givenName"]          = cNContact.givenName
    contact["familyName"]         = cNContact.familyName
    contact["imageDataAvailable"] = cNContact.imageDataAvailable
    
    if (cNContact.imageDataAvailable) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedStringWithOptions([])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String
      
//      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
//      contact["imageData"] = imageDataAsBase64String
    }
    
    if (cNContact.isKeyAvailable(CNContactPhoneNumbersKey)) {
      for number in cNContact.phoneNumbers {
        var numbers = [String: AnyObject]()
        let phoneNumber = (number.value as! CNPhoneNumber).valueForKey("digits") as! String
        let countryCode = (number.value as! CNPhoneNumber).valueForKey("countryCode") as? String
        let label = CNLabeledValue.localizedStringForLabel(number.label)
        numbers["number"] = phoneNumber
        numbers["countryCode"] = countryCode
        numbers["label"] = label
        phoneNumbers.addObject(numbers)
      }
      contact["phoneNumbers"] = phoneNumbers
    }
    
    let contactAsNSDictionary = contact as NSDictionary
    
    return contactAsNSDictionary;
  }
  

}
