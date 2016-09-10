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

@available(iOS 9.0, *)
@objc(RNUnifiedContacts)
class RNUnifiedContacts: NSObject {

  //  iOS Reference: https://developer.apple.com/library/ios/documentation/Contacts/Reference/CNContact_Class/#//apple_ref/doc/constant_group/Metadata_Keys

  let keysToFetch = [
    CNContactBirthdayKey,
//    CNContactDatesKey,
//    CNContactDepartmentNameKey,
    CNContactEmailAddressesKey,
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
    CNContactNoteKey,
    CNContactOrganizationNameKey,
    CNContactPhoneNumbersKey,
//    CNContactPhoneticFamilyNameKey,
//    CNContactPhoneticGivenNameKey,
//    CNContactPhoneticMiddleNameKey,
    CNContactPostalAddressesKey,
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
  
  @objc func getContact(identifier: String, callback: (NSObject) -> () ) -> Void {
      
    let cNContact = getCNContact( identifier, keysToFetch: keysToFetch )
    
    if ( cNContact == nil ) {
      callback( ["Could not find a contact with the identifier " + identifier, NSNull()] )
      
      return
    }
    
    let contactAsDictionary = convertCNContactToDictionary( cNContact! )
    
    callback( [NSNull(), contactAsDictionary] )

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
      NSLog("Problem getting Contacts.")
      NSLog(error.localizedDescription)

      callback([error.localizedDescription, NSNull()])
    }
  }
  
  @objc func addContact(contactData: NSDictionary, callback: (NSObject) -> () ) -> Void {
    
    let contactStore   = CNContactStore()
    let mutableContact = CNMutableContact()
    let saveRequest    = CNSaveRequest()
    
    // TODO: Extend method to handle more fields.
    //
    if (contactData["givenName"] != nil) {
      mutableContact.givenName = contactData["givenName"] as! String
    }
    
    if (contactData["familyName"] != nil) {
      mutableContact.familyName = contactData["familyName"] as! String
    }
    
    if (contactData["organizationName"] != nil) {
      mutableContact.organizationName = contactData["organizationName"] as! String
    }
    
    for phoneNumber in contactData["phoneNumbers"] as! NSArray {
      let phoneNumberAsCNLabeledValue = convertPhoneNumberToCNLabeledValue( phoneNumber as! NSDictionary )
      
      mutableContact.phoneNumbers.append( phoneNumberAsCNLabeledValue )
    }
    
    for emailAddress in contactData["emailAddresses"] as! NSArray {
      let emailAddressAsCNLabeledValue = convertEmailAddressToCNLabeledValue ( emailAddress as! NSDictionary )
      
      mutableContact.emailAddresses.append( emailAddressAsCNLabeledValue )
    }
    
    do {
      
      saveRequest.addContact(mutableContact, toContainerWithIdentifier:nil)
      
      try contactStore.executeSaveRequest(saveRequest)
      
      callback( [NSNull(), true] )
      
    }
    catch let error as NSError {
      NSLog("Problem creating Contact.")
      NSLog(error.localizedDescription)
      
      callback( [error.localizedDescription, false] )
    }
    
  }
  
