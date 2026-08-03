# Personal iOS Remote Renewal

This workspace investigates reliable personal installation and renewal of a native iOS app without paid Apple Developer Program membership.

## Language

**Pure cellular mode**:
The iPhone has no active Wi-Fi association; Wi-Fi may be disabled or its radio may be on without joining an SSID. This is stricter than merely using a different Wi-Fi network from the Mac.
_Avoid_: remote mode, no-local-Wi-Fi

**Remote renewal**:
Rebuilding, re-signing, and installing the same personal iOS app before its Personal Team provisioning profile expires, without physical access to the iPhone.
_Avoid_: profile extension, profile reinstall

**Hands-free renewal**:
Remote renewal that requires no user action after initial setup, including after normal weekly expiry and after an iPhone reboot.
_Avoid_: semi-automatic renewal, assisted renewal

**CoreDevice/Tailnet bridge**:
An experimental Mac-side Bonjour proxy and transport relay that makes a Tailscale-reachable iPhone appear locally discoverable to Apple CoreDevice tooling.
_Avoid_: AltStore bridge, Tailscale sideloading

**Direct-IP device connection**:
Xcode's connection path for a previously paired network device when Bonjour discovery is unavailable; it takes the device's IP address rather than a Bonjour-discovered name.
_Avoid_: Tailscale bridge, remote pairing

**Tailnet device discovery**:
A read-only setup diagnostic that finds or accepts the target iPhone's Tailscale address, then verifies its reachability for a direct-IP connection. It never logs in, enables VPN, changes ACLs, or alters device settings.
_Avoid_: automatic Tailscale setup, VPN activation

**Simple workspace**:
SideRefresh's primary user experience: one surface for renewal status, the selected app-to-iPhone target, and the next required action, with infrequent configuration and diagnostics disclosed on demand.
_Avoid_: simple mode, beginner mode, separate simple app

**Legacy workspace**:
The existing four-section user experience retained temporarily while the Simple workspace reaches functional parity. It is available only as a Help-menu fallback for the current session; every app launch returns to the Simple workspace. It is not a separate product or permanent user mode.
_Avoid_: classic app, advanced app, separate legacy app

**Agent app maker**:
A person who uses a coding agent to create a native iOS app for personal use and installs it through Xcode Personal Team rather than distributing it through the App Store.
_Avoid_: traditional iOS developer, no-code user, IPA consumer

**Agent-made personal app**:
A native iOS app created or substantially maintained by a coding agent for its owner's private use under Xcode Personal Team signing.
_Avoid_: AI app, sideloaded third-party app, App Store app

**Project handoff**:
A local, non-authoritative suggestion from a coding agent containing one absolute `.xcodeproj` or `.xcworkspace` path. SideRefresh re-inspects the Xcode container and requires user review before changing a renewal target; the handoff never selects an iPhone, enables automation, or installs an app.
_Avoid_: automatic project detection, remote configuration, agent-approved setup

**Setup flow**:
A temporary, task-focused sequence that establishes or replaces the selected app-to-iPhone renewal target, verifies its prerequisites, and separately asks for the first installation and automatic-renewal activation. It does not remain as primary navigation after setup succeeds.
_Avoid_: onboarding mode, setup workspace, persistent setup checklist

**Advanced settings**:
An on-demand destination for exact, editable build, signing, project-access, device, experimental-connection, and compatibility configuration. It is nested from Settings and is not a separate product mode.
_Avoid_: developer mode, advanced workspace, expert mode

**Diagnostics**:
An on-demand recovery and contribution surface containing a plain-language problem explanation, read-only evidence provenance, renewal phases, and bounded raw logs. It remains reachable without defining a second renewal status.
_Avoid_: log screen, developer console, diagnostic mode

**Renewal condition**:
The highest-urgency fact about the selected app's current installation and Personal Team signing lifecycle, shown independently from the steps required to resolve it.
_Avoid_: button state, current screen, last message

**Next action**:
The single user operation currently available that removes the nearest prerequisite between the Renewal condition and a healthy automatic-renewal state.
_Avoid_: primary CTA, action list, generic retry

**Renewal presentation**:
A read-only, deterministic projection of renewal data into the Renewal condition, Next action, selected app-to-iPhone relationship, Last verified evidence, current progress, and recent result. Every workspace and menu-bar surface reads the same projection.
_Avoid_: screen state, view-local flags, dashboard model

**Setup check**:
A one-shot, non-installing validation of the selected app-to-iPhone target. It does not persist a test mode, enable automatic renewal, or prove that an install succeeded.
_Avoid_: dry-run mode, test mode, safe mode

**Healthy renewal**:
A Renewal condition in which the active target is saved, a successful installation and its signing expiration are verified, background renewal is approved and enabled, the next renewal time is known, and no failure remains unresolved.
_Avoid_: app is installed, manual renewal is available, probably healthy

**Verified renewal**:
A renewal result for which the app installation succeeded and SideRefresh recorded enough Personal Team signing evidence, including the expiration, to calculate the next safe renewal. An installation without that evidence is not a Verified renewal.
_Avoid_: process exited successfully, install command completed, assumed renewal

**Last verified evidence**:
The most recent successful installation and signing facts that remain displayable while SideRefresh checks the current condition or cannot reach the iPhone. Their verification time must remain visible, and they do not imply current connectivity.
_Avoid_: cached current status, live device state, assumed connection
