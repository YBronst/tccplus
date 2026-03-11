#!/bin/bash
ACTIONS=("add reset")
ALLOWEDSERVICES=("All Accessibility AddressBook AppleEvents AudioCapture BluetoothAlways BluetoothPeripheral BluetoothWhileInUse Calendar Calls Camera ContactlessAccess ContactsFull ContactsLimited DeveloperTool ExposureNotification FaceID FileProviderDomain FileProviderPresence FinancialData FocusStatus GameCenterFriends KeyboardNetwork ListenEvent Liverpool Location MediaLibrary Microphone Motion MSO NearbyInteraction Pasteboard Photos PhotosAdd PostEvent Reminders RemoteDesktop ScreenCapture SecureElementAccess SensorKitAmbientLightSensor SensorKitBedSensing SensorKitDeviceUsage SensorKitElevation SensorKitFacialMetrics SensorKitForegroundAppCategory SensorKitHistoricalCardioMetrics SensorKitHistoricalMobilityMetrics SensorKitKeyboardMetrics SensorKitLocationMetrics SensorKitMessageUsage SensorKitMotion SensorKitOdometer SensorKitPedometer SensorKitPhoneUsage SensorKitSoundDetection SensorKitSpeechMetrics SensorKitStrideCalibration SensorKitWatchAmbientLightSensor SensorKitWatchFallStats SensorKitWatchForegroundAppCategory SensorKitWatchHeartRate SensorKitWatchMotion SensorKitWatchOnWristState SensorKitWatchPedometer SensorKitWatchSpeechMetrics SensorKitWristTemperature ShareKit Siri SpeechRecognition SystemPolicyAllFiles SystemPolicyAppBundles SystemPolicyAppData SystemPolicyDesktopFolder SystemPolicyDeveloperFiles SystemPolicyDocumentsFolder SystemPolicyDownloadsFolder SystemPolicyNetworkVolumes SystemPolicyRemovableVolumes SystemPolicySysAdminFiles Ubiquity UserAvailability UserTracking VirtualMachineNetworking VoiceBanking WebBrowserPublicKeyCredential WebKitIntelligentTrackingPrevention Willow")

PLISTFILE=$1/Contents/Info.plist

if [ ! -f $PLISTFILE ]; then
    echo 'Application PList $PLISTFILE not found'
    exit 1
fi
if [[ ! " ${ACTIONS[@]} " =~ " $2 " ]]; then
    echo "Action ($2) not allowed"
    exit 2
fi
BUNDLE=`awk '/CFBundleIdentifier/{getline; print}' $PLISTFILE  | awk -F '[<>]' '/string/{print $3}'`


IFS=',' read -ra SERVICES <<< "$3"

echo "RUN THE FOLLOWING:"
for SERVICE in "${SERVICES[@]}"
do
    if [[ ! " ${ALLOWEDSERVICES[@]} " =~ " $SERVICE " ]]; then
       #echo "Service ($SERVICE) not allowed, skipping"
       continue
    fi
    echo tccplus $2 $SERVICE $BUNDLE
done
