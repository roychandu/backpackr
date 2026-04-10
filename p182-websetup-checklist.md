********IMP***********
To check aws domain working or not
https://www.whatsmydns.net/#CNAME/little.allureorbit-app.info
************************
In Swift apps
Jatin will add webview
Share webview details with him everytime and
You can just cross verify
Details in code
Check in firebase and you can run in your system or
He can show you in huddle
What ever fits
Mandatory checks should be done by chanchal like
App icon, app name, infoplist, permissions, webview etc
********IMP***********


check list:
step 1: add riverpod set up folder and wrap with material widget in main.dart - done
step 2 : add google service json file - done
step 3: add all updated firebase and shareplus packages - done
step 4 : add in app id -com.thuythiquach.children - done
step 5 : add domain name - done
step 6: add Terms / webview  as wurl - done
step 7: add project name in material main.dart - done
step 8: add project name in info.plist file - done
step 9: add required permissions in info.plist and remove unused permissions - done
step 10: add ic_launcher package - done
step 11: check app icon is updated or not if not updated add new and create new -done
step 12: check portrait - done
step 14 : in app check - done
step 15 : add firebase rules in this app - done
step 16 : check is premium true then how to look ui  -done
step 17: check web view ui  -done
step 18: check in app code for 2 buttons upgrade premium and restore purchase 
        1. profile screen restore purchase -done
        2. purchase page -
             a. purchase button, -done
             b. restore purchase button- code -done
