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
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
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
    this._checkIfAlreadyRequestedAccessToContacts();
  }

  render() {
    let badgeColor;
    if ( this.state.canUserAccessContacts ) {
      badgeColor = '#44B240';
    }
    else {
      badgeColor = '#FF838A';
    }

    let alreadyRequestedBadgeColor;
    if ( this.state.alreadyRequestedAccessToContacts ) {
      alreadyRequestedBadgeColor = '#44B240';
    }
    else {
      alreadyRequestedBadgeColor = '#FF838A';
    }

    return (
      <ScrollView style={ styles.scrollView }>
        <View style={styles.container}>
            <Text style={styles.welcome}>
              Unified Contacts Example App!
            </Text>

            <View style={ [ styles.badge, { backgroundColor: badgeColor } ] }>
              <Text style={ { color: 'white' } }>{ this.state.canUserAccessContacts ? 'ACCESS GRANTED' : 'ACCESS DENIED' }</Text>
            </View>

            <View style={ [ styles.badge, { backgroundColor: alreadyRequestedBadgeColor } ] }>
              <Text style={ { color: 'white' } }>{ this.state.alreadyRequestedAccessToContacts ? 'ALREADY REQUESTED' : 'NEVER REQUESTED' }</Text>
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

            <View style={ styles.button }>
              <Button title="Select Contact" onPress={ () => this._selectContact() } />
            </View>

            <View style={ styles.button }>
              <TextInput value={ this.state.searchText } onChangeText={ text => this.setState( { searchText: text } ) } />
              <Button title="Search Name in Contacts" onPress={ () => this._searchContacts( this.state.searchText ) } />
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
      </ScrollView>
    );
  }

  _checkIfUserCanAccessContacts() {
    Contacts.userCanAccessContacts( canUserAccessContacts => {
      this.setState( { canUserAccessContacts } );
    } );
  }

  _checkIfAlreadyRequestedAccessToContacts() {
    Contacts.alreadyRequestedAccessToContacts( alreadyRequestedAccessToContacts => {
      this.setState( { alreadyRequestedAccessToContacts } );
    } );
  }

  _requestAccessToContacts() {
    Contacts.requestAccessToContacts( canUserAccessContacts => {
      this.setState( {
        canUserAccessContacts,
        alreadyRequestedAccessToContacts: true
      } );
    } );
  }

  _openPrivacySettings() {
     Contacts.openPrivacySettings();
  }

  _getContacts() {
    if ( !this.state.canUserAccessContacts ) return;

    Contacts.getContacts( (error, contacts) =>  {
      if (error) {
        console.error(error);
      }
      else {
        this.setState( { contacts } );
      }
    });
  }

  _selectContact() {
    Contacts.selectContact( ( error, contact ) => {
      if ( error ) {
        console.error( error );
      }
      else {
        const contacts = [ contact ];
        this.setState( { contacts } );
      }
    } );
  }

  // _selectContact() {
  //   if (this.state.canUserAccessContacts) {
  //     Contacts.selectContact( (error, contact) =>  {
  //       if (error) {
  //         console.error(error);
  //       }
  //       else {
  //         this.setState( { contacts: [ contact ] } );
  //       }
  //     });
  //   }
  // }

  _searchContacts( searchText ) {
    if (this.state.canUserAccessContacts) {
      Contacts.searchContacts( searchText, (error, contacts) =>  {
        if (error) {
          console.error(error);
        }
        else {
          this.setState( { contacts } );
        }
      });
    }
  }
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: '#F5FCFF',
  },
  container: {
    padding: 20,
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
    margin: 5,
    marginVertical: 5,
    flex: 1,
    borderTopColor: '#A8E5FF',
    borderTopWidth: 5,
    elevation: 2
  },
  name: {
    fontSize: 24,
  },
});
