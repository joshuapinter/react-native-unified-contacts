import {
  NativeModules
} from 'react-native';
export default NativeModules.RNUnifiedContacts;

// exports.userCanAccessContacts = function () {
//   var promise = new Promise(function (resolve, reject) {
//     PermissionsAndroid.checkPermission(PermissionsAndroid.PERMISSIONS.READ_CONTACTS)
//       .then(result => resolve(result))
//       .catch(result => reject(result));
//   });

//   return promise;
// }

// exports.requestAccessToContacts = function () {
//   var promise = new Promise(function (resolve, reject) {
//     PermissionsAndroid.requestPermission(PermissionsAndroid.PERMISSIONS.READ_CONTACTS)
//       .then(result => resolve(result))
//       .catch(result => reject(result));
//   });

//   return promise;
// }

// exports.getContacts = function () {
//   var promise = new Promise(function (resolve, reject) {

//     exports.requestAccessToContacts()
//       .then(granted => {
//         if (granted) {
//           RNUnifiedContacts.getContacts(
//             function (error) {
//               console.log(error);
//               reject(error);
//             },
//             function (contacts) {
//               resolve(contacts)
//             }
//           );
//         } else {
//           reject("No access to Contacts.");
//         }
//       })
//       .catch(result => reject(result));
//   });

//   return promise;
// }

// exports.selectContact = function () {
//   var promise = new Promise(function (resolve, reject) {

//     exports.requestAccessToContacts()
//       .then(granted => {
//         if (granted) {
//           RNUnifiedContacts.selectContact(
//             function (error) {
//               console.log(error);
//               reject(error);
//             },
//             function (contact) {
//               resolve(contact)
//             }
//           );
//         } else {
//           reject("No access to Contacts.");
//         }
//       })
//       .catch(result => reject(result))

//   });

//   return promise;
//   //   exports.requestAccessToContacts()
//   //     .then( granted => {
//   //       if (granted) {
//   //         RNUnifiedContacts.selectContact( 
//   //           function(error) { console.log(error); reject(error); }, 
//   //           function(contact) { resolve(contact) } );
//   //       }
//   //       else {
//   //         reject("No access to Contacts.");
//   //       }
//   //     })
//   //     .catch( result => reject(result) );
//   // });
// }