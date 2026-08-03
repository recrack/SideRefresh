# Prepare an Apple Personal Team

[English](PERSONAL-TEAM-SETUP.md) | [한국어](PERSONAL-TEAM-SETUP.ko.md)

SideRefresh needs the 10-character Team ID that Xcode uses to build and sign
your iOS app. Paid Apple Developer Program membership is not required for an
app used on your own iPhone, but an Apple Account and Xcode Personal Team are
required.

## Add the Apple Account in Xcode

1. Open **Xcode → Settings → Accounts**.
2. Use the `+` button to add your Apple Account.
3. Complete sign-in, two-factor authentication, and any agreement directly in
   Xcode.
4. Open the iOS project or workspace.
5. Select the actual iOS application target.
6. Under **Signing & Capabilities**, enable **Automatically manage signing**.
7. Select `Your Name (Personal Team)` under **Team**.

SideRefresh never asks for the Apple Account password or two-factor code and
does not automate this account flow.

## Create the first development signing assets

1. Use a unique Bundle ID.
2. Apply the same Team to related app extensions or widgets when present.
3. Connect and unlock the iPhone.
4. Approve trust and Developer Mode on the iPhone.
5. Choose that iPhone as the Xcode run destination.
6. Run **Product → Run** once.

With automatic signing enabled, Xcode prepares the development certificate,
device registration, App ID, and provisioning profile it needs.

## Find the Team in SideRefresh

In SideRefresh Settings, select the app and use **Find Personal Team**.
SideRefresh checks read-only local evidence in this order:

1. `DEVELOPMENT_TEAM` for the selected Xcode application target;
2. valid local Personal Team provisioning profiles;
3. expired local Personal Team profile records; and
4. Team ID candidates in Apple Development certificates in the Keychain.

A certificate contains a Team ID but does not prove that Xcode labels that team
as a Personal Team. Certificate-only evidence therefore requires confirmation
in Xcode. If several Team IDs exist, SideRefresh asks you to choose instead of
guessing the first one.

The discovery action reads local Xcode settings, provisioning profiles, and
Apple Development certificate metadata. It does not alter the Apple Account,
Keychain, certificates, or project settings.

## Fix “No Accounts” or “No profiles”

If `xcodebuild` reports **No Accounts** or cannot find a development profile:

1. Open the selected project in Xcode.
2. Confirm the Apple Account under **Xcode → Settings → Accounts**.
3. Select the correct application target and open **Signing & Capabilities**.
4. Enable automatic signing and select the Personal Team.
5. Confirm that the Bundle ID is unique and all related targets use the
   intended Team.
6. Unlock and pair the intended iPhone, then run the app from Xcode once.
7. Return to SideRefresh, find the Personal Team again, save, and retry.

Changing only the Team ID in SideRefresh cannot create a missing Xcode account
or provisioning profile.

## Personal Team limits

- Development provisioning expires and the app must be rebuilt and installed
  again to remain usable.
- Apple applies free-account limits to registered App IDs, devices, and apps.
- App Store submission and general distribution require paid program
  membership.

SideRefresh schedules Apple's normal development-signing path; it does not
bypass these limits.

## Apple references

- [About your developer account](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Assign a team to a project](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html)
- [Run an app on a physical device](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)
- [Add capabilities and prepare signing](https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app)
- [Inside a provisioning profile](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
