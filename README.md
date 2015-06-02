# Pegasus
A sample app illustrating the core features of [VIMNetworking](https://github.com/vimeo/VIMNetworking), the Vimeo iOS SDK. 

## Setup

1. Clone the repo
    
    ```bash
    $ git clone git@github.com:vimeo/Pegasus.git
    $ cd Pegasus
    ```

2. Cocoapods

Install cocoapods if necessary. Then run `pod install` in the Pegasus root directory.

3. Obtain a client key and secret [here](https://developer.vimeo.com/apps), then replace the placeholder values at the top of `AppDelegate.h`

    ```Objective-c
    #import "AppDelegate.h"

    ...

    static NSString *ClientKey = @"YOUR_CLIENT_KEY";
    static NSString *ClientSecret = @"YOUR_CLIENT_SECRET";
    static NSString *Scope = @"private public create edit delete interact upload";
    ```

4. Update your URL Schemes in your `Info.plist` (for authentication). The url scheme is `vimeo` + `YOUR_CLIENT_ID`. Example if your client id is `1234`  
   ![info_plist_ _edited](https://cloud.githubusercontent.com/assets/1383979/7306074/bb421c72-e9d0-11e4-9d48-9dd27941fdcc.jpg)

5. Add the same URL to your [app credentials](https://developer.vimeo.com/apps)  
   ![edit_app_settings_for_ pegasus _on_vimeo_developer_api](https://cloud.githubusercontent.com/assets/1383979/7306122/f6460e82-e9d0-11e4-8a76-2026ed15ef25.jpg)

6. Set your [Background Session](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html) and [Keychan Services](https://developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/) credentials in your `AppDelegate.h`

    ```Objective-c
    #import "AppDelegate.h"

    ...

    static NSString *BackgroundSessionIdentifierApp = @"YOUR_APP_BG_SESSION_ID";
    static NSString *BackgroundSessionIdentifierExtension = @"YOUR_EXTENSION_BG_SESSION_ID"; // Must be different from BackgroundSessionIdentifierApp
    static NSString *SharedContainerID = @"YOUR_SHARED_CONTAINER_ID";

    static NSString *KeychainAccessGroup = @"YOUR_KEYCHAIN_ACCESS_GROUP";
    static NSString *KeychainService = @"YOUR_KEYCHAIN_SERVICE";
    ```


For additional help building and running Pegasus see Apple's [iOS Developer Library](https://developer.apple.com/library/ios/navigation/)

## License

Pegasus is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](Vimeo.com/help/contact)
