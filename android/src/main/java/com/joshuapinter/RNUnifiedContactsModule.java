package com.joshuapinter;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.HashMap;
import java.util.Map;

class RNUnifiedContactsModule extends ReactContextBaseJavaModule {

    private Promise mSelectContactPromise;
    private Callback mSuccessCallback;
    private Callback mErrorCallback;



    public RNUnifiedContactsModule(ReactApplicationContext reactContext) {
        super(reactContext);

        reactContext.addActivityEventListener(mActivityEventListener);
    }

    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
            // Get the URI and query the content provider for the phone number
            Uri contactUri = data.getData();

            ContentResolver contentResolver = activity.getContentResolver();

            Cursor contactCursor = contentResolver.query(contactUri, null, null, null, null);

            contactCursor.moveToFirst();

            int columnId = contactCursor.getColumnIndex(ContactsContract.Contacts._ID);
            String contactId = contactCursor.getString(columnId);

            int columnDisplayName = contactCursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME);
            String contactDisplayName = contactCursor.getString(columnDisplayName);

            Log.w("Test11", contactDisplayName);
            mSuccessCallback.invoke(contactDisplayName);

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

    @ReactMethod
    public void test1(String message, int duration) {
        Toast.makeText(getReactApplicationContext(), message, duration).show();
    }

    @ReactMethod
    public void test2(String message, int duration) {
        Toast.makeText(getReactApplicationContext(), message, duration).show();
    }

    @ReactMethod
    public Boolean userCanAccessContacts(Callback successCallback) {
        int userCanAccessContacts = ContextCompat.checkSelfPermission( getCurrentActivity(), Manifest.permission.READ_CONTACTS );

        if (userCanAccessContacts == PackageManager.PERMISSION_GRANTED) {
            successCallback.invoke(true);
            return true;
        }
        else {
            successCallback.invoke(false);
            return false;
        }
    }

    @ReactMethod
    public void requestAccessToContacts(Callback successCallback) {
        if (userCanAccessContacts(successCallback)) {
            successCallback.invoke(true);
        }
        else {
            // Request access.
            ActivityCompat.requestPermissions(getCurrentActivity(),
                    new String[]{Manifest.permission.READ_CONTACTS},
                    2);

            // Return boolean to user based on response of request.
        }
    }




//    @objc func requestAccessToContacts(_ callback: @escaping (Array<Bool>) -> ()) -> Void {
//        userCanAccessContacts() { (userCanAccessContacts) in
//
//            if (userCanAccessContacts == [true]) {
//                callback([true])
//
//                return
//            }
//
//            CNContactStore().requestAccess(for: CNEntityType.contacts) { (userCanAccessContacts, error) in
//
//                if (userCanAccessContacts) {
//                    callback([true])
//                    return
//                }
//                else {
//                    callback([false])
//
//                    return
//                }
//
//            }
//
//        }
//
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
