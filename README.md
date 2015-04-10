# Pegasus
A sample app illustrating the core features of [VIMNetworking](https://github.com/vimeo/VIMNetworking), the Vimeo iOS SDK. 

## Setup

In order to build and run Pegasus, replace the placeholder values at the top of `AppDelegate.h`:

```Objective-c
#import "AppDelegate.h"

...

static NSString *ClientKey = @"YOUR_CLIENT_KEY";
static NSString *ClientSecret = @"YOUR_CLIENT_SECRET";
static NSString *Scope = @"private public create edit delete interact upload";

static NSString *BackgroundSessionIdentifierApp = @"YOUR_APP_BG_SESSION_ID";
static NSString *BackgroundSessionIdentifierExtension = @"YOUR_EXTENSION_BG_SESSION_ID"; // Must be different from BackgroundSessionIdentifierApp
static NSString *SharedContainerID = @"YOUR_SHARED_CONTAINER_ID";

static NSString *KeychainAccessGroup = @"YOUR_KEYCHAIN_ACCESS_GROUP";
static NSString *KeychainService = @"YOUR_KEYCHAIN_SERVICE";
```

Obtain a client key and secret [here](https://developer.vimeo.com/apps)

Read about shared containers [here](https://developer.apple.com/library/prerelease/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)

Read about Keychain access groups and services [here](https://developer.apple.com/library/ios/documentation/Security/Reference/keychainservices/)

For additional help building and running Pegasus see Apple's [iOS Developer Library](https://developer.apple.com/library/ios/navigation/)

## License

Pegasus is available under the MIT license. See the LICENSE file for more info.

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-api) with the tag `vimeo-api`

Get in touch [here](Vimeo.com/help/contact)
