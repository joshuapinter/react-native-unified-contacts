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
}
