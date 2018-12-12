package com.exampleapp;

import android.content.pm.PackageManager;
import android.support.v4.app.ActivityCompat;

import com.facebook.react.ReactActivity;
import com.joshuapinter.RNUnifiedContacts.RNUnifiedContactsPackage;

public class MainActivity extends ReactActivity implements ActivityCompat.OnRequestPermissionsResultCallback {

    /**
     * Returns the name of the main component registered from JavaScript.
     * This is used to schedule rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
        return "ExampleApp";
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {

        RNUnifiedContactsPackage.onRequestPermissionsResult( requestCode, permissions, grantResults );

    }
}
