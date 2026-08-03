# Developer ID Application certificate setup

> Researched: 2026-08-02
>
> Scope: SideRefresh distribution outside the Mac App Store

## Conclusion

SideRefresh needs a **Developer ID Application** certificate to sign the Mac
app and its embedded executables. It does not currently need a **Developer ID
Installer** certificate because the planned release artifact is a ZIP
containing `SideRefresh.app`, not a signed installer package.

The certificate can be created through Xcode or through the Apple Developer
website with a certificate signing request (CSR). Xcode is the shortest path
on one release Mac. The manual CSR path is useful when the private-key
location and backup need to be controlled explicitly.

Certificate installation and notarization authentication are separate:

- the Developer ID identity in Keychain signs the app locally; and
- `notarytool` uses separately stored Apple notarization credentials to submit
  the signed archive.

Apple describes Developer ID plus notarization as the distribution path for
Mac software downloaded outside the Mac App Store.
[Apple: Developer ID](https://developer.apple.com/support/developer-id/)

## Current SideRefresh state

The release Mac had **zero** valid `Developer ID Application` identities when
checked on 2026-08-02:

```sh
security find-identity -v -p codesigning
```

`Scripts/build-app.sh` already accepts a real identity through
`SIDEREFRESH_SIGNING_IDENTITY`. With a non-ad-hoc identity it enables hardened
runtime and a secure timestamp and signs the embedded Agent and iOS renewal
helper before signing the outer app.

No SideRefresh entitlement file or advanced Developer ID capability was found
in the current app bundle. A Developer ID provisioning profile therefore is
not part of this certificate-installation task. Apple requires such a profile
only when a directly distributed app uses advanced capabilities such as
CloudKit.
[Apple: Developer ID preparation](https://developer.apple.com/support/developer-id/)

## Prerequisites

1. The distributor must have an active Apple Developer Program or Apple
   Developer Enterprise Program membership. A free Xcode Personal Team cannot
   issue Developer ID certificates.
2. A locally managed Developer ID certificate requires the **Account Holder**
   role. An individual enrollee is the Account Holder of their one-person
   team.
3. Select the paid program team, not the Personal Team, when multiple teams
   appear in Xcode.

Cloud-managed Developer ID certificates are a different path: Apple manages
them remotely for the Xcode Organizer distribution workflow. SideRefresh's
shell build needs a conventional identity and private key available to the
local Keychain, so a cloud-managed certificate is not a substitute for this
setup.
[Apple: cloud-managed certificates](https://developer.apple.com/help/account/certificates/cloud-managed-certificates/)

Apple currently permits up to five Developer ID Application certificates and
five Developer ID Installer certificates per team. Avoid creating replacements
just to troubleshoot a missing local private key.
[Apple: create Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/)
[Apple: program roles](https://developer.apple.com/help/account/access/roles)

## Recommended path: create it with Xcode

The exact labels can move between Xcode releases, but Apple's current workflow
is:

1. Open **Xcode → Settings → Accounts**.
2. Add or select the Apple Account that owns the paid developer membership.
3. Select the paid team.
4. Open **Manage Certificates**.
5. Press **+** and choose **Developer ID Application**.
6. Wait for Xcode to create the private key, request the certificate, and add
   the resulting identity to the login keychain.

Xcode can also create the identity while exporting a normal Xcode archive via
**Distribute App → Developer ID → Upload → Automatically manage signing**.
SideRefresh itself is assembled by `Scripts/build-app.sh`, so the Accounts
screen is the more direct Xcode route for this repository.
[Apple Xcode Help: upload a Mac app for notarization](https://help.apple.com/xcode/mac/current/en.lproj/dev88332a81e.html)
[Apple: synchronize signing identities](https://developer.apple.com/documentation/xcode/sharing-your-teams-signing-certificates)

Continue with **Verify the installed identity** below. Do not create a second
certificate if the first one already appears with its private key.

## Manual alternative: Apple Developer website and CSR

Use this path if Xcode cannot create the certificate or explicit CSR ownership
is preferred.

### 1. Create the CSR and private key

On the Mac that will sign SideRefresh:

1. Open **Keychain Access**.
2. Choose **Keychain Access → Certificate Assistant → Request a Certificate
   from a Certificate Authority**.
3. Enter the Apple Account email address.
4. Enter a descriptive Common Name for the release key.
5. Leave the CA Email Address empty.
6. Choose **Saved to disk**, then save the `.certSigningRequest` file.

Creating this CSR also creates the associated private key in that Mac's
keychain. Keep using the same login account and keychain for the download and
installation steps.
[Apple: create a certificate signing request](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request)

### 2. Issue the certificate

1. Sign in to
   [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list).
2. Open **Certificates** and press **+**.
3. Under **Software**, select **Developer ID** and continue.
4. Select **Developer ID Application**. Do not select Developer ID Installer
   for the SideRefresh ZIP release.
5. Upload the `.certSigningRequest` file.
6. Download the generated `.cer` file.

[Apple: create Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/)

### 3. Install and pair it

Double-click the downloaded `.cer`. It should be added to the login keychain
and appear under **Keychain Access → My Certificates**.

Expand the certificate row. A private key must appear underneath it. The
`.cer` contains the issued certificate but is not a replacement for the
private key created with the CSR. Installing the `.cer` on an unrelated Mac
without importing that private key produces a certificate that cannot sign.
Apple notes that signing private keys exist only in the local keychain and a
missing private key cannot be repaired by downloading profiles again.
[Apple Xcode Help: export signing assets](https://help.apple.com/xcode/mac/current/en.lproj/dev8a2822e0b.html)

## Verify the installed identity

Run:

```sh
security find-identity -v -p codesigning
```

Expected result: one valid identity whose label has this shape:

```text
Developer ID Application: DISTRIBUTOR NAME (TEAMID)
```

If Keychain shows the certificate but this command shows no valid identity,
the usual boundary is the missing or inaccessible private key. Import the
original encrypted backup from the Mac that created the key rather than
copying the `.cer` alone.

Do not paste the real distributor name, Team ID, certificate fingerprint, or
private-key material into issues, Actions logs, or repository files.

## Back up the signing identity immediately

The recovery asset must include the certificate **and its private key**.

In Keychain Access:

1. Open **My Certificates** and select the Developer ID Application identity.
2. Confirm that the private key is nested below it.
3. Choose **File → Export Items**.
4. Export an encrypted Personal Information Exchange (`.p12`) file.
5. Protect it with a strong, unique password and store the file and password
   separately in approved secure storage.

To move the identity to another Mac, use **File → Import Items** and import the
`.p12`. Use this explicit identity backup rather than relying on an
Xcode-version-specific account export UI.
[Apple: import and export Keychain items](https://support.apple.com/en-ca/guide/keychain-access/kyca35961/mac)
[Apple Xcode Help: export signing assets](https://help.apple.com/xcode/mac/current/en.lproj/dev8a2822e0b.html)

Never commit `.p12`, `.developerprofile`, CSR, certificate, notarization
password, or App Store Connect API key files. Apple treats signing assets and
account credentials as sensitive identity material.
[Apple: certificates overview](https://developer.apple.com/help/account/certificates/certificates-overview/)

## Use the identity with SideRefresh

After the identity is installed, copy its exact Keychain label into the
existing build command:

```sh
SIDEREFRESH_SIGNING_IDENTITY='Developer ID Application: DISTRIBUTOR NAME (TEAMID)' \
  Scripts/build-app.sh
```

Then inspect and verify the nested and outer signatures:

```sh
codesign --display --verbose=4 dist/SideRefresh.app
codesign --verify --deep --strict --verbose=2 dist/SideRefresh.app
```

A valid local signature is necessary but does not mean the app is notarized.
Apple's notary service also checks that distributed executables use a valid
Developer ID signature, hardened runtime, and secure timestamp.
[Apple: prepare software for notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

Do not use `spctl` as the certificate-installation test. Gatekeeper assessment
belongs after notarization and ticket stapling; before that point it can reject
an otherwise valid Developer ID signature as unnotarized.

## Configure notarization separately

After certificate verification, create a Keychain profile for `notarytool`.
Omitting `--password` gives a secure interactive prompt with the installed
Xcode command-line tool, avoiding a secret in shell history:

```sh
xcrun notarytool store-credentials 'SideRefresh-notary' \
  --apple-id 'APPLE_ACCOUNT_EMAIL' \
  --team-id 'TEAMID'
```

Use an app-specific password at the prompt. Later submissions reference only
the Keychain profile name:

```sh
xcrun notarytool submit dist/SideRefresh.zip \
  --keychain-profile 'SideRefresh-notary' \
  --wait
```

The final release still needs ticket stapling, signature verification,
Gatekeeper assessment, checksum publication, and a clean-account download test.
[Apple: customize the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

## Expiration, replacement, and compromise

- Developer ID certificates are valid for five years.
- Apps signed while a certificate was valid can continue to install and run
  after that certificate expires, but a new certificate is required to sign
  updates.
- Revocation is different from expiration: software signed with a revoked
  Developer ID certificate can no longer be installed or launched.
- Apple directs Developer ID revocation requests to
  `product-security@apple.com`; do not revoke or replace a working identity as
  casual troubleshooting.

[Apple: Developer ID expiration](https://developer.apple.com/support/developer-id/)
[Apple: Developer ID revocation](https://developer.apple.com/help/account/reference/revoking-privileges/)

## SideRefresh completion check

- [ ] Active paid program team and Account Holder access confirmed.
- [ ] Exactly one intended Developer ID Application identity is valid locally.
- [ ] Keychain identity expands to show its private key.
- [ ] Encrypted off-machine backup and separate password storage confirmed.
- [ ] `Scripts/build-app.sh` succeeds with the real identity.
- [ ] Embedded executables and outer app pass strict signature verification.
- [ ] Notarization credentials are stored separately in Keychain.
- [ ] No signing or notarization secret is present in Git, logs, or shell
  scripts.
