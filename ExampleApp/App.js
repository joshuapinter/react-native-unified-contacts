/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  Button,
  FlatList,
  Platform,
  StyleSheet,
  Switch,
  Text,
  View
} from 'react-native';

import Contacts from 'react-native-unified-contacts';

const instructions = Platform.select({
  ios: 'Press Cmd+R to reload,\n' +
    'Cmd+D or shake for dev menu',
  android: 'Double tap R on your keyboard to reload,\n' +
    'Shake or press menu button for dev menu',
});

export default class App extends Component<{}> {

  constructor(props) {
    super(props);

    this.state = {
      canUserAccessContact: null,
      contacts: [],
    }

    this._checkIfUserCanAccessContacts();
  }

  render() {
    let badgeColor;
    if ( this.state.canUserAccessContacts ) {
      badgeColor = '#44B240';
    }
    else {
      badgeColor = '#FF838A';
    }

    return (
      <View style={styles.container}>
          <Text style={styles.welcome}>
            Unified Contacts Example App!
          </Text>

          <View style={ [ styles.badge, { backgroundColor: badgeColor } ] }>
            <Text style={ { color: 'white' } }>{ this.state.canUserAccessContacts ? 'ACCESS GRANTED' : 'ACCESS DENIED' }</Text>
          </View>

          <View style={ styles.button }>
            <Button title="Request Access to Contacts" onPress={ () => this._requestAccessToContacts() } />
          </View>

          <View style={ styles.button }>
            <Button title="Open Privacy Settings" onPress={ () => this._openPrivacySettings() } />
          </View>

          <View style={ styles.button }>
            <Button title="Get Contacts" onPress={ () => this._getContacts() } />
          </View>

          <FlatList
            style={styles.contacts}
            data={this.state.contacts}
            keyExtractor={ (contact) => contact.identifier }
            renderItem={ ({item}) => (
              <View style={styles.contact}>
                <Text style={styles.name}>
                  { item.fullName }
                </Text>
              </View>
            ) }
          />

      </View>
    );
  }

  // _checkIfUserCanAccessContacts() {
  //   Contacts.userCanAccessContacts( (canUserAccessContacts) => {
  //     console.log( "test1", canUserAccessContacts );

  //     this.setState( { canUserAccessContacts } );
  //   });
  // }
  async _checkIfUserCanAccessContacts() {
    canUserAccessContacts = await Contacts.userCanAccessContactsAsPromise();

    this.setState( { canUserAccessContacts } );
  }

  _requestAccessToContacts() {
    Contacts.requestAccessToContacts( (canUserAccessContacts) => {
      if (canUserAccessContacts) {
        console.log("User has access to Contacts!");
      }
      else {
        console.log("User DOES NOT have access to Contacts!");
      }

      this.setState( { canUserAccessContacts } );
    });
  }

  _openPrivacySettings() {
     Contacts.openPrivacySettings();
  }

  _getContacts() {
    if (this.state.canUserAccessContacts) {
      Contacts.getContacts( (error, contacts) =>  {
        if (error) {
          console.error(error);
        }
        else {
          // console.log('contacts[0].fullName', contacts[0].fullName);
          this.setState( { contacts } );
        }
      });
    }
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF',
    paddingTop: 40,
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  badge: {
    alignSelf: 'center',
    borderRadius: 5,
    paddingVertical: 5,
    paddingHorizontal: 7,
    marginBottom: 10,
  },
  button: {
    marginBottom: 10,
  },
  contacts: {
    flex: 1,
    marginTop: 20,
  },
  contact: {
    backgroundColor: '#FFFFFF',
    padding: 20,
    marginHorizontal: 20,
    marginVertical: 5,
    flex: 1,
    borderTopColor: '#A8E5FF',
    borderTopWidth: 5,
  },
  name: {
    fontSize: 24,
  },
});
