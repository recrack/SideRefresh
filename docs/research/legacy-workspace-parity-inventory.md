# Legacy workspace parity inventory

This inventory answers which current behaviors must have an explicit owner before the Legacy workspace can be removed. It describes the current implementation, not a requirement to reproduce the four-section layout.

## Destination surfaces

| Surface | Responsibility |
| --- | --- |
| **Simple workspace** | Renewal condition, selected app-to-iPhone relationship, Last verified evidence, progress or recent result, and at most one Next action |
| **Setup flow** | First setup and target replacement: project, iOS app target, Personal Team, iPhone, Setup check, first installation, and automatic-renewal activation |
| **Settings** | Infrequent supported choices that remain part of the first public release |
| **Advanced diagnostics** | Exact identifiers, evidence provenance, project access, recovery tools, experimental connection controls, and raw logs |
| **Confirmation** | Explicit approval immediately before an install, active automation change, or background-registration change |
| **System handoff** | Work SideRefresh cannot safely perform: Xcode signing, Apple Account authentication, iPhone trust and Developer Mode, and macOS background or file permissions |
| **Renewal domain** | State resolution, validation, scheduling, execution safety, evidence recording, and failure classification behind a small interface shared by every UI surface |
| **Compatibility fallback** | Existing custom-command configurations during migration; not part of the Simple workspace product contract |

The deletion test is strict: deleting the Legacy workspace must not redistribute renewal rules across new SwiftUI views. Those rules remain in or move behind the Renewal domain interface.

## User-visible capability ownership

### Status, evidence, and execution

| Legacy capability | Current behavior | Owner before removal | Parity requirement |
| --- | --- | --- | --- |
| App-to-iPhone relationship | Shows Mac app → build/sign/install → exact iPhone | Simple workspace | Always visible; changing either endpoint enters Setup flow |
| Readiness summary | Combines saved configuration, background status, approval, dry run, and missing fields | Renewal domain + Simple workspace | Replace view-local branching with Renewal condition and Next action |
| Next renewal | Shows a scheduled time only when the configuration is current and automation is operational | Simple workspace | Distinguish next automatic renewal from a time that is merely eligible |
| Last successful renewal | Reads the command-scoped receipt; wording distinguishes install from generic command success | Simple workspace | Show as Last verified evidence with its verification time |
| Signing expiration | Uses the installed build's embedded profile receipt and schedules no later than 24 hours before expiry | Renewal domain + Simple workspace | Actual expiration outranks the configured interval |
| Dirty-target handling | Marks configuration dirty, invalidates profile-match presentation, and hides current-target schedule evidence | Renewal domain + Simple workspace | Keep prior evidence only when clearly labelled as belonging to the previous saved target |
| Setup check | Validates a generated dry-run command without building, signing, contacting the iPhone, installing, or recording success | Setup flow; secondary action after setup | Remain one-shot and non-installing, never a persisted Simple workspace mode |
| Immediate renewal | Requires saved, clean, complete execute configuration; shows target/build/version confirmation before running | Simple workspace + Confirmation | One explicit install confirmation; disabled while prerequisites or another run are active |
| Renewal progress | Shows preparing, connection, cleanup, build, app validation, profile reading, install, receipt, and completion | Simple workspace summary + Advanced diagnostics detail | Current phase owns the primary surface; no cancel action until the engine has a safe cancellation contract |
| Renewal result | Keeps succeeded or failed phase data and a log preview until cleared | Simple workspace recent result + Advanced diagnostics | Success becomes Healthy renewal; failure preserves phase and Last verified evidence |
| Menu-bar status | Shows target, readiness, renewal summary, automation summary, Setup check, immediate renewal, logs, and app open/quit | Compact Simple workspace companion | Preserve status and safe entry points without creating a second state resolver |

### Project and signing setup

