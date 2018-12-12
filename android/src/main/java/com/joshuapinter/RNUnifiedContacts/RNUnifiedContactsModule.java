package com.joshuapinter.RNUnifiedContacts;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.preference.PreferenceManager;
import android.provider.ContactsContract;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.text.format.DateFormat;
import android.util.Base64;
import android.Manifest;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

class RNUnifiedContactsModule extends ReactContextBaseJavaModule {

    private static final int ON_REQUEST_PERMISSIONS_RESULT_REQUEST_READ_CONTACTS            = 0;

    private static Callback          callback;

    private        ContentResolver   contentResolver;
    private        SharedPreferences sharedPreferences;


    public RNUnifiedContactsModule(ReactApplicationContext reactContext) {
        super(reactContext);

        sharedPreferences = PreferenceManager.getDefaultSharedPreferences( getReactApplicationContext() );

//        reactContext.addActivityEventListener( mActivityEventListener );
    }

    @Override
    public String getName() {
        return "RNUnifiedContacts";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
//        constants.put(DURATION_SHORT_KEY, Toast.LENGTH_SHORT);
//        constants.put(DURATION_LONG_KEY, Toast.LENGTH_LONG);
        return constants;

//        @"phoneNumberLabel": @{
//            @"HOME"     : @"home",
//            @"WORK"     : @"work",
//            @"MOBILE"   : @"mobile",
//            @"IPHONE"   : @"iPhone",
//            @"MAIN"     : @"main",
//            @"HOME_FAX" : @"home fax",
//            @"WORK_FAX" : @"work fax",
//            @"PAGER"    : @"pager",
//            @"OTHER"    : @"other",
//        },
//        @"emailAddressLabel": @{
//            @"HOME"     : @"home",
//            @"WORK"     : @"work",
//            @"ICLOUD"   : @"iCloud",
//            @"OTHER"    : @"other",
//        },
    }


    // TODO: This is no longer necessary because React Native has a PermissionsAndroid library that allows
    // us to just use Javascript for permissions management in Android. So, implement this in index.js.
    //
    @Deprecated
    @ReactMethod
    public void userCanAccessContacts( Callback callback ) {

        int userCanAccessContacts = ContextCompat.checkSelfPermission( getCurrentActivity(), Manifest.permission.READ_CONTACTS );

        if ( userCanAccessContacts == PackageManager.PERMISSION_GRANTED ) {
            callback.invoke( true );
        }
        else {
            callback.invoke( false );
        }
    }

    @Deprecated
    @ReactMethod
    public void requestAccessToContacts( Callback callback ) {

        RNUnifiedContactsModule.callback = callback;

        boolean canAccessContacts = ContextCompat.checkSelfPermission( getCurrentActivity(), Manifest.permission.READ_CONTACTS ) == PackageManager.PERMISSION_GRANTED;

        alreadyRequestedAccessToContacts( true ); // Set shared preferences so we know permissions have already been asked before. Note: This is the only way to properly capture when the User checksk "Don't ask again."

        if ( canAccessContacts ) {
            callback.invoke( true );
        }
        else {
            ActivityCompat.requestPermissions( getCurrentActivity(), new String[]{ Manifest.permission.READ_CONTACTS }, ON_REQUEST_PERMISSIONS_RESULT_REQUEST_READ_CONTACTS );
        }
    }

    @ReactMethod
    public void alreadyRequestedAccessToContacts( Callback callback ) {

        callback.invoke( alreadyRequestedAccessToContacts() );

    }

    @ReactMethod
    public void openPrivacySettings() {

        Uri packageUri = Uri.fromParts( "package", getReactApplicationContext().getPackageName(), null );

        Intent applicationDetailsSettingsIntent = new Intent();

        applicationDetailsSettingsIntent.setAction( Settings.ACTION_APPLICATION_DETAILS_SETTINGS );
        applicationDetailsSettingsIntent.setData( packageUri );
        applicationDetailsSettingsIntent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK );

        getReactApplicationContext().startActivity( applicationDetailsSettingsIntent );

    }

    @ReactMethod
    public void getContacts(final Callback callback) {
        searchContacts(null, callback);
    }

    @ReactMethod
    public void searchContacts( String searchText, Callback callback ) {

        WritableArray contacts   = Arguments.createArray();
        Set<Integer>  contactIds = new HashSet<Integer>();

        contentResolver = getCurrentActivity().getContentResolver();

        String   whereString = null;
        String[] whereParams = null;

        if ( searchText != null && !searchText.equals( "" ) ) {
            whereString = "display_name LIKE ?";
            whereParams = new String[]{ "%" + searchText + "%" };
        }

        Cursor contactCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null );

        while( contactCursor.moveToNext() ) {

            int contactId = getIntFromCursor( contactCursor, ContactsContract.Data.CONTACT_ID );

            if ( contactIds.contains( contactId ) ) continue;

            WritableMap contact = getContactDetailsFromContactId(contactId);

            contacts.pushMap(contact);

            contactIds.add( contactId );

        }

        contactCursor.close();

        // ToDo: Add check for error and return error callback instead
        // i.e. callback.invoke(error, null)

        // Success
        callback.invoke(null, contacts);
    }

