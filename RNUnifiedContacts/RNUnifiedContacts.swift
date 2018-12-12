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
    
    let thumbnailCache = NSCache<NSString, NSDictionary>()
    let fullImageCache = NSCache<NSString, NSDictionary>()
    
    override init() {
        super.init()
        thumbnailCache.countLimit = 100;
        fullImageCache.countLimit = 20;
    }
    
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
    
    let keyMap : [String:String] = [
        "Birthday":CNContactBirthdayKey,
        "Dates":CNContactDatesKey,
        "DepartmentName":CNContactDepartmentNameKey,
        "EmailAddresses":CNContactEmailAddressesKey,
        "FamilyName":CNContactFamilyNameKey,
        "GivenName":CNContactGivenNameKey,
        "Identifier":CNContactIdentifierKey,
        "ImageDataAvailable":CNContactImageDataAvailableKey,
        "ImageData":CNContactImageDataKey,
        "InstantMessageAddresses":CNContactInstantMessageAddressesKey,
        "JobTitle":CNContactJobTitleKey,
        "MiddleName":CNContactMiddleNameKey,
        "NamePrefix":CNContactNamePrefixKey,
        "NameSuffix":CNContactNameSuffixKey,
        "Nickname":CNContactNicknameKey,
        "NonGregorianBirthday":CNContactNonGregorianBirthdayKey,
        "Note":CNContactNoteKey,
        "OrganizationName":CNContactOrganizationNameKey,
        "PhoneNumbers":CNContactPhoneNumbersKey,
        "PhoneticFamilyName":CNContactPhoneticFamilyNameKey,
        "PhoneticGivenName":CNContactPhoneticGivenNameKey,
        "PhoneticMiddleName":CNContactPhoneticMiddleNameKey,
        "PhoneticOrganizationName":CNContactPhoneticOrganizationNameKey,
        "PostalAddresses":CNContactPostalAddressesKey,
        "PreviousFamilyName":CNContactPreviousFamilyNameKey,
        "Relations":CNContactRelationsKey,
        "SocialProfiles":CNContactSocialProfilesKey,
        "ThumbnailImageData":CNContactThumbnailImageDataKey,
        "Type":CNContactTypeKey,
        "UrlAddresses":CNContactUrlAddressesKey
    ]
    
    let requiredFullNameKeys = [
        CNContactFamilyNameKey,
        CNContactGivenNameKey,
        CNContactMiddleNameKey,
        CNContactNamePrefixKey,
        CNContactNameSuffixKey,
        CNContactNicknameKey,
        CNContactOrganizationNameKey,
        CNContactTypeKey]
    
    func getKeys(_ fields:[String]) -> [String] {
        var keys : [String] = []
        for field in fields {
            if let key = keyMap[field] {
                keys.append(key)
            }
        }
        return keys
    }
    
    @objc func getContactImage(_ identifier:String, thumbnail:Bool, callback: (NSArray) -> ()) -> Void {
        let cache : NSCache<NSString, NSDictionary> = thumbnail ? thumbnailCache : fullImageCache
        var contactAsDictionary : NSDictionary!
        if let cachedDictionary = cache.object(forKey: identifier as NSString) {
            // use the cached version
            contactAsDictionary = cachedDictionary
        } else {
            let keysToFetch = thumbnail ? [CNContactThumbnailImageDataKey] : [CNContactImageDataKey]
            let cNContact = getCNContact( identifier, keysToFetch: keysToFetch as [CNKeyDescriptor] )
            if ( cNContact == nil ) {
                callback( ["Could not find a contact with the identifier ".appending(identifier), NSNull()] )
                return
            }
            contactAsDictionary = convertCNContactToDictionary( cNContact! )
            cache.setObject(contactAsDictionary, forKey: identifier as NSString)
        }
        callback( [NSNull(), contactAsDictionary] )
    }
    
    @objc func getContactWithFields(_ identifier: String, _ keysToFetch: [String], callback: (NSArray) -> () ) -> Void {
        let cNContact = getCNContact( identifier, keysToFetch: keysToFetch as [CNKeyDescriptor] )
        if ( cNContact == nil ) {
            callback( ["Could not find a contact with the identifier ".appending(identifier), NSNull()] )
            return
        }
        
        let contactAsDictionary = convertCNContactToDictionary( cNContact! )
        callback( [NSNull(), contactAsDictionary] )
    }
    
    @objc func getContactsWithFields(_ fields: [String], callback: (NSArray) -> ()) -> Void {
        var keys = keysToFetch
        var filterKeys : [String]? = []
        if fields.contains("RNFullName") {
            let baseKeys = self.getKeys(fields)
            let keysSet = NSMutableSet(array: baseKeys)
            keysSet.addObjects(from: requiredFullNameKeys)
            keys = keysSet.allObjects as! [String]
            filterKeys = baseKeys // we only want these keys to come back
            filterKeys?.append("fullName") // add special case for fullName
        }
        searchContactsWithKeys(nil, keys, filterKeys, callback: callback)
    }
    
    @objc func userCanAccessContacts(_ callback: (Array<Bool>) -> ()) -> Void {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus{
        case .notDetermined, .restricted, .denied:
            callback([false])
            
        case .authorized:
            callback([true])
        }
    }
    
    @objc func searchContactsWithKeys(_ searchText: String?, callback: (NSArray) -> ()) -> Void {
        searchContactsWithKeys(searchText, keysToFetch, nil, callback: callback)
    }
    
    @objc func searchContactsWithKeys(_ searchText: String?, _ keysToFetch : [String], _ filterKeys:[String]?, callback: (NSArray) -> ()) -> Void {
        let contactStore = CNContactStore()
        do {
            var cNContacts = [CNContact]()
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
            
            fetchRequest.sortOrder = CNContactSortOrder.givenName
            
            try contactStore.enumerateContacts(with: fetchRequest) { (cNContact, pointer) -> Void in
                if searchText == nil {
                    // Add all Contacts if no searchText is provided.
                    cNContacts.append(cNContact)
                } else {
                    // If the Contact contains the search string then add it.
                    if self.contactContainsText( cNContact, searchText: searchText! ) {
                        cNContacts.append(cNContact)
                    }
                }
            }
            
            var contacts = [NSDictionary]();
            for cNContact in cNContacts {
                contacts.append( convertCNContactToDictionary(cNContact, filterKeys) )
            }
            
            callback([NSNull(), contacts])
        } catch let error as NSError {
            NSLog("Problem getting contacts.")
            NSLog(error.localizedDescription)
            
            callback([error.localizedDescription, NSNull()])
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
                } else {
                    callback([false])
                    return
                }
            }
        }
    }

    @objc func alreadyRequestedAccessToContacts(_ callback: (Array<Bool>) -> ()) -> Void {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)

        switch authorizationStatus{
        case .notDetermined:
            callback([false])

        case .authorized, .restricted, .denied:
            callback([true])
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
    
    @objc func getGroup(_ identifier: String, callback: (NSArray) -> () ) -> Void {
        let cNGroup = getCNGroup( identifier )
        if ( cNGroup == nil ) {
            callback( ["Could not find a group with the identifier ".appending(identifier), NSNull()] )
            return
        }
        
        let groupAsDictionary = convertCNGroupToDictionary( cNGroup! )
        callback( [NSNull(), groupAsDictionary] )
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
    
    @objc func getGroups(_ callback: (NSArray) -> ()) -> Void {
        let contactStore = CNContactStore()
        do {
            var cNGroups = [CNGroup]()
            
            try cNGroups = contactStore.groups(matching: nil)
            
            var groups = [NSDictionary]();
            for cNGroup in cNGroups {
                groups.append( convertCNGroupToDictionary(cNGroup) )
            }
            
            callback([NSNull(), groups])
        } catch let error as NSError {
            NSLog("Problem getting groups.")
            NSLog(error.localizedDescription)
            
            callback([error.localizedDescription, NSNull()])
        }
    }
    
    @objc func contactsInGroup(_ identifier: String, callback: (NSArray) -> ()) -> Void {
        let contactStore = CNContactStore()
        do {
            var cNContacts = [CNContact]()
            
            let predicate = CNContact.predicateForContactsInGroup(withIdentifier: identifier)
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
            
            fetchRequest.predicate = predicate
            fetchRequest.sortOrder = CNContactSortOrder.userDefault
            
            try contactStore.enumerateContacts(with: fetchRequest) { (cNContact, pointer) -> Void in
                cNContacts.append(cNContact)
            }
            
            var contacts = [NSDictionary]();
            for cNContact in cNContacts {
                contacts.append( convertCNContactToDictionary(cNContact) )
            }
            
            callback([NSNull(), contacts])
        } catch let error as NSError {
            NSLog("Problem getting contacts.")
            NSLog(error.localizedDescription)
            
            callback([error.localizedDescription, NSNull()])
        }
    }
    
    @objc func searchContacts(_ searchText: String?, callback: (NSArray) -> ()) -> Void {
        self.searchContactsWithKeys(searchText, keysToFetch, nil, callback: callback)
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

        for postalAddress in contactData["postalAddresses"] as! NSArray {
            let postalAddressAsCNLabeledValue = convertPostalAddressToCNLabeledValue ( postalAddress as! NSDictionary )

            mutableContact.postalAddresses.append( postalAddressAsCNLabeledValue )
        }

        do {
            
            saveRequest.add(mutableContact, toContainerWithIdentifier:nil)
            
            try contactStore.execute(saveRequest)
            
            callback( [NSNull(), true] )
            
        }
        catch let error as NSError {
            NSLog("Problem creating contact.")
            NSLog(error.localizedDescription)
            
            callback( [error.localizedDescription, false] )
        }
        
    }
    
    @objc func addGroup(_ groupData: NSDictionary, callback: (NSArray) -> () ) -> Void {
        
        let contactStore   = CNContactStore()
        let mutableGroup = CNMutableGroup()
        let saveRequest    = CNSaveRequest()
        
        if (groupData["name"] != nil) {
            mutableGroup.name = groupData["name"] as! String
        }
        
        do {
            saveRequest.add(mutableGroup, toContainerWithIdentifier:nil)
            
            try contactStore.execute(saveRequest)
            
            callback( [NSNull(), true] )
        }
        catch let error as NSError {
            NSLog("Problem creating group.")
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
            mutableContact.givenName = contactData["givenName"] as! String
        }

        if ( contactData["organizationName"] != nil ) {
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

        if ( contactData["postalAddresses"] != nil ) {
            mutableContact.postalAddresses.removeAll()

            for postalAddress in contactData["postalAddresses"] as! NSArray {
                let postalAddressAsCNLabeledValue = convertPostalAddressToCNLabeledValue ( postalAddress as! NSDictionary )

                mutableContact.postalAddresses.append( postalAddressAsCNLabeledValue )
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
    
    @objc func updateGroup(_ identifier: String, groupData: NSDictionary, callback: (NSArray) -> () ) -> Void {
        
        let contactStore = CNContactStore()
        
        let saveRequest = CNSaveRequest()
        
        let cNGroup = getCNGroup(identifier)
        
        let mutableGroup = cNGroup!.mutableCopy() as! CNMutableGroup
        
        if ( groupData["name"] != nil ) {
            mutableGroup.name = groupData["name"] as! String
        }
        
        do {
            saveRequest.update(mutableGroup)
            
            try contactStore.execute(saveRequest)
            
            callback( [NSNull(), true] )
        }
        catch let error as NSError {
            NSLog("Problem updating group with identifier: " + identifier)
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
            
            NSLog("Problem deleting unified contact with identifier: " + identifier)
            NSLog(error.localizedDescription)
            
            callback( [error.localizedDescription, false] )
        }
        
    }
    
    @objc func deleteGroup(_ identifier: String, callback: (NSArray) -> () ) -> Void {
        
        let contactStore = CNContactStore()
        
        let cNGroup = getCNGroup(identifier)
        
        let saveRequest = CNSaveRequest()
        
        let mutableGroup = cNGroup!.mutableCopy() as! CNMutableGroup
        
        saveRequest.delete(mutableGroup)
        
        do {
            try contactStore.execute(saveRequest)
            callback( [NSNull(), true] )
        }
        catch let error as NSError {
            NSLog("Problem deleting group with identifier: " + identifier)
            NSLog(error.localizedDescription)
            
            callback( [error.localizedDescription, false] )
        }
        
    }
    
    @objc func addContactsToGroup(_ identifier: String, contactIdentifiers: [NSString], callback: (NSArray) -> () ) -> Void {
        let contactStore = CNContactStore()
        let cNGroup = getCNGroup(identifier)
        let saveRequest = CNSaveRequest()
        let mutableGroup = cNGroup!.mutableCopy() as! CNMutableGroup
        
        do {
            for contactIdentifier in contactIdentifiers {
                let cNContact = getCNContact(contactIdentifier as String, keysToFetch: keysToFetch as [CNKeyDescriptor])
                let mutableContact = cNContact!.mutableCopy() as! CNMutableContact
                
                saveRequest.addMember(mutableContact, to: mutableGroup)
            }
            
            try contactStore.execute(saveRequest)
            callback( [NSNull(), true] )
        }
        catch let error as NSError {
            NSLog("Problem adding contacts to group with identifier: " + identifier)
            NSLog(error.localizedDescription)
            
            callback( [error.localizedDescription, false] )
        }
    }
    
    @objc func removeContactsFromGroup(_ identifier: String, contactIdentifiers: [NSString], callback: (NSArray) -> () ) -> Void {
        let contactStore = CNContactStore()
        let cNGroup = getCNGroup(identifier)
        let saveRequest = CNSaveRequest()
        let mutableGroup = cNGroup!.mutableCopy() as! CNMutableGroup
        
        do {
            for contactIdentifier in contactIdentifiers {
                let cNContact = getCNContact(contactIdentifier as String, keysToFetch: keysToFetch as [CNKeyDescriptor])
                let mutableContact = cNContact!.mutableCopy() as! CNMutableContact
                
                saveRequest.removeMember(mutableContact, from: mutableGroup)
            }
            
            try contactStore.execute(saveRequest)
            callback( [NSNull(), true] )
        }
        catch let error as NSError {
            NSLog("Problem removing contacts from group with identifier: " + identifier)
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
        } catch let error as NSError {
            NSLog("Problem getting unified contact with identifier: " + identifier)
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    func getCNGroup( _ identifier: String ) -> CNGroup? {
        let contactStore = CNContactStore()
        do {
            let predicate = CNGroup.predicateForGroups(withIdentifiers: [identifier])
            let cNGroup = try contactStore.groups(matching: predicate).first
            return cNGroup
        } catch let error as NSError {
            NSLog("Problem getting group with identifier: " + identifier)
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    func contactContainsText( _ cNContact: CNContact, searchText: String ) -> Bool {
        let searchText   = searchText.lowercased();
        let textToSearch = cNContact.givenName.lowercased() + " " + cNContact.familyName.lowercased() + " " + cNContact.nickname.lowercased()
        
        if searchText.isEmpty || textToSearch.contains(searchText) {
            return true
        } else {
            return false
        }
    }
    
    func getLabeledDict<T>(_ item: CNLabeledValue<T>) -> [String: Any] {
        var dict = [String: Any]()
        dict["identifier"] = item.identifier
        if let label = item.label {
            if label.hasPrefix("_$!<") && label.hasSuffix(">!$_") {
                addString(&dict, key: "label", value: label.substring(with: label.index(label.startIndex, offsetBy: 4)..<label.index(label.endIndex, offsetBy: -4)))
            } else {
                addString(&dict, key: "label", value: item.label)
            }
        }
        addString(&dict, key: "localizedLabel", value: item.label == nil ? nil : CNLabeledValue<T>.localizedString(forLabel: item.label!))
        return dict
    }
    
    func addString(_ dict: inout [String: Any], key: String, value: String?) {
        if let value = value, !value.isEmpty {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if (!trimmed.isEmpty) {
                dict[key] = value
            }
        }
    }
    
    func convertCNGroupToDictionary(_ cNGroup: CNGroup) -> NSDictionary {
        var group = [String: Any]()
        
        addString(&group, key: "identifier", value: cNGroup.identifier)
        addString(&group, key: "name", value: cNGroup.name)
        
        return group as NSDictionary
    }
    
    func convertCNContactToDictionary(_ cNContact: CNContact, _ filterKeys:[String]? = nil) -> NSDictionary {
        var contact = [String: Any]()
        
        func shouldInclude(_ key:String) -> Bool {
            if let keys = filterKeys {
                if !keys.contains(key) {
                    return false
                }
            }
            return cNContact.isKeyAvailable(key)
        }
        
        if (shouldInclude("birthday")) {
            if let birthday = cNContact.birthday {
                var date = [String: Int]()
                date["year"] = birthday.year == NSDateComponentUndefined ? nil : birthday.year
                date["month"] = birthday.month == NSDateComponentUndefined ? nil : birthday.month
                date["day"] = birthday.day == NSDateComponentUndefined ? nil : birthday.day
                contact["birthday"] = date
            }
        }
        
        if (shouldInclude("contactRelations")) {
            if cNContact.contactRelations.count > 0 {
                contact["contactRelations"] = cNContact.contactRelations.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "name", value: item.value.name)
                    return dict
                }
            }
        }
        
        if (shouldInclude("contactType")) {
            addString(&contact, key: "contactType", value: cNContact.contactType == CNContactType.person ? "person" : "organization")
        }
        
        if (shouldInclude("dates")){
            if cNContact.dates.count > 0 {
                contact["dates"] = cNContact.dates.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    dict["year"] = item.value.year == NSDateComponentUndefined ? nil : item.value.year
                    dict["month"] = item.value.month == NSDateComponentUndefined ? nil : item.value.month
                    dict["day"] = item.value.day == NSDateComponentUndefined ? nil : item.value.day
                    return dict
                }
            }
        }
        
        if (shouldInclude("departmentName")){
            addString(&contact, key: "departmentName", value: cNContact.departmentName)
        }
        
        if (shouldInclude("emailAddresses")) {
            if cNContact.emailAddresses.count > 0 {
                contact["emailAddresses"] = cNContact.emailAddresses.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "value", value: item.value as String)
                    return dict
                }
            }
        }
        
        if (shouldInclude("familyName")) {
            addString(&contact, key: "familyName", value: cNContact.familyName)
        }
        if (shouldInclude("givenName")) {
            addString(&contact, key: "givenName", value: cNContact.givenName)
        }
        if (shouldInclude("identifier")) {
            addString(&contact, key: "identifier", value: cNContact.identifier)
        }
        
        if (shouldInclude("imageDataAvailable")) {
            contact["imageDataAvailable"] = cNContact.imageDataAvailable
        }
        
        if (shouldInclude("instantMessageAddresses")) {
            if cNContact.instantMessageAddresses.count > 0 {
                contact["instantMessageAddresses"] = cNContact.instantMessageAddresses.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "service", value: item.value.service)
                    addString(&dict, key: "localizedService", value: CNInstantMessageAddress.localizedString(forService: item.value.service))
                    addString(&dict, key: "username", value: item.value.username)
                    return dict
                }
            }
        }
        
        if (shouldInclude("jobTitle")) {
            addString(&contact, key: "jobTitle", value: cNContact.jobTitle)
        }
        if (shouldInclude("middleName")) {
            addString(&contact, key: "middleName", value: cNContact.middleName)
        }
        if (shouldInclude("namePrefix")) {
            addString(&contact, key: "namePrefix", value: cNContact.namePrefix)
        }
        if (shouldInclude("nameSuffix")) {
            addString(&contact, key: "nameSuffix", value: cNContact.nameSuffix)
        }
        if (shouldInclude("nickname")) {
            addString(&contact, key: "nickname", value: cNContact.nickname)
        }
        
        if (shouldInclude("nonGregorianBirthday")) {
            if let nonGregorianBirthday = cNContact.nonGregorianBirthday {
                var date = [String: Int]()
                date["year"] = nonGregorianBirthday.year == NSDateComponentUndefined ? nil : nonGregorianBirthday.year
                date["month"] = nonGregorianBirthday.month == NSDateComponentUndefined ? nil : nonGregorianBirthday.month
                date["day"] = nonGregorianBirthday.day == NSDateComponentUndefined ? nil : nonGregorianBirthday.day
                contact["nonGregorianBirthday"] = date
            }
        }
        
        if (shouldInclude("note")) {
            addString(&contact, key: "note", value: cNContact.note)
        }
        if (shouldInclude("organizationName")) {
            addString(&contact, key: "organizationName", value: cNContact.organizationName)
        }
        
        if (shouldInclude("phoneNumbers")) {
            if cNContact.phoneNumbers.count > 0 {
                contact["phoneNumbers"] = cNContact.phoneNumbers.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "stringValue", value: item.value.stringValue)
                    addString(&dict, key: "countryCode", value: item.value.value(forKey: "countryCode") as? String)
                    addString(&dict, key: "digits", value: item.value.value(forKey: "digits") as? String)
                    return dict
                }
            }
        }
        
        if (shouldInclude("phoneticFamilyName")) {
            addString(&contact, key: "phoneticFamilyName", value: cNContact.phoneticFamilyName)
        }
        if (shouldInclude("phoneticGivenName")) {
            addString(&contact, key: "phoneticGivenName", value: cNContact.phoneticGivenName)
        }
        if (shouldInclude("phoneticMiddleName")) {
            addString(&contact, key: "phoneticMiddleName", value: cNContact.phoneticMiddleName)
        }
        
        // if #available(iOS 10.0, *) {
        //   contact["phoneticOrganizationName"]   = cNContact.phoneticOrganizationName
        // } else {
        //   // Fallback on earlier versions
        // }
        
        if (shouldInclude("postalAddresses")) {
            if cNContact.postalAddresses.count > 0 {
                contact["postalAddresses"] = cNContact.postalAddresses.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "street", value: item.value.street)
                    addString(&dict, key: "city", value: item.value.city)
                    addString(&dict, key: "state", value: item.value.state)
                    addString(&dict, key: "postalCode", value: item.value.postalCode)
                    addString(&dict, key: "country", value: item.value.country)
                    addString(&dict, key: "isoCountryCode", value: item.value.isoCountryCode)
                    addString(&dict, key: "mailingAddress", value: CNPostalAddressFormatter.string(from: item.value, style: .mailingAddress))
                    return dict
                }
            }
        }
        
        if (shouldInclude("previousFamilyName")) {
            addString(&contact, key: "previousFamilyName", value: cNContact.previousFamilyName)
        }
        
        if (shouldInclude("socialProfiles")) {
            if cNContact.socialProfiles.count > 0 {
                contact["socialProfiles"] = cNContact.socialProfiles.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "urlString", value: item.value.urlString)
                    addString(&dict, key: "username", value: item.value.username)
                    addString(&dict, key: "userIdentifier", value: item.value.userIdentifier)
                    addString(&dict, key: "service", value: item.value.service)
                    addString(&dict, key: "localizedService", value: CNSocialProfile.localizedString(forService: item.value.service))
                    return dict
                }
            }
        }
        
        if (shouldInclude("thumbnailImageData")) {
            if let thumbnailImageData = cNContact.thumbnailImageData {
                addString(&contact, key: "thumbnailImageData", value: thumbnailImageData.base64EncodedString(options: []))
            }
        }
        
        if (shouldInclude("urlAddresses")) {
            if cNContact.urlAddresses.count > 0 {
                contact["urlAddresses"] = cNContact.urlAddresses.map { (item) -> [String: Any] in
                    var dict = getLabeledDict(item)
                    addString(&dict, key: "value", value: item.value as String)
                    return dict
                }
            }
        }
        
        if (cNContact.areKeysAvailable(requiredFullNameKeys as [CNKeyDescriptor])) {
            addString(&contact, key: "fullName", value: CNContactFormatter.string( from: cNContact, style: .fullName ))
        }
        
        return contact as NSDictionary
    }
    
    func convertPhoneNumberToCNLabeledValue(_ phoneNumber: NSDictionary) -> CNLabeledValue<CNPhoneNumber> {
        var formattedLabel = String()
        let userProvidedLabel = phoneNumber["label"] as! String
        let lowercaseUserProvidedLabel = userProvidedLabel.lowercased()
        switch (lowercaseUserProvidedLabel) {
        case "home":
            formattedLabel = CNLabelHome
        case "work":
            formattedLabel = CNLabelWork
        case "mobile":
            formattedLabel = CNLabelPhoneNumberMobile
        case "iphone":
            formattedLabel = CNLabelPhoneNumberiPhone
        case "main":
            formattedLabel = CNLabelPhoneNumberMain
        case "home fax":
            formattedLabel = CNLabelPhoneNumberHomeFax
        case "work fax":
            formattedLabel = CNLabelPhoneNumberWorkFax
        case "pager":
            formattedLabel = CNLabelPhoneNumberPager
        case "other":
            formattedLabel = CNLabelOther
        default:
            formattedLabel = userProvidedLabel
        }
        
        return CNLabeledValue(
            label:formattedLabel,
            value:CNPhoneNumber(stringValue: phoneNumber["stringValue"] as! String)
        )
    }
    
    func convertEmailAddressToCNLabeledValue(_ emailAddress: NSDictionary) -> CNLabeledValue<NSString> {
        var formattedLabel = String()
        let userProvidedLabel = emailAddress["label"] as! String
        let lowercaseUserProvidedLabel = userProvidedLabel.lowercased()
        switch (lowercaseUserProvidedLabel) {
        case "home":
            formattedLabel = CNLabelHome
        case "work":
            formattedLabel = CNLabelWork
        case "icloud":
            formattedLabel = CNLabelEmailiCloud
        case "other":
            formattedLabel = CNLabelOther
        default:
            formattedLabel = userProvidedLabel
        }
        
        return CNLabeledValue(
            label:formattedLabel,
            value: emailAddress["value"] as! NSString
        )
    }

    func convertPostalAddressToCNLabeledValue(_ postalAddress: NSDictionary) -> CNLabeledValue<CNPostalAddress> {
        var formattedLabel = String()
        let userProvidedLabel = postalAddress["label"] as! String
        let lowercaseUserProvidedLabel = userProvidedLabel.lowercased()
        switch (lowercaseUserProvidedLabel) {
        case "home":
            formattedLabel = CNLabelHome
        case "work":
            formattedLabel = CNLabelWork
        case "other":
            formattedLabel = CNLabelOther
        default:
            formattedLabel = userProvidedLabel
        }

        let mutableAddress = CNMutablePostalAddress()
        mutableAddress.street = postalAddress["street"] as! String
        mutableAddress.city = postalAddress["city"] as! String
        mutableAddress.state = postalAddress["state"] as! String
        mutableAddress.postalCode = postalAddress["postalCode"] as! String
        mutableAddress.country = postalAddress["country"] as! String
 
        return CNLabeledValue(
            label: formattedLabel,
            value: mutableAddress as CNPostalAddress
        )
    }
}


