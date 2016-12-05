//
//  RNUnifiedContacts.swift
//  RNUnifiedContacts
//
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


  @objc func userCanAccessContacts(_ callback: (Array<Bool>) -> ()) -> Void {
    let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)

    switch authorizationStatus{
      case .notDetermined, .restricted, .denied:
        callback([false])

      case .authorized:
        callback([true])
    }
  }

  @objc func requestAccessToContacts(_ callback: @escaping (Array<Bool>) -> ()) -> Void {
    userCanAccessContacts() { (userCanAccessContacts) in

      if (userCanAccessContacts == [true]) {
        callback([true])

        return
      }

      CNContactStore().requestAccess(for: CNEntityType.contacts) { (userCanAccessContacts, error) in

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
  
  @objc func getContact(_ identifier: String, callback: (NSArray) -> () ) -> Void {
      
    let cNContact = getCNContact( identifier, keysToFetch: keysToFetch as [CNKeyDescriptor] )
    
    if ( cNContact == nil ) {
      callback( ["Could not find a contact with the identifier ".appending(identifier), NSNull()] )
      
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
  @objc func getContacts(_ callback: (NSObject) -> ()) -> Void {
    searchContacts(nil) { (result: NSObject) in
      callback(result)
    }
  }

  @objc func searchContacts(_ searchText: String?, callback: (NSArray) -> ()) -> Void {

    let contactStore = CNContactStore()

    do {

      var cNContacts = [CNContact]()

      let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])

      fetchRequest.sortOrder = CNContactSortOrder.givenName

      try contactStore.enumerateContacts(with: fetchRequest) { (cNContact, pointer) -> Void in

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
  
  @objc func addContact(_ contactData: NSDictionary, callback: (NSArray) -> () ) -> Void {
    
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
      
      saveRequest.add(mutableContact, toContainerWithIdentifier:nil)
      
      try contactStore.execute(saveRequest)
      
      callback( [NSNull(), true] )
      
    }
    catch let error as NSError {
      NSLog("Problem creating Contact.")
      NSLog(error.localizedDescription)
      
      callback( [error.localizedDescription, false] )
    }
    
  }
  
  @objc func updateContact(_ identifier: String, contactData: NSDictionary, callback: (NSArray) -> () ) -> Void {
    
    let contactStore = CNContactStore()
    
    let saveRequest = CNSaveRequest()
    
    let cNContact = getCNContact(identifier, keysToFetch: keysToFetch as [CNKeyDescriptor])
    
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
      
      saveRequest.update(mutableContact)
      
      try contactStore.execute(saveRequest)
      
      callback( [NSNull(), true] )
      
    }
    catch let error as NSError {
      NSLog("Problem updating Contact with identifier: " + identifier)
      NSLog(error.localizedDescription)
      
      callback( [error.localizedDescription, false] )
    }
    
    
  }
  
  @objc func deleteContact(_ identifier: String, callback: (NSArray) -> () ) -> Void {
    
    let contactStore = CNContactStore()
    
    let cNContact = getCNContact( identifier, keysToFetch: keysToFetch as [CNKeyDescriptor] )
    
    let saveRequest = CNSaveRequest()
    
    let mutableContact = cNContact!.mutableCopy() as! CNMutableContact
    
    saveRequest.delete(mutableContact)
    
    do {
      
      try contactStore.execute(saveRequest)
      
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
    
  func getCNContact( _ identifier: String, keysToFetch: [CNKeyDescriptor] ) -> CNContact? {
    let contactStore = CNContactStore()
    do {
      
      let cNContact = try contactStore.unifiedContact( withIdentifier: identifier, keysToFetch: keysToFetch )
      return cNContact
      
    }
    catch let error as NSError {
      
      NSLog("Problem getting unified Contact with identifier: " + identifier)
      NSLog(error.localizedDescription)
      return nil
      
    }
  }
  
  func contactContainsText( _ cNContact: CNContact, searchText: String ) -> Bool {
    let searchText   = searchText.lowercased();
    let textToSearch = cNContact.givenName.lowercased() + " " + cNContact.familyName.lowercased()

    if searchText.isEmpty || textToSearch.contains(searchText) {
      return true
    }
    else {
      return false
    }
  }

  func convertCNContactToDictionary(_ cNContact: CNContact) -> NSDictionary {

    var contact = [String: AnyObject]()

    contact["identifier"]         = cNContact.identifier as AnyObject?
    contact["givenName"]          = cNContact.givenName as AnyObject?
    contact["familyName"]         = cNContact.familyName as AnyObject?
    contact["fullName"]           = CNContactFormatter.string( from: cNContact, style: .fullName ) as AnyObject?
    contact["organizationName"]   = cNContact.organizationName as AnyObject?
    contact["note"]               = cNContact.note as AnyObject?
    contact["imageDataAvailable"] = cNContact.imageDataAvailable as AnyObject?

    if (cNContact.thumbnailImageData != nil) {
      let thumbnailImageDataAsBase64String = cNContact.thumbnailImageData!.base64EncodedString(options: [])
      contact["thumbnailImageData"] = thumbnailImageDataAsBase64String as AnyObject?

//      let imageDataAsBase64String = cNContact.imageData!.base64EncodedStringWithOptions([])
//      contact["imageData"] = imageDataAsBase64String
    }

    contact["phoneNumbers"]    = generatePhoneNumbers(cNContact) as AnyObject?
    contact["emailAddresses"]  = generateEmailAddresses(cNContact) as AnyObject?
    contact["postalAddresses"] = generatePostalAddresses(cNContact) as AnyObject?

    if (cNContact.birthday != nil) {

      var birthday = [String: Int]()

      if ( cNContact.birthday!.year != NSDateComponentUndefined ) {
        birthday["year"] = cNContact.birthday!.year
      }

      if ( cNContact.birthday!.month != NSDateComponentUndefined ) {
        birthday["month"] = cNContact.birthday!.month
      }

      if ( cNContact.birthday!.day != NSDateComponentUndefined ) {
        birthday["day"] = cNContact.birthday!.day
      }

      contact["birthday"] = birthday as AnyObject?

    }

    let contactAsNSDictionary = contact as NSDictionary

    return contactAsNSDictionary
  }

  func generatePhoneNumbers(_ cNContact: CNContact) -> [AnyObject] {
    var phoneNumbers: [AnyObject] = []

    for cNContactPhoneNumber in cNContact.phoneNumbers {

      var phoneNumber = [String: String]()

      let cNPhoneNumber = cNContactPhoneNumber.value 

      phoneNumber["identifier"]  = cNContactPhoneNumber.identifier
      phoneNumber["label"]       = CNLabeledValue<NSString>.localizedString( forLabel: cNContactPhoneNumber.label ?? "" )
      phoneNumber["stringValue"] = cNPhoneNumber.stringValue
      phoneNumber["countryCode"] = cNPhoneNumber.value(forKey: "countryCode") as? String
      phoneNumber["digits"]      = cNPhoneNumber.value(forKey: "digits") as? String

      phoneNumbers.append( phoneNumber as AnyObject )
    }

    return phoneNumbers
  }

  func generateEmailAddresses(_ cNContact: CNContact) -> [AnyObject] {
    var emailAddresses: [AnyObject] = []

    for cNContactEmailAddress in cNContact.emailAddresses {

      var emailAddress = [String: String]()

      emailAddress["identifier"]  = cNContactEmailAddress.identifier
      emailAddress["label"]       = CNLabeledValue<NSString>.localizedString( forLabel: cNContactEmailAddress.label ?? "" )
      emailAddress["value"]       = cNContactEmailAddress.value as String

      emailAddresses.append( emailAddress as AnyObject )
    }

    return emailAddresses
  }
  
  func convertPhoneNumberToCNLabeledValue(_ phoneNumber: NSDictionary) -> CNLabeledValue<CNPhoneNumber> {
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
  
  func convertEmailAddressToCNLabeledValue(_ emailAddress: NSDictionary) -> CNLabeledValue<NSString> {
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
      value: emailAddress["value"] as! NSString
    )
  }
  

  func generatePostalAddresses(_ cNContact: CNContact) -> [AnyObject] {

    var postalAddresses: [AnyObject] = []

    for cNContactPostalAddress in cNContact.postalAddresses {

      var postalAddress = [String: String]()

      let cNPostalAddress = cNContactPostalAddress.value 

      postalAddress["identifier"]  = cNContactPostalAddress.identifier
      postalAddress["label"]       = CNLabeledValue<NSString>.localizedString( forLabel: cNContactPostalAddress.label ?? "" )
      postalAddress["street"]      = cNPostalAddress.value(forKey: "street") as? String
      postalAddress["city"]        = cNPostalAddress.value(forKey: "city") as? String
      postalAddress["state"]       = cNPostalAddress.value(forKey: "state") as? String
      postalAddress["postalCode"]  = cNPostalAddress.value(forKey: "postalCode") as? String
      postalAddress["country"]     = cNPostalAddress.value(forKey: "country") as? String
      postalAddress["stringValue"] = CNPostalAddressFormatter.string(from: cNPostalAddress, style: .mailingAddress)

      // FIXME: For some reason, it throws an error with isoCountryCode.
      // postalAddress["isoCountryCode"] = cNPostalAddress.valueForKey("isoCountryCode") as! String

      postalAddresses.append( postalAddress as AnyObject )
    }

    return postalAddresses
  }

}
