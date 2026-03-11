//
//  main.m
//  tccplus
//
//  Created by j on 3/23/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>

// Pointers to private TCC functions
int (*_TCCAccessSetForBundle)(CFStringRef, CFBundleRef);
int (*_TCCAccessResetForBundle)(CFStringRef, CFBundleRef);

// Fixed: added void to arguments to comply with modern C standards
void print_help(void) {
    const char *services[] = {
        "All", "Accessibility", "AddressBook", "AppleEvents", "AudioCapture",
        "BluetoothAlways", "BluetoothPeripheral", "BluetoothWhileInUse",
        "Calendar", "Calls", "Camera", "ContactlessAccess", "ContactsFull",
        "ContactsLimited", "DeveloperTool", "ExposureNotification",
        "FaceID", "FileProviderDomain", "FileProviderPresence",
        "FinancialData", "FocusStatus", "GameCenterFriends", "KeyboardNetwork",
        "ListenEvent", "Liverpool", "Location", "MediaLibrary", "Microphone",
        "Motion", "MSO", "NearbyInteraction", "Pasteboard", "Photos",
        "PhotosAdd", "PostEvent", "Reminders", "RemoteDesktop", "ScreenCapture",
        "SecureElementAccess", "SensorKitAmbientLightSensor", "SensorKitBedSensing",
        "SensorKitDeviceUsage", "SensorKitElevation", "SensorKitFacialMetrics",
        "SensorKitForegroundAppCategory", "SensorKitHistoricalCardioMetrics",
        "SensorKitHistoricalMobilityMetrics", "SensorKitKeyboardMetrics",
        "SensorKitLocationMetrics", "SensorKitMessageUsage", "SensorKitMotion",
        "SensorKitOdometer", "SensorKitPedometer", "SensorKitPhoneUsage",
        "SensorKitSoundDetection", "SensorKitSpeechMetrics",
        "SensorKitStrideCalibration", "SensorKitWatchAmbientLightSensor",
        "SensorKitWatchFallStats", "SensorKitWatchForegroundAppCategory",
        "SensorKitWatchHeartRate", "SensorKitWatchMotion",
        "SensorKitWatchOnWristState", "SensorKitWatchPedometer",
        "SensorKitWatchSpeechMetrics", "SensorKitWristTemperature",
        "ShareKit", "Siri", "SpeechRecognition", "SystemPolicyAllFiles",
        "SystemPolicyAppBundles", "SystemPolicyAppData",
        "SystemPolicyDesktopFolder", "SystemPolicyDeveloperFiles",
        "SystemPolicyDocumentsFolder", "SystemPolicyDownloadsFolder",
        "SystemPolicyNetworkVolumes", "SystemPolicyRemovableVolumes",
        "SystemPolicySysAdminFiles", "Ubiquity", "UserAvailability",
        "UserTracking", "VirtualMachineNetworking", "VoiceBanking",
        "WebBrowserPublicKeyCredential", "WebKitIntelligentTrackingPrevention",
        "Willow"
    };
    
    printf("Usage: tccplus [add/reset] SERVICE [BUNDLE_ID]\nServices:\n");
    size_t count = sizeof(services) / sizeof(services[0]);
    for (size_t i = 0; i < count; i++) {
        printf(" - %s\n", services[i]);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Check arguments
        if(argc < 4 || (strcmp(argv[1], "add") != 0 && strcmp(argv[1], "reset") != 0)) {
            print_help();
            return 0;
        }
        
        _TCCAccessSetForBundle = NULL;
        _TCCAccessResetForBundle = NULL;
        
        // Dynamically load TCC framework
        void *tccHandle = dlopen("/System/Library/PrivateFrameworks/TCC.framework/Versions/A/TCC", RTLD_LAZY);
        if(!tccHandle) {
            fprintf(stderr, "Could not open TCC framework\n");
            return 1;
        }
        
        _TCCAccessSetForBundle = dlsym(tccHandle, "TCCAccessSetForBundle");
        _TCCAccessResetForBundle = dlsym(tccHandle, "TCCAccessResetForBundle");
        
        if(!_TCCAccessSetForBundle || !_TCCAccessResetForBundle) {
            fprintf(stderr, "Could not find TCC symbols\n");
            dlclose(tccHandle);
            return 1;
        }
        
        // Get application URL by Bundle ID
        CFStringRef bundleId = CFStringCreateWithCString(kCFAllocatorDefault, argv[3], kCFStringEncodingUTF8);
        CFArrayRef urls = LSCopyApplicationURLsForBundleIdentifier(bundleId, NULL);
        CFRelease(bundleId);
        
        if(!urls || CFArrayGetCount(urls) == 0) {
            fprintf(stderr, "Could not locate bundle for bundle id %s\n", argv[3]);
            if(urls) CFRelease(urls);
            dlclose(tccHandle);
            return 1;
        }
        
        CFURLRef bundleURL = (CFURLRef)CFArrayGetValueAtIndex(urls, 0);
        CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
        CFRelease(urls);
        
        if(!bundle) {
            fprintf(stderr, "Could not create CFBundleRef\n");
            dlclose(tccHandle);
            return 1;
        }
        
        // Form service name (e.g. kTCCServiceCamera)
        CFStringRef serviceName = CFStringCreateWithCString(kCFAllocatorDefault, argv[2], kCFStringEncodingUTF8);
        CFStringRef service = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("kTCCService%@"), serviceName);
        CFRelease(serviceName);
        
        if(strcmp(argv[1], "add") == 0) {
            if(_TCCAccessSetForBundle(service, bundle) == 0) {
                printf("Successfully added %s approval status for %s\n", argv[2], argv[3]);
                // Add Accessibility as a prerequisite if needed
                _TCCAccessSetForBundle(CFSTR("kTCCServiceAccessibility"), bundle);
            } else {
                fprintf(stderr, "Could not add %s approval status for %s\n", argv[2], argv[3]);
            }
        } else if(strcmp(argv[1], "reset") == 0) {
            if(_TCCAccessResetForBundle(service, bundle) == 0) {
                printf("Successfully reset %s approval status for %s\n", argv[2], argv[3]);
            } else {
                fprintf(stderr, "Could not reset %s approval status for %s\n", argv[2], argv[3]);
            }
        }
        
        // Resource cleanup
        CFRelease(service);
        CFRelease(bundle);
        dlclose(tccHandle);
    }
    return 0;
}