| Legacy capability | Current behavior | Owner before removal | Parity requirement |
| --- | --- | --- | --- |
| Project discovery | Searches cached and user-authorized locations for `.xcodeproj` and `.xcworkspace` containers with real iOS application targets | Setup flow | Progressive results, cancel, cached results, and direct selection remain available |
| Protected-folder access | Tracks selection required, checking, allowed, partially blocked, blocked, and missing locations | Setup flow first use; Advanced diagnostics later | Never claim access after a cancelled or failed probe; provide macOS Settings recovery |
| Search privacy explanation | States that source files are not uploaded or modified and identifies metadata read | Setup flow | Retain concise disclosure before folder authorization |
| Explicit project confirmation | Selecting a row does not change the target until “Use selected app” | Setup flow | No silent adoption from scan or agent handoff |
| Workspace recommendation | Detects related project/workspace pairs and recommends the workspace | Setup flow | Preserve recommendation, especially for CocoaPods and generated workspaces |
| Target metadata fill | Fills scheme only when unambiguous and reads product, Bundle ID, Team, version, and icon metadata | Setup flow | Never guess between multiple applications or schemes; expose unresolved fields |
| Exact build fields | Allows scheme, product name, Bundle ID, and 10-character Team ID correction | Setup flow first use; Advanced settings later | Reviewable without placing raw fields on the Simple workspace |
| Personal Team discovery | Prioritizes selected Xcode target and active local profile; treats expired profiles and certificates as weaker evidence | Setup flow | Preserve evidence provenance and never auto-accept certificate-only or ambiguous candidates |
| Personal Team recovery guide | Hands Apple Account login, signing setup, trust, Developer Mode, and first Xcode run to Xcode/iPhone | System handoff | SideRefresh must not automate credentials, 2FA, agreements, certificate mutation, trust, or Developer Mode |
| Bundled sample | Loads a non-installing sample, preserves a remembered device, and attempts safe Personal Team recovery | Advanced diagnostics or contributor tooling | Not required on the primary first-release path; retain until a separate removal decision |
| Legacy custom command | Loads unrecognized stored commands; editable only in DEBUG and otherwise offers migration to guided setup | Compatibility fallback | Preserve read/disable/migrate capability until all supported installations are guided configurations |

### iPhone and connection setup

| Legacy capability | Current behavior | Owner before removal | Parity requirement |
| --- | --- | --- | --- |
| Paired-iPhone discovery | Runs only after an explicit action, keeps physical iPhones, and times out after 20 seconds | Setup flow; Settings when replacing device | Show no-device, unpaired-device, timeout, tool failure, and multi-device selection states |
| Single-device selection | Automatically selects exactly one paired iPhone when no valid target exists | Setup flow | Allowed only because first-release cardinality is one app × one iPhone |
| Exact iPhone identity | Shows name, model, iOS, pairing state, and UDID; preserves a saved or manually entered UDID | Setup flow summary + Advanced diagnostics | Friendly identity is primary; exact UDID remains inspectable and copyable |
| Manual UDID recovery | Accepts a UDID and opens Xcode Devices and Simulators | Advanced diagnostics + System handoff | Keep as recovery, not normal setup |
| Automatic connection | Uses CoreDevice over USB or the same local network | Settings | Default and only launch-promise route |
| Tailnet discovery | Explicitly reads Tailscale status, stores stable node identity and DNS, and refuses to substitute another iPhone | Experimental advanced settings | Keep outside Healthy renewal and Product Hunt claims until separately validated |
| Direct address | Accepts and copies IP/DNS while keeping CoreDevice UDID as installation identity | Experimental advanced settings | Preserve only as a diagnostic connection route |

### Renewal and background settings

| Legacy capability | Current behavior | Owner before removal | Parity requirement |
| --- | --- | --- | --- |
| Execute/dry-run mode | Persists a dry-run mode and requires explicit switch to execute | Setup flow | Simple workspace replaces the persistent mode with one-shot Setup check and explicit first-install confirmation |
| Build strategy | Offers incremental by default and clean rebuild for cache recovery | Settings; clean rebuild also a failure recovery action | Preserve both; keep clean rebuild out of the normal primary surface |
| Version policy | Keeps the project version or increments safely from the newer project/installed version | Settings | Preserve preview and invalid-version failure; default remains keep |
| Renewal interval | Supports 1–168 hours and recommends 144 hours | Settings | Preserve validation; default to six days while actual expiry can move renewal earlier |
| Background registration | Represents not registered, enabled, approval required, missing helper, and unknown status | Renewal domain + Simple workspace | Healthy renewal requires approved and enabled background execution |
| Enable/disable automation | Requires explicit confirmation; disabling preserves target configuration and renewal receipt | Simple workspace + Confirmation | Preserve non-destructive disable semantics |
| Save while active | Requires an explicit confirmation because the next background run will use the changed target | Settings + Confirmation | Never silently redirect active automation |

## State transitions that must survive

