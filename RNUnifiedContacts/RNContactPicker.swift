import Foundation
import Contacts
import ContactsUI

protocol ContactPickerDelegateDelegate: class {
  func done()
}

class PickContactDelegate: NSObject, CNContactPickerDelegate {
  unowned let delegate: ContactPickerDelegateDelegate
  var resolve: RCTPromiseResolveBlock?
  var reject: RCTPromiseRejectBlock?
  
  init(delegate: ContactPickerDelegateDelegate, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.delegate = delegate
    self.resolve = resolve
    self.reject = reject
  }
  
  deinit {
    reject?("deinit", "Deinitialized", nil)
  }
  
  func clear() {
    resolve = nil
    reject = nil
  }
  
  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    reject?("cancel", "User Cancelled", nil)
    clear()
    delegate.done()
  }
  
  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    resolve?(RNContactPicker.contactToDictionary(contact))
    clear()
    delegate.done()
  }
}

class PickContactsDelegate: NSObject, CNContactPickerDelegate {
  unowned let delegate: ContactPickerDelegateDelegate
  var resolve: RCTPromiseResolveBlock?
  var reject: RCTPromiseRejectBlock?
  
  init(delegate: ContactPickerDelegateDelegate, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    self.delegate = delegate
    self.resolve = resolve
    self.reject = reject
  }
  
  deinit {
    reject?("deinit", "Deinitialized", nil)
  }
  
  func clear() {
    resolve = nil
    reject = nil
  }
  
  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    reject?("cancel", "User Cancelled", nil)
    clear()
    delegate.done()
  }
  
  func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
    resolve?(contacts.map { x in RNContactPicker.contactToDictionary(x) })
    clear()
    delegate.done()
  }
}

@objc(RNContactPicker)
class RNContactPicker: NSObject, ContactPickerDelegateDelegate {
  var contactDelegate: PickContactDelegate?
  var contactsDelegate: PickContactsDelegate?
  
  @objc func constantsToExport() -> [String: Any] {
    return [
      "name": "RNContactPicker",
    ]
  }
  
  func getTopViewController(window: UIWindow?) -> UIViewController? {
    if let window = window {
      var top = window.rootViewController
      while true {
        if let presented = top?.presentedViewController {
          top = presented
        } else if let nav = top as? UINavigationController {
          top = nav.visibleViewController
        } else if let tab = top as? UITabBarController {
          top = tab.selectedViewController
        } else {
          break
        }
      }
      return top
    }
    return nil
  }
  
  func present(viewController: UIViewController) {
    DispatchQueue.main.async { [weak self] in
      self?.getTopViewController(window: UIApplication.shared.keyWindow)?.present(viewController, animated: true, completion: nil)
    }
  }
  
  @objc func pickContact(_ data: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let vc = CNContactPickerViewController()
    contactDelegate = PickContactDelegate(delegate: self, resolve: resolve, reject: reject)
    vc.delegate = contactDelegate
    
    if let displayedPropertyKeys = data["displayedPropertyKeys"] as? [String] {
      vc.displayedPropertyKeys = displayedPropertyKeys
    }
    
    present(viewController: vc)
  }
  
  @objc func pickContacts(_ data: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
    let vc = CNContactPickerViewController()
    contactsDelegate = PickContactsDelegate(delegate: self, resolve: resolve, reject: reject)
    vc.delegate = contactsDelegate
    
    if let displayedPropertyKeys = data["displayedPropertyKeys"] as? [String] {
      vc.displayedPropertyKeys = displayedPropertyKeys
    }
    
    present(viewController: vc)
  }
  
  func done() {
    contactDelegate = nil
    contactsDelegate = nil
  }
  
  static func addString(data: inout [String: Any], key: String, value: String?) {
    if let x = value, !x.isEmpty {
      data[key] = x
    }
  }
  
  static func add(_ data: inout [String: Any], key: String, value: Any?) {
    if let x = value {
      data[key] = x
    }
  }

  static func addLabel<T>(_ data: inout [String: Any], item: CNLabeledValue<T>) {
    data["identifier"] = item.identifier
    if let label = item.label {
      if label.hasPrefix("_$!<") && label.hasSuffix(">!$_") {
        addString(data: &data, key: "label", value: label.substring(with: label.index(label.startIndex, offsetBy: 4)..<label.index(label.endIndex, offsetBy: -4)))
      } else {
        addString(data: &data, key: "label", value: item.label)
      }
      addString(data: &data, key: "localizedLabel", value: CNLabeledValue<T>.localizedString(forLabel: label))
    }
  }
  
  static func addDate(_ data: inout [String: Any], value: DateComponents?) {
    if let x = value {
      add(&data, key: "year", value: x.year == NSDateComponentUndefined ? nil : x.year)
      add(&data, key: "month", value: x.month == NSDateComponentUndefined ? nil : x.month)
      add(&data, key: "day", value: x.day == NSDateComponentUndefined ? nil : x.day)
    }
  }
  
