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
    CNContactDatesKey,
    CNContactDepartmentNameKey,
    CNContactEmailAddressesKey,
    CNContactFamilyNameKey,
    CNContactGivenNameKey,
    CNContactIdentifierKey,
    CNContactImageDataAvailableKey,
//    CNContactImageDataKey,
    CNContactInstantMessageAddressesKey,
    CNContactJobTitleKey,
    CNContactMiddleNameKey,
    CNContactNamePrefixKey,
    CNContactNameSuffixKey,
    CNContactNicknameKey,
    CNContactNonGregorianBirthdayKey,
    CNContactNoteKey,
    CNContactOrganizationNameKey,
    CNContactPhoneNumbersKey,
    CNContactPhoneticFamilyNameKey,
    CNContactPhoneticGivenNameKey,
    CNContactPhoneticMiddleNameKey,
    // CNContactPhoneticOrganizationNameKey,
    CNContactPostalAddressesKey,
    CNContactPreviousFamilyNameKey,
    CNContactRelationsKey,
    CNContactSocialProfilesKey,
    CNContactThumbnailImageDataKey,
    CNContactTypeKey,
    CNContactUrlAddressesKey,
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
  
  func getLabeledDict<T>(_ item: CNLabeledValue<T>) -> [String: Any] {
    var dict = [String: Any]()
    dict["identifier"] = item.identifier
    if let label = item.label {
      if label.hasPrefix("_$!<") && label.hasSuffix(">!$_") {
        dict["label"] = label.substring(with: label.index(label.startIndex, offsetBy: 4)..<label.index(label.endIndex, offsetBy: -4))
      } else {
        dict["label"] = item.label
      }
    }
    dict["localizedLabel"] = item.label == nil ? nil : CNLabeledValue<T>.localizedString(forLabel: item.label!)
    return dict
  }
  
  func addString(dict: inout [String: AnyObject], key: String, value: String?) {
    if let value = value, !value.isEmpty {
      dict[key] = value as AnyObject?
    }
  }

  func convertCNContactToDictionary(_ cNContact: CNContact) -> NSDictionary {
    var contact = [String: AnyObject]()
    
    if let birthday = cNContact.birthday {
      var date = [String: Int]()
      date["year"] = birthday.year == NSDateComponentUndefined ? nil : birthday.year
      date["month"] = birthday.month == NSDateComponentUndefined ? nil : birthday.month
      date["day"] = birthday.day == NSDateComponentUndefined ? nil : birthday.day
      contact["birthday"] = date as AnyObject?
    }
    
    if cNContact.contactRelations.count > 0 {
      contact["contactRelations"] = cNContact.contactRelations.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["name"] = item.value.name
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "contactType", value: cNContact.contactType == CNContactType.person ? "person" : "organization")
    
    if cNContact.dates.count > 0 {
      contact["dates"] = cNContact.dates.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["year"] = item.value.year == NSDateComponentUndefined ? nil : item.value.year
        dict["month"] = item.value.month == NSDateComponentUndefined ? nil : item.value.month
        dict["day"] = item.value.day == NSDateComponentUndefined ? nil : item.value.day
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "departmentName", value: cNContact.departmentName)
    
    if cNContact.emailAddresses.count > 0 {
      contact["emailAddresses"] = cNContact.emailAddresses.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["value"] = item.value
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "familyName", value: cNContact.familyName)
    addString(dict: &contact, key: "givenName", value: cNContact.givenName)
    addString(dict: &contact, key: "identifier", value: cNContact.identifier)
    
    contact["imageDataAvailable"] = cNContact.imageDataAvailable as AnyObject?
    
    if cNContact.instantMessageAddresses.count > 0 {
      contact["instantMessageAddresses"] = cNContact.instantMessageAddresses.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["service"] = item.value.service
        dict["localizedService"] = CNInstantMessageAddress.localizedString(forService: item.value.service)
        dict["username"] = item.value.username
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "jobTitle", value: cNContact.jobTitle)
    addString(dict: &contact, key: "middleName", value: cNContact.middleName)
    addString(dict: &contact, key: "namePrefix", value: cNContact.namePrefix)
    addString(dict: &contact, key: "nameSuffix", value: cNContact.nameSuffix)
    addString(dict: &contact, key: "nickname", value: cNContact.nickname)
    
    if let nonGregorianBirthday = cNContact.nonGregorianBirthday {
      var date = [String: Int]()
      date["year"] = nonGregorianBirthday.year == NSDateComponentUndefined ? nil : nonGregorianBirthday.year
      date["month"] = nonGregorianBirthday.month == NSDateComponentUndefined ? nil : nonGregorianBirthday.month
      date["day"] = nonGregorianBirthday.day == NSDateComponentUndefined ? nil : nonGregorianBirthday.day
      contact["nonGregorianBirthday"] = date as AnyObject?
    }
    
    addString(dict: &contact, key: "note", value: cNContact.note)
    addString(dict: &contact, key: "organizationName", value: cNContact.organizationName)
    
    if cNContact.phoneNumbers.count > 0 {
      contact["phoneNumbers"] = cNContact.phoneNumbers.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["stringValue"] = item.value.stringValue
        dict["countryCode"] = item.value.value(forKey: "countryCode") as? String
        dict["digits"]      = item.value.value(forKey: "digits") as? String
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "phoneticFamilyName", value: cNContact.phoneticFamilyName)
    addString(dict: &contact, key: "phoneticGivenName", value: cNContact.phoneticGivenName)
    addString(dict: &contact, key: "phoneticMiddleName", value: cNContact.phoneticMiddleName)
    
    // if #available(iOS 10.0, *) {
    //   contact["phoneticOrganizationName"]   = cNContact.phoneticOrganizationName as AnyObject?
    // } else {
    //   // Fallback on earlier versions
    // }
    
    if cNContact.postalAddresses.count > 0 {
      contact["postalAddresses"] = cNContact.postalAddresses.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["street"]      = item.value.street
        dict["city"]        = item.value.city
        dict["state"]       = item.value.state
        dict["postalCode"]  = item.value.postalCode
        dict["country"]     = item.value.country
        dict["isoCountryCode"]     = item.value.isoCountryCode
        dict["stringValue"] = CNPostalAddressFormatter.string(from: item.value, style: .mailingAddress)
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "previousFamilyName", value: cNContact.previousFamilyName)
    
    if cNContact.socialProfiles.count > 0 {
      contact["socialProfiles"] = cNContact.socialProfiles.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["urlString"] = item.value.urlString
        dict["username"] = item.value.username
        dict["userIdentifier"] = item.value.userIdentifier
        dict["service"] = item.value.service
        dict["localizedService"] = CNSocialProfile.localizedString(forService: item.value.service)
        return dict
        } as AnyObject?
    }
    
    if let thumbnailImageData = cNContact.thumbnailImageData {
      addString(dict: &contact, key: "thumbnailImageData", value: thumbnailImageData.base64EncodedString(options: []))
    }
    
    if cNContact.urlAddresses.count > 0 {
      contact["urlAddresses"] = cNContact.urlAddresses.map { (item) -> [String: Any] in
        var dict = getLabeledDict(item)
        dict["value"] = item.value
        return dict
        } as AnyObject?
    }
    
    addString(dict: &contact, key: "fullName", value: CNContactFormatter.string( from: cNContact, style: .fullName ))

    return contact as NSDictionary
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

}

