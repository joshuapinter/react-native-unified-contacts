package com.joshuapinter;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import java.util.HashMap;
import java.util.Map;

class RNUnifiedContactsModule extends ReactContextBaseJavaModule {

    private Promise mSelectContactPromise;
    private Callback mSuccessCallback;
    private Callback mErrorCallback;
    private ContentResolver contentResolver;

    public RNUnifiedContactsModule(ReactApplicationContext reactContext) {
        super(reactContext);

        reactContext.addActivityEventListener(mActivityEventListener);
    }

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            Uri contactUri = data.getData();

            contentResolver = activity.getContentResolver();

//            String[] projection = {ContactsContract.CommonDataKinds.Phone.NUMBER, ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME};

            Cursor contactCursor = contentResolver.query(contactUri, null, null, null, null);

            contactCursor.moveToFirst();

            int columnId = contactCursor.getColumnIndex(ContactsContract.Contacts._ID);
            String contactId = contactCursor.getString(columnId);

            WritableMap contactMap = getContactDetailsFromContactId(contactId);

//            int columnDisplayName = contactCursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME);
//            String contactDisplayName = contactCursor.getString(columnDisplayName);

//            String family_name =       contactCursor.getString(contactCursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME));


//            int columnStructredName = contactCursor.getColumnCount(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME);

            Log.w("Test12", contactMap.toString());
            mSuccessCallback.invoke(contactMap);

//            String[] projection = new String[]{ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME};
//            Cursor cursor = activity.getContentResolver().query(contactUri, projection,
//                    null, null, null);



//            // If the cursor returned is valid, get the phone number
//            if (cursor != null && cursor.moveToFirst()) {
//                int nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME);
//                String name = cursor.getString(nameIndex);
//
//                Log.w("Test1", "name:");
//                Log.w("Test1", name);
//                // Do something with the phone number
//                mSuccessCallback.invoke(name);
//            }
//
//            Log.w("Test1", "onActivityResult after");
//            mSelectContactPromise.resolve("Resolve1");
        }
    };

    private WritableMap getContactDetailsFromContactId(String contactId) {
        WritableMap contactMap = Arguments.createMap();

        contactMap.putString( "identifier", contactId ); // TODO: Consider standardizing on "id" instead.
        contactMap.putString( "id",         contactId ); // Provided for Android devs used to getting it like this. Maybe _ID is necessary as well.

        WritableMap names = getNamesFromContact(contactId);
        contactMap.merge( names );

        WritableArray phoneNumbers = getPhoneNumbersFromContact(contactId);
        contactMap.putArray( "phoneNumbers", phoneNumbers );

        WritableArray emailAddresses = getEmailAddressesFromContact(contactId);
        contactMap.putArray( "emailAddresses", emailAddresses );

        WritableArray postalAddresses = getPostalAddressesFromContact(contactId);
        contactMap.putArray( "postalAddresses", postalAddresses );

        // TODO: Birthday.
        // TODO: Anything else?

        String note = getNoteFromContact(contactId);
        contactMap.putString( "note", note );

        Log.w("Test13", contactMap.toString());

        return contactMap;
    }

    @NonNull
    private WritableMap getNamesFromContact(String contactId) {
        WritableMap names = Arguments.createMap();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{ contactId, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE };

        Cursor namesCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        namesCursor.moveToNext();

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

        namesCursor.close();

        return names;
    }

    @NonNull
    private WritableArray getPhoneNumbersFromContact(String contactId) {
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
    private WritableArray getEmailAddressesFromContact(String contactId) {
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
    private WritableArray getPostalAddressesFromContact(String contactId) {
        WritableArray postalAddresses = Arguments.createArray();

        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{ contactId, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE };

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

    @NonNull
    private String getNoteFromContact(String contactId) {
        String   whereString = ContactsContract.Data.CONTACT_ID + " = ? AND " + ContactsContract.Data.MIMETYPE + " = ?";
        String[] whereParams = new String[]{ contactId, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE };

        Cursor noteCursor = contentResolver.query(
                ContactsContract.Data.CONTENT_URI,
                null,
                whereString,
                whereParams,
                null,
                null);

        noteCursor.moveToNext();

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



//            // column index of the phone number
//            Cursor pCur = cr.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI,null,
//                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID +" = ?",
//                    new String[]{id}, null);
//            while (pCur.moveToNext()) {
//                String phone = pCur.getString(
//                        pCur.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
//                txtTelefono.setText(phone);         //print data
//            }
//            pCur.close();
//            // column index of the email
//            Cursor emailCur = cr.query(
//                    ContactsContract.CommonDataKinds.Email.CONTENT_URI,
//                    null,
//                    ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?",
//                    new String[]{id}, null);
//            while (emailCur.moveToNext()) {
//                // This would allow you get several email addresses
//                // if the email addresses were stored in an array
//                String email = emailCur.getString(
//                        emailCur.getColumnIndex(ContactsContract.CommonDataKinds.Email.ADDRESS));
//                txtMailContacto.setText(email);         //print data
//            }
//            emailCur.close();
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//    }


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

    // This is no longer necessary because React Native has a PermissionsAndroid library that allows
    // us to just use Javascript for permissions management in Android. So in index.js you'll see
    // it handled there.
    //
//    @ReactMethod
//    public Boolean userCanAccessContacts(Callback successCallback) {
//        int userCanAccessContacts = ContextCompat.checkSelfPermission( getCurrentActivity(), Manifest.permission.READ_CONTACTS );
//
//        if (userCanAccessContacts == PackageManager.PERMISSION_GRANTED) {
//            successCallback.invoke(true);
//            return true;
//        }
//        else {
//            successCallback.invoke(false);
//            return false;
//        }
//    }

    @ReactMethod
    public void selectContact(Callback errorCallback, Callback successCallback) {
        mErrorCallback = errorCallback;
        mSuccessCallback = successCallback;

        Intent intent = new Intent(Intent.ACTION_PICK);
        intent.setType(ContactsContract.Contacts.CONTENT_TYPE);
        Activity currentActivity = getCurrentActivity();

        if (intent.resolveActivity(currentActivity.getPackageManager()) != null) {
            currentActivity.startActivityForResult(intent, 1);
        }
    }

    @ReactMethod
    public void getMessages() {
        Activity currentActivity = getCurrentActivity();

        if (ContextCompat.checkSelfPermission(currentActivity.getBaseContext(), "android.permission.READ_SMS") != PackageManager.PERMISSION_GRANTED) {
            Log.w("Test3", "request permission");
            final int REQUEST_CODE_ASK_PERMISSIONS = 123;
            ActivityCompat.requestPermissions(currentActivity, new String[]{"android.permission.READ_SMS"}, REQUEST_CODE_ASK_PERMISSIONS);
        }

//        ActivityCompat.requestPermissions(currentActivity,
//                new String[]{Manifest.permission.READ_SMS},
//                1);

        Cursor cursor = currentActivity.getContentResolver().query(Uri.parse("content://sms/sent"), null, null, null, null);

        if (cursor.moveToFirst()) { // must check the result to prevent exception
            do {
                String msgData = "";
                for (int idx = 0; idx < cursor.getColumnCount(); idx++) {
                    msgData += " " + cursor.getColumnName(idx) + ":" + cursor.getString(idx);
                }

                Log.w("Test1", msgData);
            } while (cursor.moveToNext());
        } else {
            Log.w("Test2", "Messages empty.");
            // empty box, no SMS
        }
    }


}