  static func contactToDictionary(_ contact: CNContact) -> [String: Any] {
    var data = [String: Any]()
    
    addString(data: &data, key: "identifier", value: contact.identifier)
    
    switch contact.contactType {
    case .organization:
      data["contactType"] = "organization"
      break
    case .person:
      data["contactType"] = "person"
    }
    
    addString(data: &data, key: "namePrefix", value: contact.namePrefix)
    addString(data: &data, key: "givenName", value: contact.givenName)
    addString(data: &data, key: "middleName", value: contact.middleName)
    addString(data: &data, key: "familyName", value: contact.familyName)
    addString(data: &data, key: "previousFamilyName", value: contact.previousFamilyName)
    addString(data: &data, key: "nameSuffix", value: contact.nameSuffix)
    addString(data: &data, key: "nickname", value: contact.nickname)
    
    addString(data: &data, key: "fullName", value: CNContactFormatter.string(from: contact, style: .fullName))
    
    addString(data: &data, key: "organizationName", value: contact.organizationName)
    addString(data: &data, key: "departmentName", value: contact.departmentName)
    addString(data: &data, key: "jobTitle", value: contact.jobTitle)
    
    addString(data: &data, key: "phoneticGivenName", value: contact.phoneticGivenName)
    addString(data: &data, key: "phoneticMiddleName", value: contact.phoneticMiddleName)
    addString(data: &data, key: "phoneticFamilyName", value: contact.phoneticFamilyName)
    if #available(iOS 10.0, *) {
      addString(data: &data, key: "phoneticOrganizationName", value: contact.phoneticOrganizationName)
    }
    
    addString(data: &data, key: "note", value: contact.note)
    
    addString(data: &data, key: "imageData", value: contact.imageData?.base64EncodedString())
    addString(data: &data, key: "thumbnailImageData", value: contact.thumbnailImageData?.base64EncodedString())
    data["imageDataAvailable"] = contact.imageDataAvailable
    
    data["phoneNumbers"] = contact.phoneNumbers.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "stringValue", value: val.value.stringValue)
      addString(data: &o, key: "countryCode", value: val.value.value(forKey: "countryCode") as? String)
      addString(data: &o, key: "digits", value: val.value.value(forKey: "digits") as? String)
      return o
      } as [[String: Any]]
    
    data["emailAddresses"] = contact.emailAddresses.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "value", value: val.value as String)
      return o
      } as [[String: Any]]
    
    data["postalAddresses"] = contact.postalAddresses.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "street", value: val.value.street)
      if #available(iOS 10.3, *) {
        addString(data: &o, key: "subLocality", value: val.value.subLocality)
      }
      addString(data: &o, key: "city", value: val.value.city)
      if #available(iOS 10.3, *) {
        addString(data: &o, key: "subAdministrativeArea", value: val.value.subAdministrativeArea)
      }
      addString(data: &o, key: "state", value: val.value.state)
      addString(data: &o, key: "postalCode", value: val.value.postalCode)
      addString(data: &o, key: "country", value: val.value.country)
      addString(data: &o, key: "isoCountryCode", value: val.value.isoCountryCode)
      addString(data: &o, key: "mailingAddress", value: CNPostalAddressFormatter.string(from: val.value, style: .mailingAddress))
      return o
      } as [[String: Any]]
    
    data["urlAddresses"] = contact.urlAddresses.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "value", value: val.value as String)
      return o
      } as [[String: Any]]
    
    data["contactRelations"] = contact.contactRelations.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "name", value: val.value.name)
      return o
      } as [[String: Any]]
    
    data["socialProfiles"] = contact.socialProfiles.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "urlString", value: val.value.urlString)
      addString(data: &o, key: "username", value: val.value.username)
      addString(data: &o, key: "userIdentifier", value: val.value.userIdentifier)
      addString(data: &o, key: "service", value: val.value.service)
      addString(data: &o, key: "localizedService", value: CNSocialProfile.localizedString(forService: val.value.service))
      return o
      } as [[String: Any]]
    
    data["instantMessageAddresses"] = contact.instantMessageAddresses.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addString(data: &o, key: "username", value: val.value.username)
      addString(data: &o, key: "service", value: val.value.service)
      addString(data: &o, key: "localizedService", value: CNInstantMessageAddress.localizedString(forService: val.value.service))
      return o
      } as [[String: Any]]
    
    if let value = contact.birthday {
      var o = [String: Any]()
      addDate(&o, value: value)
      data["birthday"] = o
    }
    
    if let value = contact.nonGregorianBirthday {
      var o = [String: Any]()
      addDate(&o, value: value)
      data["nonGregorianBirthday"] = o
    }
    
    data["dates"] = contact.dates.map { val in
      var o = [String: Any]()
      addLabel(&o, item: val)
      addDate(&o, value: val.value as DateComponents)
      return o
      } as [[String: Any]]
    
    return data
  }

}

