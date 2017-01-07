package com.joshuapinter;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.HashMap;
import java.util.Map;

public class RNUnifiedContactsModule extends ReactContextBaseJavaModule {

    public RNUnifiedContactsModule(ReactApplicationContext reactContext) {
        super(reactContext);
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

    @ReactMethod
    public void test1(String message, int duration) {
        Toast.makeText(getReactApplicationContext(), message, duration).show();
    }

    @ReactMethod
    public void test2(String message, int duration) {
        Toast.makeText(getReactApplicationContext(), message, duration).show();
    }

    @ReactMethod
    public void selectContact() {
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
