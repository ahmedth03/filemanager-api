# HarfiDar — Android Release Checklist

## 1. Pre-build Configuration
- [ ] `lib/core/constants/api_constants.dart` — `BASE_URL` set to `https://api.harfidar.dz/api/v1`
- [ ] `android/app/build.gradle` — `versionCode` incremented, `versionName` updated (e.g., `1.0.0`)
- [ ] `android/app/build.gradle` — `applicationId` = `dz.harfidar.app`
- [ ] `android/app/build.gradle` — `minSdkVersion` ≥ 21 (Android 5.0)
- [ ] `android/app/build.gradle` — `targetSdkVersion` = 34 (latest)
- [ ] `android/app/build.gradle` — `compileSdkVersion` = 34
- [ ] ProGuard/R8 rules configured for Retrofit, Gson, Firebase

## 2. Signing
- [ ] Production keystore created: `keytool -genkey -v -keystore harfidar-release.jks`
- [ ] Keystore stored securely (NOT in git)
- [ ] `android/key.properties` created with keystore path and credentials
- [ ] `build.gradle` `signingConfigs.release` configured
- [ ] Build with: `flutter build appbundle --release`
- [ ] Verify signature: `apksigner verify --print-certs build/app/outputs/bundle/release/app-release.aab`

## 3. Firebase Setup
- [ ] `google-services.json` downloaded from Firebase Console for production app
- [ ] `google-services.json` placed in `android/app/`
- [ ] FCM token registration tested on physical device
- [ ] Background notification handling verified

## 4. Permissions (AndroidManifest.xml)
- [ ] `INTERNET` — required
- [ ] `ACCESS_NETWORK_STATE` — for connectivity detection
- [ ] `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` — for image picker (API 33+)
- [ ] `CAMERA` — for profile/portfolio photo capture
- [ ] `POST_NOTIFICATIONS` — for FCM push notifications (API 33+)
- [ ] `VIBRATE` — for notification vibration
- [ ] No unused dangerous permissions declared

## 5. App Icon & Branding
- [ ] App icon set in all densities (mdpi → xxxhdpi) using `flutter_launcher_icons`
- [ ] Adaptive icon configured for Android 8.0+ (foreground + background layers)
- [ ] App name in Arabic: `حرفيدار` (or localised)
- [ ] Splash screen configured

## 6. Google Play Store
- [ ] Google Play developer account active ($25 one-time fee)
- [ ] App created in Play Console
- [ ] Short description (≤80 chars) in Arabic and French
- [ ] Full description (≤4000 chars)
- [ ] Screenshots: phone (min 2, max 8), 7-inch tablet (optional)
- [ ] Feature graphic: 1024×500 px
- [ ] Content rating questionnaire completed (expected: Everyone/Teen)
- [ ] Target audience: Algeria, Morocco, Tunisia (select countries)
- [ ] Privacy policy URL published and linked
- [ ] Data safety form completed:
  - [ ] Data collected: name, email, phone, location (city), messages
  - [ ] Data shared: none with third parties
  - [ ] Data encrypted in transit: yes
  - [ ] Data can be deleted: yes (account deletion flow)
- [ ] App signing by Google Play: enrolled

## 7. Release Track
- [ ] Internal testing track: share with QA team
- [ ] Closed testing (alpha): 10-20 beta users in Algeria
- [ ] Open testing (beta): 100 users
- [ ] Production release: staged rollout 20% → 50% → 100%

## 8. Performance
- [ ] App start time < 3 seconds on mid-range device (Redmi Note 10)
- [ ] Listing images lazy-loaded with shimmer placeholder
- [ ] APK/AAB size < 50 MB (check: `flutter build apk --analyze-size`)
- [ ] Memory usage < 200 MB during normal usage
- [ ] No ANR (Application Not Responding) events in 24h testing
- [ ] Crash-free rate > 99.5% in internal testing

## 9. Offline Behavior
- [ ] App shows meaningful error when offline (not crash)
- [ ] Cached listings visible when offline (SharedPreferences or Hive)
- [ ] Authentication tokens survive app restart

## 10. Final Verification
- [ ] Test on Android 8, 10, 12, 14 (physical or emulator)
- [ ] Test on small screen (5 inch) and large screen (6.5 inch)
- [ ] RTL layout verified for Arabic text
- [ ] Dark mode tested (if supported)
- [ ] Uninstall and reinstall: no stale session/token bugs
- [ ] Build submitted to Play Console: `flutter build appbundle --release`
