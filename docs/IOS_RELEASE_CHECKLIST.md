# HarfiDar — iOS Release Checklist

## 1. Pre-build Configuration
- [ ] `lib/core/constants/api_constants.dart` — `BASE_URL` = `https://api.harfidar.dz/api/v1`
- [ ] `ios/Runner/Info.plist` — `CFBundleVersion` incremented
- [ ] `ios/Runner/Info.plist` — `CFBundleShortVersionString` = `1.0.0`
- [ ] `ios/Runner/Info.plist` — `CFBundleName` = `حرفيدار`
- [ ] `pubspec.yaml` — `version: 1.0.0+1`
- [ ] Minimum iOS version: `ios/Podfile` — `platform :ios, '13.0'`

## 2. Apple Developer Account
- [ ] Apple Developer Program enrolled ($99/year)
- [ ] Bundle ID registered: `dz.harfidar.app`
- [ ] Production App ID created in Developer Portal
- [ ] Distribution certificate created (iOS Distribution)
- [ ] Production provisioning profile created and downloaded
- [ ] Profile installed in Xcode

## 3. Firebase & Push Notifications
- [ ] `GoogleService-Info.plist` downloaded for production bundle ID
- [ ] `GoogleService-Info.plist` added to Xcode project (not tracked in git)
- [ ] APN key or certificate uploaded to Firebase Console
- [ ] Push notification entitlement enabled in Xcode Capabilities
- [ ] Background modes enabled: `remote-notifications`

## 4. Info.plist — Usage Descriptions
- [ ] `NSCameraUsageDescription` — "لالتقاط صور للملف الشخصي والمحفظة"
- [ ] `NSPhotoLibraryUsageDescription` — "لاختيار صور من مكتبتك"
- [ ] `NSPhotoLibraryAddUsageDescription` — "لحفظ الصور"
- [ ] `NSLocationWhenInUseUsageDescription` (if map feature used) — "لعرض العقارات القريبة"
- [ ] `NSMicrophoneUsageDescription` (if voice messages) — or omit if not used

## 5. App Transport Security
- [ ] ATS enabled (default) — no `NSAllowsArbitraryLoads: true` in production
- [ ] All API calls over HTTPS (api.harfidar.dz)
- [ ] Cloudinary URLs served over HTTPS
- [ ] WebSocket via `wss://` in production

## 6. App Store Connect
- [ ] App created in App Store Connect
- [ ] App name: `HarfiDar - حرفيدار` (Latin + Arabic)
- [ ] Subtitle (≤30 chars): "العقار والحرفيين بالجزائر"
- [ ] Description (≤4000 chars) in Arabic
- [ ] Keywords (≤100 chars): `عقار,حرفي,إيجار,بيع,الجزائر,شقة,فيلا`
- [ ] Support URL: `https://harfidar.dz/support`
- [ ] Marketing URL: `https://harfidar.dz`
- [ ] Privacy policy URL: `https://harfidar.dz/privacy`

## 7. Screenshots
- [ ] 6.5-inch iPhone (1284×2778 px) — min 3 screenshots
- [ ] 5.5-inch iPhone (1242×2208 px) — min 3 screenshots
- [ ] 12.9-inch iPad Pro (2048×2732 px) — optional but recommended
- [ ] Screenshots show Arabic UI
- [ ] App preview video (optional, 15-30 seconds)

## 8. Age Rating
- [ ] Complete age rating questionnaire
- [ ] Expected: 4+ or 12+ (no violence, no adult content)
- [ ] User-generated content disclosure: YES (listings, reviews, chat)

## 9. Privacy Nutrition Label
- [ ] Data collected: contact info (name, email, phone), identifiers (user ID), usage data
- [ ] Data used for: app functionality, developer's advertising not applicable
- [ ] Data linked to user: yes (name, email, phone, messages)
- [ ] Data not sold to third parties

## 10. Build & Submit
```bash
# From Flutter project root:
flutter build ipa --release

# In Xcode:
# Product → Archive → Distribute App → App Store Connect → Upload
```

Or via Fastlane:
```bash
fastlane deliver --ipa "build/ios/ipa/harfidar.ipa"
```

- [ ] Build uploaded to App Store Connect
- [ ] All screenshots uploaded
- [ ] Build selected for review submission
- [ ] Notes to reviewer (Arabic): explain test account credentials if needed

## 11. App Review Tips
- [ ] Provide test account in reviewer notes: email + password for demo user
- [ ] Note that image upload requires Cloudinary (functional, not a bug)
- [ ] Note that some features require account registration (not a barrier — create account in-app)
- [ ] Typical review time: 1-3 business days

## 12. TestFlight
- [ ] Internal testers (up to 25) added for day-1 testing
- [ ] External beta group: Algerian testers
- [ ] Beta testing duration: min 1 week before production release

## 13. Launch Day
- [ ] Staged rollout: not available on iOS (App Store releases 100% immediately)
- [ ] Publish immediately or schedule for specific date/time
- [ ] Monitor crash reports via Xcode Organizer / Firebase Crashlytics
- [ ] Respond to Day 1 reviews within 24 hours
