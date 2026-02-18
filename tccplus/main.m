//
//  main.m
//  tccplus
//
//  Created by j on 3/23/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <dlfcn.h>

// Указатели на приватные функции TCC
int (*_TCCAccessSetForBundle)(CFStringRef, CFBundleRef);
int (*_TCCAccessResetForBundle)(CFStringRef, CFBundleRef);

// Исправлено: добавлен void в аргументы для соответствия современным стандартам C
void print_help(void) {
    const char *services[] = {
        "All", "Accessibility", "AddressBook", "AppleEvents", "Calendar",
        "Camera", "ContactsFull", "ContactsLimited", "DeveloperTool",
        "Facebook", "LinkedIn", "ListenEvent", "Liverpool", "Location",
        "MediaLibrary", "Microphone", "Motion", "Photos", "PhotosAdd",
        "PostEvent", "Reminders", "ScreenCapture", "ShareKit", "SinaWeibo",
        "Siri", "SpeechRecognition", "SystemPolicyAllFiles",
        "SystemPolicyDesktopFolder", "SystemPolicyDeveloperFiles",
        "SystemPolicyDocumentsFolder", "SystemPolicyDownloadsFolder",
        "SystemPolicyNetworkVolumes", "SystemPolicyRemovableVolumes",
        "SystemPolicySysAdminFiles", "TencentWeibo", "Twitter",
        "Ubiquity", "Willow"
    };
    
    printf("Usage: tccplus [add/reset] SERVICE [BUNDLE_ID]\nServices:\n");
    size_t count = sizeof(services) / sizeof(services[0]);
    for (size_t i = 0; i < count; i++) {
        printf(" - %s\n", services[i]);
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Проверка аргументов
        if(argc < 4 || (strcmp(argv[1], "add") != 0 && strcmp(argv[1], "reset") != 0)) {
            print_help();
            return 0;
        }
        
        _TCCAccessSetForBundle = NULL;
        _TCCAccessResetForBundle = NULL;
        
        // Динамическая загрузка TCC framework
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
        
        // Получение URL приложения по Bundle ID
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
        
        // Формирование названия сервиса (например, kTCCServiceCamera)
        CFStringRef serviceName = CFStringCreateWithCString(kCFAllocatorDefault, argv[2], kCFStringEncodingUTF8);
        CFStringRef service = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("kTCCService%@"), serviceName);
        CFRelease(serviceName);
        
        if(strcmp(argv[1], "add") == 0) {
            if(_TCCAccessSetForBundle(service, bundle) == 0) {
                printf("Successfully added %s approval status for %s\n", argv[2], argv[3]);
                // Добавляем Accessibility как пререквизит, если нужно
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
        
        // Очистка ресурсов
        CFRelease(service);
        CFRelease(bundle);
        dlclose(tccHandle);
    }
    return 0;
}