| Trigger | Current transition | Destination owner |
| --- | --- | --- |
| No configuration file | Unconfigured, not dirty → first missing setup requirement | Renewal domain → Setup flow |
| Recognized bundled-helper command loads | Saved guided target and policies restored → schedule refreshed | Renewal domain → Simple workspace |
| Unrecognized command loads | Compatibility configuration → migration offer while current automation remains controllable | Compatibility fallback |
| Project selected | Target metadata replaced, configuration dirty, installed-app inspection invalidated | Renewal domain → Setup flow |
| Required field missing | Save or action redirects to the owning setup area | Renewal domain → Next action |
| Saved target edited | Old background target remains active until confirmed save | Renewal domain → Simple workspace warning + Confirmation |
| Setup check succeeds | Summary changes, but no receipt, schedule, installation, or Healthy renewal is produced | Renewal domain → Setup flow |
| First or manual install confirmed | Idle → running phases | Renewal domain → Simple workspace |
| Build, validation, profile read, or install fails | Running → phase-specific failed; receipt is unchanged and renewal remains due | Renewal domain → Simple workspace + Advanced diagnostics |
| Install succeeds with expiration evidence | Running → Verified renewal → next due computed | Renewal domain → success announcement → Healthy renewal |
| Install completes without required expiration evidence | Running → unverified installation; success receipt is not written | Renewal domain → Simple workspace action to inspect installation |
| Configuration command changes | Existing receipt fingerprint no longer matches → immediately due | Renewal domain |
| Renewal not yet due | Background run skips command and does not touch Tailnet or receipt | Renewal domain |
| Tailnet target offline when due | Connection phase fails; command is not run and renewal remains due | Renewal domain → Simple workspace recovery |
| Background enable requested | Confirmation → registered, approval required, or error | Renewal domain → Simple workspace/System handoff |
| Background disable requested | Confirmation → unregistered; configuration and receipt remain | Renewal domain → Simple workspace |
| Current status check fails | Error is surfaced without deleting Last verified evidence | Renewal domain → Simple workspace stale state |

## Safety invariants

These are Renewal domain responsibilities. SwiftUI may request or present them but must not reimplement them.

| Invariant | Current enforcement |
| --- | --- |
| No inferred install target | Project candidate and iPhone selection require explicit adoption; ambiguous apps, schemes, and teams remain unresolved |
| No install with incomplete target | Container, scheme, configuration, product, Bundle ID, Team, UDID, and DerivedData are validated; placeholders and invalid Team/Bundle formats are rejected |
| Only the bundled renewal helper is trusted for guided configuration | Saving checks the executable identity against the bundled helper |
| No unsafe cleanup | A stale `.app` is deleted only beneath resolved DerivedData; root paths and symlink escapes are rejected |
| Build current source every renewal | Both incremental and clean strategies run `xcodebuild`; no cached no-build re-sign path is presented as renewal |
| Install only the expected app | The built `.app` must exist, have a valid `Info.plist`, and match the saved Bundle ID before installation |
| Read signing evidence before install | The embedded Apple Development profile and expiration are parsed before the install command |
| Do not record partial success | A nonzero command, missing required expiration receipt, or install failure does not advance the success receipt |
| Prevent overlapping renewals | Immediate UI gating prevents a second run in-process; the engine also holds a file lock across status check, command, and receipt write |
| Bound external processes and output | Connection and inspection tools have timeouts and size limits; the full workflow has a 27-minute budget; UI logs cap retained text |
| Preserve manual control | Install, background enable/disable, ambiguous Team adoption, and active-target save require explicit confirmation |
| Keep connection route separate from device identity | IP/DNS or Tailnet locates a route; CoreDevice UDID remains the installation target |
| Never substitute a missing remote device | Stable Tailnet node/DNS reconciliation refuses to select a different iPhone |
| Read-only diagnostics remain read-only | Project scan, Team discovery, device-app inspection, profile inspection, status refresh, and Setup check do not change accounts, VPN, Xcode projects, or the iPhone |

## Failure and recovery ownership