  @objc func updateContact(identifier: String, contactData: NSDictionary, callback: (NSObject) -> () ) -> Void {
    
    let contactStore = CNContactStore()
    
    let saveRequest = CNSaveRequest()
    
    let cNContact = getCNContact(identifier, keysToFetch: keysToFetch)
    
    let mutableContact = cNContact!.mutableCopy() as! CNMutableContact
    
    if ( contactData["givenName"] != nil ) {
      mutableContact.givenName = contactData["givenName"] as! String
    }
    
    if ( contactData["familyName"] != nil ) {
      mutableContact.familyName = contactData["familyName"] as! String
    }
    
    if ( contactData["givenName"] != nil ) {
      mutableContact.organizationName = contactData["organizationName"] as! String
    }
    
    if ( contactData["phoneNumbers"] != nil ) {
      mutableContact.phoneNumbers.removeAll()
      
      for phoneNumber in contactData["phoneNumbers"] as! NSArray {
        let phoneNumberAsCNLabeledValue = convertPhoneNumberToCNLabeledValue( phoneNumber as! NSDictionary )
        
        mutableContact.phoneNumbers.append( phoneNumberAsCNLabeledValue )
      }
    }
    
    if ( contactData["emailAddresses"] != nil ) {
      mutableContact.emailAddresses.removeAll()
      
      for emailAddress in contactData["emailAddresses"] as! NSArray {
        let emailAddressAsCNLabeledValue = convertEmailAddressToCNLabeledValue ( emailAddress as! NSDictionary )
        
        mutableContact.emailAddresses.append( emailAddressAsCNLabeledValue )
      }
    }
    
    
    do {
      
      saveRequest.updateContact(mutableContact)
      
      try contactStore.executeSaveRequest(saveRequest)
      
      callback( [NSNull(), true] )
      
    }
    catch let error as NSError {
      NSLog("Problem updating Contact with identifier: " + identifier)
      NSLog(error.localizedDescription)
      
      callback( [error.localizedDescription, false] )
    }
    
    
  }
  
  @objc func deleteContact(identifier: String, callback: (NSObject) -> () ) -> Void {
    
    let contactStore = CNContactStore()
    
    let cNContact = getCNContact( identifier, keysToFetch: keysToFetch )
    
    let saveRequest = CNSaveRequest()
    
    let mutableContact = cNContact!.mutableCopy() as! CNMutableContact
    
    saveRequest.deleteContact(mutableContact)
    
    do {
      
      try contactStore.executeSaveRequest(saveRequest)
      
      callback( [NSNull(), true] )
      
    }
    catch let error as NSError {
      
      NSLog("Problem deleting unified Contact with indentifier: " + identifier)
      NSLog(error.localizedDescription)
      
      callback( [error.localizedDescription, false] )
    }
    
  }
  


  /////////////
  // PRIVATE //
    
  func getCNContact( identifier: String, keysToFetch: [CNKeyDescriptor] ) -> CNContact? {
    let contactStore = CNContactStore()
    do {
      
      let cNContact = try contactStore.unifiedContactWithIdentifier( identifier, keysToFetch: keysToFetch )
      return cNContact
      
    }
    catch let error as NSError {
      
      NSLog("Problem getting unified Contact with identifier: " + identifier)
      NSLog(error.localizedDescription)
      return nil
      
    }
  }
  
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
    contact["fullName"]           = CNContactFormatter.stringFromContact( cNContact, style: .FullName )
    contact["organizationName"]   = cNContact.organizationName
    contact["note"]               = cNContact.note
    contact["imageDataAvailable"] = cNContact.imageDataAvailable