step 19: check unused packages in pubspec.yamal file -done
step 20: sign in with apple checking- done
step 21: in firebase token value add false after checking webview - done
step 22: add firebase rules properly with child.  - done
         eg: {
                "rules": {
                ".write": false,
                ".read": true,
                
                     "$child": {
                      ".read": true,
                      ".write": "auth != null"
                    },
             }
step 23: google service infoplist for ios with production bundle id
step 24:try with different webview versions
step 25:firebase packages should be as given in canvas NOT updated
step 26:setPortrait at 2 places
step 27:go through pubspec.yaml once for plus package version, unsued package, audio related packages ( flutter_tts - modification in podfile required )
step 28:If in app purchase is used then use GetMaterialApp as Get.dialog is used for purchase
step 29: info.plist add compalsary
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
</dict>

***************************
cursor prompt for update new features:
i want to add this app of update for appstore 1.0.2 so please add little bit feature
in this app and give me 10 lines desctription related that added feature. please dont 
change in main.dart and please check in side app of main feature and add some little bit
feature dont changes in edit profile like that check main features of this app dont changes in 
common features. dont add more features add only 1 feature and give me 6 lines description. 
due to addded more feature dont rejct my app
**************************
Describe Permission description if used

Camera
Gallery
Location
audio



ios": {
"supportsTablet": true,
"bundleIdentifier": "com.zapp.testbuild",
"appleTeamId": "ZMS6G7P2U9",
"infoPlist": {
*****************************

Describe Permission description if used in details
Camera
Gallery
Location
Microphone
Audio
***************
P182
6755545951:
18215e510e9ff7352360b0a6f17f35056d780f876f8c34e48273e76bd30af259
token enabled
{
"globeSection": {
"18215e510e9ff7352360b0a6f17f35056d780f876f8c34e48273e76bd30af259": {
    "globeValue": true
}
}
}
***************
p182
in app id : com.birtansokullu.preglob
**************
Santosh851 - #P182
Main page - https://yuvonglobe-app.info/
Privacy Policy - https://yuvonglobe-app.info/privacy_policy/
Terms / webview - https://yuvonglobe-app.info/terms_of_use/
Contact - https://yuvonglobe-app.info/contact_us.html
*********************
AppNumber: p182
test user
email: user@rest.yuvonglobe-app.info
password : 123456

🟢 TYPE A
Domain: rest.yuvonglobe-app.info
Value: 54.166.230.233
Proxy Status - 🔸 Proxied

Requested By: chanchal
************
#P182 (en us)
App Name:
Yuvon Globe
Company Name:
dsfgh45oliviamill@icloud.com
Birtan SOKULLU (Individual)
Team ID:
AYZVD6A5GX
Bundle ID:
com.birtansokullu.yuvonglobe
App ID:
6755545951
Dev key:
e7JEo5cRmitmpkWeufXHuH
Key ID:
6FL3K854ZC
Issuer ID:
22856d2c-88fa-4964-90bb-ea7a2f074dff
Flutter installed.
*******************

changes in post: in rever functiona
curl -X POST "https://apiend.steviochart-app.info/" \
-H "Accept: */*" \
-H "x-app-id: 6753713863"


final response = await http.post(
Uri.parse(Tripsids.trBaseUrl),
headers: {
'Accept': '*/*',
'x-app-id': "6754171560",
},
);
***************REFERENCE CODE***********

***********RUN COmmand*************
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/Flutter/Flutter.framework ios/Flutter/App.framework ios/Flutter/ephemeral pubspec.lock
flutter clean
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
*******************
For Web section
Real Time Database -Add Token
{
"reviveSection": {
"3ab38f4dbfca493ec6b9ee4961cb31f54cfd0723bb8e5bf76290e4d5d4f582a2": {
"reviveValue": true
}
}
}
    

3. Pubpec.yamal

icons_launcher:
image_path: "assets/icon.png"
platforms:
android:
enable: false
ios:
enable: true



dev_dependencies:


icons_launcher: ^3.0.3


4. Checking version
# Firebase packages
firebase_auth: ^5.1.0
firebase_core: ^3.15.2
firebase_database: ^11.3.10
firebase_messaging: ^15.2.10
firebase_app_check: ^0.3.2+10
firebase_analytics: ^11.6.0
check share_plus: lates version
webview_flutter: ^4.10.0

dependency_overrides:
webview_flutter_wkwebview: 3.17.0

Add River setup Param folder -Any - from document file
Pubspec.yamal
provider: ^6.1.2
riverpod: ^2.5.1
flutter_riverpod: ^2.5.1

5. Run command ->
   flutter pub get && dart run icons_launcher:create


6. upgrade prmium

Ontap: purchase premium
setState(() => isLoading = true);
if (purchaseProvider
.products.isNotEmpty) {
await purchaseProvider.buyProduct(
purchaseProvider.products[0]);
}
setState(() => isLoading = false);


Ontap: restore purchase
setState(() => isLoading = true);
await purchaseProvider.restoreItem();
setState(() => isLoading = false);

Production inapp purchse key
/// test ids
/// production ids
const nonConsumableId = kDebugMode
? "com.test.bet"
: "com.quangkhaitran.invoices";   ///TODO chekcing change
const trophiesId = kDebugMode ? "com.zapp.testbuild.10006" : ""; ///TODO chekcing change

Add Rules in real time database

"$child": {
".read": true,
".write": "auth != null"
},




//////////Fastlaner///// json
{
"app_store_connect": {
"key_id": "TU4GH4455U",
"issuer_id": "2a5c979b-e2b6-44bf-abb0-03137166ab56",
"key_filepath": "AuthKey_TU4GH4455U.p8"
},
"metadata": {
"app_id": "6753713863", ///done
"package_id": "com.longvanhoang.curnexrevive", /// bundle id
"email": "khanhngocp34@gmail.com",
"name": "Curnex Revive", /// app name
"release_notes": "",
"support_url": "https://curnexrevive-app.info/contact-us.html", /// contact url
"privacy_url": "https://curnexrevive-app.info/privacy-policy/", /// privacty
"primary_category": "REFERENCE",
"changelog": "",
"update_version": "",
"marketing_url": "",
"copyright": "",
"keywords": ""    
},
"default_language": "en-US",
"localizations": [
"en-US"
],
"specific_name_locales": {},
"inapp": {
"iap_metadata": [
{
"product_id": "com.longvanhoang.revive",/// in app id
"reference_name": "Advance garage", /// add premium feature key
"purchase_type": "NON_CONSUMABLE",
"family_sharable": false,
"review_notes": "",
"pricing": {
"territory": "USA",
"price_point": "0.99"
},
"localizations": [
{
"locale": "en-US",
"name": "Advance garage",/// "reference_name": "Advance garage", /// add premium feature key
"description": "Add unlimited vehicles" /// add desc anything related premium feature
}
]
}
],
"availability": {
"available_in_all_territories": true,
"territories": []
},
"iap_territory_id": "USA",
"review_image_path": "./img.png"
}
}
**************
update version 1.0.1
P147 - w54zsDkpBLCUk4BwHkQZeH - done
P210 - H9QmmEshDjbriabupj27aU - done
P184 - B42SR8GdqRUzby5oYNvSEb - done


p197 - vHC9wxvRuhrCCfYeLihBPh - jatin
p138 - XosxqHriVAazvXKvwJc7P5 - Santosh
p195 - 5bJHRNbd4BREB2tLhVNDAT - jaimin  -done
p172 - YgiiwysY7bFL3qnvePYw43 - gurjeet
#p121 - qRo4eSTnZZMGNDUeTz72Wf - done
Appsflyer