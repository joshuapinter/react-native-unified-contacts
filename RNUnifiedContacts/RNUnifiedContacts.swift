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
  
  
  @objc func getContacts(callback: (NSObject) -> ()) -> Void {
    
    NSLog("Inside getContacts in RNUnifiedContacts.swift")
    
    let contactStore = CNContactStore()

    let defaultContainerIdentifier = contactStore.defaultContainerIdentifier()

    let predicate = CNContact.predicateForContactsInContainerWithIdentifier(defaultContainerIdentifier)

    let keysToFetch = [ CNContactViewController.descriptorForRequiredKeys() ]

    do {
      let cNContacts = try contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
      
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
  
  
  func convertCNContactToDictionary(cNContact: CNContact) -> NSDictionary {
    
    var contact = [String: AnyObject]()
    
    contact["identifier"]         = cNContact.identifier
    contact["givenName"]          = cNContact.givenName
    contact["familyName"]         = cNContact.familyName
    contact["imageDataAvailable"] = cNContact.imageDataAvailable
    
    if (cNContact.imageDataAvailable) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedStringWithOptions([])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String
      
      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
      contact["imageData"] = imageDataAsBase64String
    }
    
    let contactAsNSDictionary = contact as NSDictionary
    
    return contactAsNSDictionary;
  }
  

}