    if (cNContact.thumbnailImageData != nil) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedStringWithOptions([])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String

//      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
//      contact["imageData"] = imageDataAsBase64String
    }

    contact["phoneNumbers"]    = generatePhoneNumbers(cNContact)
    contact["emailAddresses"]  = generateEmailAddresses(cNContact)
    contact["postalAddresses"] = generatePostalAddresses(cNContact)

    if (cNContact.birthday != nil) {

      var birthday = [String: AnyObject]()

      if ( cNContact.birthday!.year != NSDateComponentUndefined ) {
        birthday["year"] = String(cNContact.birthday!.year)
      }

      if ( cNContact.birthday!.month != NSDateComponentUndefined ) {
        birthday["month"] = String(cNContact.birthday!.month)
      }

      if ( cNContact.birthday!.day != NSDateComponentUndefined ) {
        birthday["day"] = String(cNContact.birthday!.day)
      }

      contact["birthday"] = birthday

    }

    let contactAsNSDictionary = contact as NSDictionary

    return contactAsNSDictionary
  }

  func generatePhoneNumbers(cNContact: CNContact) -> [AnyObject] {
    var phoneNumbers: [AnyObject] = []

    for cNContactPhoneNumber in cNContact.phoneNumbers {

      var phoneNumber = [String: AnyObject]()

      let cNPhoneNumber = cNContactPhoneNumber.value as! CNPhoneNumber

      phoneNumber["identifier"]  = cNContactPhoneNumber.identifier
      phoneNumber["label"]       = CNLabeledValue.localizedStringForLabel( cNContactPhoneNumber.label ) as! String
      phoneNumber["stringValue"] = cNPhoneNumber.stringValue
      phoneNumber["countryCode"] = cNPhoneNumber.valueForKey("countryCode") as! String
      phoneNumber["digits"]      = cNPhoneNumber.valueForKey("digits") as! String

      phoneNumbers.append( phoneNumber )
    }

    return phoneNumbers
  }

  func generateEmailAddresses(cNContact: CNContact) -> [AnyObject] {
    var emailAddresses: [AnyObject] = []

    for cNContactEmailAddress in cNContact.emailAddresses {

      var emailAddress = [String: AnyObject]()

      emailAddress["identifier"]  = cNContactEmailAddress.identifier
      emailAddress["label"]       = CNLabeledValue.localizedStringForLabel( cNContactEmailAddress.label ) as! String
      emailAddress["value"]       = cNContactEmailAddress.value

      emailAddresses.append( emailAddress )
    }

    return emailAddresses
  }
  
  func convertPhoneNumberToCNLabeledValue(phoneNumber: NSDictionary) -> CNLabeledValue {
    var label = String()
    switch (phoneNumber["label"] as! String) {
      case "home":
        label = CNLabelHome
      case "work":
        label = CNLabelWork
      case "mobile":
        label = CNLabelPhoneNumberMobile
      case "iPhone":
        label = CNLabelPhoneNumberiPhone
      case "main":
        label = CNLabelPhoneNumberMain
      case "home fax":
        label = CNLabelPhoneNumberHomeFax
      case "work fax":
        label = CNLabelPhoneNumberWorkFax
      case "pager":
        label = CNLabelPhoneNumberPager
      case "other":
        label = CNLabelOther
      default:
        label = ""
    }
    
    return CNLabeledValue(
      label:label,
      value:CNPhoneNumber(stringValue: phoneNumber["stringValue"] as! String)
    )
  }
  
  func convertEmailAddressToCNLabeledValue(emailAddress: NSDictionary) -> CNLabeledValue {
    var label = String()
    switch (emailAddress["label"] as! String) {
      case "home":
        label = CNLabelHome
      case "work":
        label = CNLabelWork
      case "iCloud":
        label = CNLabelEmailiCloud
      case "other":
        label = CNLabelOther
      default:
        label = ""
    }
    
    return CNLabeledValue(
      label:label,
      value: emailAddress["value"] as! String
    )
  }
  

  func generatePostalAddresses(cNContact: CNContact) -> [AnyObject] {

    var postalAddresses: [AnyObject] = []

    for cNContactPostalAddress in cNContact.postalAddresses {

      var postalAddress = [String: AnyObject]()

      let cNPostalAddress = cNContactPostalAddress.value as! CNPostalAddress

      postalAddress["identifier"]  = cNContactPostalAddress.identifier
      postalAddress["label"]       = CNLabeledValue.localizedStringForLabel( cNContactPostalAddress.label )
      postalAddress["street"]      = cNPostalAddress.valueForKey("street") as! String
      postalAddress["city"]        = cNPostalAddress.valueForKey("city") as! String
      postalAddress["state"]       = cNPostalAddress.valueForKey("state") as! String
      postalAddress["postalCode"]  = cNPostalAddress.valueForKey("postalCode") as! String
      postalAddress["country"]     = cNPostalAddress.valueForKey("country") as! String
      postalAddress["stringValue"] = CNPostalAddressFormatter.stringFromPostalAddress(cNPostalAddress, style: .MailingAddress)

      // FIXME: For some reason, it throws an error with isoCountryCode.
      // postalAddress["isoCountryCode"] = cNPostalAddress.valueForKey("isoCountryCode") as! String

      postalAddresses.append( postalAddress )
    }

    return postalAddresses
  }

}