//    @ReactMethod
//    public void selectContact(Callback callback) {
//        this.callback = callback;
//
//        Intent intent = new Intent(Intent.ACTION_PICK);
//        intent.setType(ContactsContract.Contacts.CONTENT_TYPE);
//        Activity currentActivity = getCurrentActivity();
//
//        if (intent.resolveActivity(currentActivity.getPackageManager()) != null) {
//            currentActivity.startActivityForResult(intent, 1);
//        }
//    }

    public static void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {

        switch( requestCode ) {

            case ON_REQUEST_PERMISSIONS_RESULT_REQUEST_READ_CONTACTS:

                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    callback.invoke( true );
                }
                else {
                    callback.invoke( false );
                }

                break;

        }

    }





    //////////////
    // PRIVATE  //
    //////////////

//    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
//
//        @Override
//        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
//        Uri contactUri = data.getData();
//
//        contentResolver = activity.getContentResolver();
//
//        Cursor contactCursor = contentResolver.query(contactUri, null, null, null, null);
//
//        contactCursor.moveToFirst();
//
//        int contactId = getIntFromCursor( contactCursor, ContactsContract.Contacts._ID );
//
//        WritableMap contact = getContactDetailsFromContactId( contactId );
//
//        callback.invoke( null, contact );
//        }
//
//    };


    private WritableMap getContactDetailsFromContactId(int contactId) {
        WritableMap contactMap = Arguments.createMap();

        String contactIdAsString = Integer.toString(contactId);
        contactMap.putString( "identifier", contactIdAsString ); // TODO: Consider standardizing on "id" instead.
        contactMap.putInt( "id",         contactId ); // Provided for Android devs used to getting it like this. Maybe _ID is necessary as well.

        WritableMap names = getNamesFromContact(contactId);
        contactMap.merge( names );

        WritableMap thumbnail = getThumbnailFromContact(contactId);
        contactMap.merge( thumbnail );

        WritableMap organization = getOrganizationFromContact(contactId);
        contactMap.merge( organization );

        WritableArray phoneNumbers = getPhoneNumbersFromContact(contactId);
        contactMap.putArray( "phoneNumbers", phoneNumbers );

        WritableArray emailAddresses = getEmailAddressesFromContact(contactId);
        contactMap.putArray( "emailAddresses", emailAddresses );

        WritableArray postalAddresses = getPostalAddressesFromContact(contactId);
        contactMap.putArray( "postalAddresses", postalAddresses );

        WritableMap birthday = getBirthdayFromContact(contactId);
        contactMap.putMap( "birthday", birthday );

        // TODO: Instant Messenger entries.

        String note = getNoteFromContact(contactId);
        contactMap.putString( "note", note );

        return contactMap;
    }

    @NonNull
    private WritableMap getNamesFromContact(int contactId) {
        WritableMap names = Arguments.createMap();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{String.valueOf(contactId), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE };

        Cursor namesCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        if ( !namesCursor.moveToFirst() ) return names;

        String prefix      = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.PREFIX );
        String givenName   = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME );
        String middleName  = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME );
        String familyName  = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME );
        String suffix      = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.SUFFIX );
        String displayName = getStringFromCursor( namesCursor, ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME );

        names.putString( "prefix",      prefix );
        names.putString( "givenName",   givenName );
        names.putString( "middleName",  middleName );
        names.putString( "familyName",  familyName );
        names.putString( "suffix",      suffix );
        names.putString( "displayName", displayName );
        names.putString( "fullName", displayName );


        namesCursor.close();

        return names;
    }

    @NonNull
    private WritableMap getThumbnailFromContact(int contactId) {
        WritableMap thumbnail = Arguments.createMap();

        // NOTE: See this for getting the high-res image: https://developer.android.com/reference/android/provider/ContactsContract.Contacts.Photo.html

        Uri contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, contactId);
        Uri photoUri = Uri.withAppendedPath(contactUri, ContactsContract.Contacts.Photo.CONTENT_DIRECTORY);

        Cursor photoCursor = contentResolver.query(
                photoUri,
                new String[] {ContactsContract.Contacts.Photo.PHOTO},
                null,
                null,
                null,
                null);

        if ( !photoCursor.moveToFirst() ) return thumbnail;

        byte[] data = photoCursor.getBlob(0);

        if (data != null) {
            thumbnail.putBoolean( "imageDataAvailable", true );

            String base64Thumbnail = Base64.encodeToString(data, Base64.DEFAULT);

            thumbnail.putString( "thumbnailImageData", base64Thumbnail );
        }
        else {
            thumbnail.putBoolean( "imageDataAvailable", false );
        }

        photoCursor.close();

        return thumbnail;
    }



    @NonNull
    private WritableMap getOrganizationFromContact(int contactId) {
        WritableMap organization = Arguments.createMap();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{String.valueOf(contactId), ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE };

        Cursor organizationCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        if ( !organizationCursor.moveToFirst() ) return organization;

        String company        = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.COMPANY );
        String department     = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.DEPARTMENT );
        String jobDescription = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.JOB_DESCRIPTION );
        String officeLocation = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.OFFICE_LOCATION );
        String symbol         = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.SYMBOL );
        String title          = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.TITLE );
        String label          = getStringFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.LABEL );

        int typeInt = getIntFromCursor( organizationCursor, ContactsContract.CommonDataKinds.Organization.TYPE );
        String type = String.valueOf(ContactsContract.CommonDataKinds.Organization.getTypeLabel(getCurrentActivity().getResources(), typeInt, ""));

        // NOTE: label is only set for custom Types, so to keep things consistent between iOS and Android
        // and to essentially give the user what they really want, which is the label, put type into label if it's null.
        if (label == null) label = type;

        organization.putString( "company",        company );
        organization.putString( "title",          title );

        // NOTE: Below are hidden because based on current Android Contacts only company and title can be entered.
        //   Additionally, it would be good to handle this as an array if we really want to do it correct. For example,
        //   somebody could be the chairman or on the board of multiple companies and that would be important to capture.
