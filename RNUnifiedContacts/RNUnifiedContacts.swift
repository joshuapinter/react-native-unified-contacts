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
  
  @objc func addEvent(name: String, location: String, date: NSNumber, callback: (NSObject) -> ()) -> Void {
    NSLog("Inside addEvent in RNUnifiedContacts.swift")
    
    NSLog("Name: " + name)
    NSLog("Location: " + location)
    NSLog("Date: " + date.stringValue)
    
    let events = [
      [
        "Name" : "name1",
        "Location" : "location1",
        "Date" : "date1"
      ],
      [
        "Name" : "name2",
        "Location" : "location2",
        "Date" : "date2"
      ]
    ]
    
    callback([NSNull(), events])

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

//    let defaultContainerIdentifier = contactStore.defaultContainerIdentifier()

//    let predicate = CNContact.predicateForContactsInContainerWithIdentifier(defaultContainerIdentifier)
    
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
      
      callback([error, NSNull()])
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
    
    if (cNContact.imageDataAvailable) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedStringWithOptions([])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String
      
//      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
//      contact["imageData"] = imageDataAsBase64String
    }
    
    let contactAsNSDictionary = contact as NSDictionary
    
    return contactAsNSDictionary;
  }
  

}
