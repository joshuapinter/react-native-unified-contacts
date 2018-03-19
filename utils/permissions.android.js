import {
    NativeModules,
    PermissionsAndroid
} from 'react-native';

exports.userCanAccessContacts = () => {
    return new Promise(function (resolve, reject) {
        PermissionsAndroid.check(android.permission.READ_CONTACTS)
            .then(result => resolve(result))
            .catch(result => reject(result));
    });
}

exports.requestAccessToContacts = () => {
    return new Promise(function (resolve, reject) {
        PermissionsAndroid.request(android.permission.READ_CONTACTS)
            .then(result => resolve(result))
            .catch(result => reject(result));
    });
}

exports.alreadyRequestedAccessToContacts = () => {
    return true
    // return new Promise(function (resolve, reject) {
    //     PermissionsAndroid.check(android.permission.READ_CONTACTS)
    //         .then(result => resolve(result))
    //         .catch(result => reject(result));
    // });
}
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