//        organization.putString( "department",     department );
//        organization.putString( "jobDescription", jobDescription );
//        organization.putString( "officeLocation", officeLocation );
//        organization.putString( "symbol",         symbol );
//        organization.putString( "label",          label );
//        organization.putString( "type",           type );

        organizationCursor.close();

        return organization;
    }

    @NonNull
    private WritableArray getPhoneNumbersFromContact(int contactId) {
        WritableArray phoneNumbers = Arguments.createArray();

        Cursor phoneNumbersCursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                null,
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = " + contactId,
                null,
                null);

        while (phoneNumbersCursor.moveToNext()) {
            WritableMap phoneNumber = Arguments.createMap();

            String number           = getStringFromCursor( phoneNumbersCursor, ContactsContract.CommonDataKinds.Phone.NUMBER );
            String normalizedNumber = getStringFromCursor( phoneNumbersCursor, ContactsContract.CommonDataKinds.Phone.NORMALIZED_NUMBER );
            String label            = getStringFromCursor( phoneNumbersCursor, ContactsContract.CommonDataKinds.Phone.LABEL );

            int typeInt = getIntFromCursor( phoneNumbersCursor, ContactsContract.CommonDataKinds.Phone.TYPE );
            String type = String.valueOf(ContactsContract.CommonDataKinds.Phone.getTypeLabel(getCurrentActivity().getResources(), typeInt, ""));

            // NOTE: label is only set for custom Types, so to keep things consistent between iOS and Android
            // and to essentially give the user what they really want, which is the label, put type into label if it's null.
            if (label == null) label = type;

            phoneNumber.putString("stringValue", number);
            phoneNumber.putString("digits", normalizedNumber);
            phoneNumber.putString("label", label);
            phoneNumber.putString("type", type);

            phoneNumbers.pushMap(phoneNumber);
        }
        phoneNumbersCursor.close();
        return phoneNumbers;
    }

    @NonNull
    private WritableArray getEmailAddressesFromContact(int contactId) {
        WritableArray emailAddresses = Arguments.createArray();

        Cursor emailAddressesCursor = contentResolver.query(
                ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                null,
                ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = " + contactId,
                null,
                null);

        while (emailAddressesCursor.moveToNext()) {
            WritableMap emailAddress = Arguments.createMap();

            String value = getStringFromCursor( emailAddressesCursor, ContactsContract.CommonDataKinds.Email.ADDRESS );
            String label = getStringFromCursor( emailAddressesCursor, ContactsContract.CommonDataKinds.Email.LABEL );

            int typeInt = getIntFromCursor( emailAddressesCursor, ContactsContract.CommonDataKinds.Email.TYPE );
            String type = String.valueOf(ContactsContract.CommonDataKinds.Email.getTypeLabel(getCurrentActivity().getResources(), typeInt, ""));

            // NOTE: label is only set for custom Types, so to keep things consistent between iOS and Android
            // and to essentially give the user what they really want, which is the label, put type into label if it's null.
            if (label == null) label = type;

            emailAddress.putString("value", value); // TODO: Consider standardizing on "address" instead of "value".
            emailAddress.putString("address", value); // Added in case Android devs are used to accessing it like this.
            emailAddress.putString("label", label);
            emailAddress.putString("type", type);

            emailAddresses.pushMap(emailAddress);
        }
        emailAddressesCursor.close();
        return emailAddresses;
    }

    @NonNull
    private WritableArray getPostalAddressesFromContact(int contactId) {
        WritableArray postalAddresses = Arguments.createArray();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{String.valueOf(contactId), ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE };

        Cursor postalAddressesCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        while (postalAddressesCursor.moveToNext()) {
            WritableMap postalAddress = Arguments.createMap();

            String pobox            = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.POBOX);
            String street           = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.STREET);
            String neighborhood     = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.NEIGHBORHOOD);
            String city             = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.CITY);
            String region           = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.REGION);
            String postcode         = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE);
            String country          = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY);
            String formattedAddress = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.FORMATTED_ADDRESS);

            String label = getStringFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.LABEL );

            int typeInt = getIntFromCursor( postalAddressesCursor, ContactsContract.CommonDataKinds.StructuredPostal.TYPE );
            String type = String.valueOf(ContactsContract.CommonDataKinds.StructuredPostal.getTypeLabel(getCurrentActivity().getResources(), typeInt, ""));

            // NOTE: label is only set for custom Types, so to keep things consistent between iOS and Android
            // and to essentially give the user what they really want, which is the label, put type into label if it's null.
            if (label == null) label = type;

            postalAddress.putString("pobox", pobox);
            postalAddress.putString("street", street);
            postalAddress.putString("neighborhood", neighborhood);
            postalAddress.putString("city", city);
            postalAddress.putString("state", region); // // TODO: Consider standardizing on "region" instead.
            postalAddress.putString("region", region); // Added in case Android devs are used to accessing it like this.
            postalAddress.putString("postalCode", postcode); // TODO: Consider standardizing on "postalCode" instead.
            postalAddress.putString("postcode", postcode); // Added in case Android devs are used to accessing it like this.
            postalAddress.putString("country", country);
            postalAddress.putString("stringValue", formattedAddress); // TODO: Consider standardizing on "formattedString" instead.
            postalAddress.putString("formattedAddress", formattedAddress); // Added in case Android devs are used to accessing it like this.
            postalAddress.putString("label", label);
            postalAddress.putString("type", type);

            postalAddresses.pushMap(postalAddress);
        }
        postalAddressesCursor.close();
        return postalAddresses;
    }

    private WritableMap getBirthdayFromContact(int contactId) {
        WritableMap birthday = Arguments.createMap();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.CommonDataKinds.Event.TYPE + " = ? AND " + ContactsContract.CommonDataKinds.Event.MIMETYPE + " = ?" ;
        String[] whereParams = new String[]{String.valueOf(contactId), String.valueOf(ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY), ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE };

        Cursor birthdayCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        if ( !birthdayCursor.moveToFirst() ) return null;

        String stringValue = getStringFromCursor( birthdayCursor, ContactsContract.CommonDataKinds.Event.START_DATE );

        birthday.putString( "stringValue", stringValue ); // This will always be returned but day/month/year might not be if it's not available.

        SimpleDateFormat dateFormat = new SimpleDateFormat("YYYY-MM-DD");

        try {
            Date birthdayDate = dateFormat.parse(stringValue);

            String day   = (String) DateFormat.format("dd",   birthdayDate);
            String month = (String) DateFormat.format("MM",   birthdayDate);
            String year  = (String) DateFormat.format("yyyy", birthdayDate);

            birthday.putString( "day", day );
            birthday.putString( "month", month );
            birthday.putString( "year", year );

        } catch (ParseException e) {
            e.printStackTrace();
        }

        birthdayCursor.close();

        return birthday;
    }

    private String getNoteFromContact(int contactId) {
        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{String.valueOf(contactId), ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE };

        Cursor noteCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        if ( !noteCursor.moveToFirst() ) return null;

        String note = getStringFromCursor( noteCursor, ContactsContract.CommonDataKinds.Note.NOTE );

        noteCursor.close();

        return note;
    }

    private String getStringFromCursor(Cursor cursor, String column) {
        int columnIndex = cursor.getColumnIndex(column);
        return cursor.getString(columnIndex);
    }

    private int getIntFromCursor(Cursor cursor, String column) {
        int columnIndex = cursor.getColumnIndex(column);
        return cursor.getInt(columnIndex);
    }

    private void alreadyRequestedAccessToContacts( boolean value ) {
        SharedPreferences.Editor sharedPreferencesEditor = sharedPreferences.edit();
        sharedPreferencesEditor.putBoolean( "ALREADY_REQUESTED_ACCESS_TO_CONTACTS", value );
        sharedPreferencesEditor.apply();
    }

    private boolean alreadyRequestedAccessToContacts() {
        return sharedPreferences.getBoolean( "ALREADY_REQUESTED_ACCESS_TO_CONTACTS", false );
    }

}