| Failure family | Existing signals and recovery | Destination owner |
| --- | --- | --- |
| Project absent or moved | Cached candidate is removed; rescan, another authorized folder, or direct file selection | Setup flow |
| Folder access blocked | Per-location status, permission request, and Files & Folders Settings handoff | Setup flow / Advanced diagnostics |
| Multiple apps or schemes | No guess; exact target fields and Xcode review | Setup flow / System handoff |
| Personal Team missing | Not-found state and preparation guide | Setup flow / System handoff |
| Personal Team weak or ambiguous | Expired/certificate-only provenance, explicit confirmation or candidate menu | Setup flow |
| Xcode/CoreDevice unavailable | No-device, unpaired, timeout, malformed/oversized output, missing tools, and Open Xcode recovery | Setup flow / System handoff |
| Tailnet target missing, offline, or addressless | Connection-phase failure without executing renewal | Experimental advanced settings |
| Invalid or dirty configuration | Field-specific guidance; save and active-agent confirmation | Simple workspace Next action / Settings |
| Background approval required | Open Login Items and Extensions settings; retain manual renewal | Simple workspace / System handoff |
| Build or signing failure | Failed build phase, raw Xcode output, workspace recommendation, optional clean rebuild | Simple workspace / Advanced diagnostics / Settings |
| Built app Bundle ID mismatch | Stop before install and show expected versus actual identifier | Simple workspace / Advanced diagnostics |
| Profile missing or unreadable | Stop before install; expose signing/profile phase and Xcode repair | Simple workspace / Advanced diagnostics / System handoff |
| Installation failure | Preserve previous receipt and failure phase; reconnect/unlock/trust then retry | Simple workspace / System handoff |
| Installation result lacks expiration evidence | Do not write success; inspect installed app and profile before retrying | Simple workspace / Advanced diagnostics |
| Installed-app inspection unavailable | Preserve receipt evidence, explain source limitations, and show tool failure | Advanced diagnostics |
| Unknown failure | Keep phase history and bounded raw log; copy/export for an issue | Simple workspace / Advanced diagnostics |

## Contributor diagnostics that must remain reachable

Advanced diagnostics must preserve:

- exact project/workspace path, scheme, product, Bundle ID, Team ID, configuration, DerivedData path, UDID, connection route, and address;
- project search locations, permission status, scan progress, cached candidates, manual folders, and direct picker;
- all detected developer apps with version, build, Bundle ID, Developer App/App Clip/removability flags, and device path when available;
- provisioning candidate provenance, profile name, App ID, UUID, Team, dates, remaining validity, TTL, platforms, device inclusion, local-provision flag, certificates, and entitlement keys;
- whether a device profile UUID matches the SideRefresh installation receipt, with the existing warning that this is evidence rather than proof of the app/profile relationship;
- every renewal phase and its started/succeeded/failed state;
- bounded raw stdout/stderr with live following, search, jump-to-latest, line wrapping, selection, copy, `.log` export, clear-after-run, line count, and truncation notice;
- read-only compatibility-command summary and a guided migration entry point;
- sample configuration and manual UDID/connection tools until separate removal decisions are made.

The Simple workspace needs only a problem summary and a route into these diagnostics. It must not carry the raw fields itself.

## Verified coverage and gaps

Validation performed for this inventory:

- Swift package tests: **168 passed, 0 failed, 0 skipped**.
- Public CLI tests: **10 passed**.
- Covered Core behavior includes schedules, required expiration receipts, unchanged receipt after failure, lock-safe execution, process bounds, project filtering and ambiguity, target validation, safe DerivedData cleanup, Bundle ID validation, Personal Team evidence, device/Tailnet identity, installed-app and profile readers, logs, background agent control, and MCP confirmations.

Known gap:

- There is no dedicated test target for `SideRefreshViewModel` or the SwiftUI Legacy workspace. View-local condition precedence, action routing, alerts, sheet navigation, dirty-evidence presentation, and menu-bar parity are currently verified by reading and manual use rather than automated UI or presentation-model tests.

The migration acceptance matrix must therefore test the new Renewal condition/Next action resolver through a stable Renewal domain interface, plus a smaller number of end-to-end SwiftUI checks. Copying the current view-local branches into new views would preserve this gap and fail the deletion test.

## Primary implementation sources

- `Sources/SideRefreshApp/SideRefreshApp.swift`
- `Sources/SideRefreshApp/SideRefreshViewModel.swift`
- `Sources/SideRefreshApp/RenewalTargetDraft.swift`
- `Sources/SideRefreshApp/RenewalLogWindow.swift`
- `Sources/SideRefreshCore/ConfiguredRenewalRunner.swift`
- `Sources/SideRefreshCore/RenewalEngine.swift`
- `Sources/SideRefreshCore/IOSAppRenewalPlan.swift`
- `Sources/SideRefreshIOSRenewal/main.swift`
- `SwiftTests/SideRefreshCoreTests`
- `SwiftTests/SideRefreshMCPServerTests`
- `Tests/test_cli.py`
- `docs/MANUAL.ko.md`
- `docs/STATUS.md`
- `docs/DEVICE-DATA-INVENTORY.ko.md`
