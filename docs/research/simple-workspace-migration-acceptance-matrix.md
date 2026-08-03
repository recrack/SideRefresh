# Simple workspace migration acceptance matrix

> Decision date: 2026-07-31
>
> Scope: Simple-default readiness, first stable public release, and later
> Legacy workspace removal

This document defines the evidence required before SideRefresh makes the Simple
workspace the default, approves a public source preview, approves the first
stable candidate, or deletes the Legacy workspace. It also defines immediate
post-publication checks whose evidence cannot exist before a GitHub release is
public.

It does not implement tests or certify the current app. It defines the release
record that later implementation must satisfy.

## Gate decision

The release and migration transitions use five separate gates:

| Gate | Transition | Required outcome |
| --- | --- | --- |
| **Simple-default gate** | A prerelease first launches into the Simple workspace | Every default-gate automated row and human row passes; the Help-menu Legacy fallback remains |
| **Public-source gate** | Approve and immediately verify publication of `v0.2.0-beta.1` and the public repository | Every default and public-source row passes; the release is source-only, marked as a prerelease, and verified after publication |
| **Stable-candidate gate** | Approve publication of the signed and notarized `v0.2.0` binary | Every applicable default, public-source, and stable-candidate row passes against the exact final draft assets, including real Personal Team renewal across the original signing expiration |
| **Post-publication verification** | Verify the just-published immutable stable release | The public download, checksum, tag, provenance, immutability, and Gatekeeper checks pass before announcement or Product Hunt launch |
| **Legacy-removal gate** | Delete the Legacy workspace in a later release | At least one stable release has shipped with Simple as default and Legacy as fallback; every removal row passes after the Legacy code is deleted |

The first stable release cannot also be the release that removes Legacy. Stable
exposure with the fallback is evidence for the later removal gate.

The gate order is `D → P → S → V → R`. A later gate requires earlier behavior
to remain valid, but it does not require an impossible rerun:

- rows still meaningful for the candidate are rerun;
- evidence invalidated by a relevant change is rerun;
- `PRES-08`, `MIG-03`, `MIG-04`, and `HUM-15` are coexistence rows and are
  recorded as `carried-forward` at the Legacy-removal gate;
- `MIG-07` is historical stable-release evidence and is also carried forward;
- every other default behavior that remains after Legacy deletion is rerun
  against the post-deletion candidate.

Carry-forward names the exact earlier version, artifact, result, and reason the
row remains valid. It is not `not-applicable`.

Elapsed time, usage volume, and lack of bug reports are not acceptance
evidence. A gate passes only through the rows below.

## Evidence classes

Every row requires one of these evidence classes:

| Class | Meaning |
| --- | --- |
| **Unit** | Deterministic XCTest against a Module's Interface with clocks, processes, files, and system states controlled |
| **Integration** | A built executable, CLI, MCP server, sample Xcode project, or local Agent exercised without a real iPhone mutation |
| **UI smoke** | A built macOS app launched with a DEBUG-only in-memory fixture Adapter and asserted by semantic element identity, label, enabled state, navigation, and focus—not pixel snapshots |
| **Human fixture** | A person exercises a deterministic display/failure fixture to judge copy, information hierarchy, keyboard behavior, VoiceOver, contrast, and recovery clarity |
| **Real system** | A person uses the final app with actual Xcode, Personal Team signing, macOS permissions, background Agent, and a physical iPhone |
| **Release** | Signature, notarization, archive integrity, clean-account installation, documentation, and immutable artifact evidence |
| **Review** | A named human inspects a capability ledger, release manifest, or deletion diff against its source contract; behavior rows still require their automated or real-system evidence |

Automated fixtures can prove state resolution and UI routing. They cannot stand
in for Apple signing, pairing, installation, Login Item approval, sleep/wake,
or a Personal Team expiration.

## Test seams

### Renewal presentation

The Renewal presentation Module is the primary automated test seam. Tests
provide saved configuration, live Agent state, renewal evidence, current run,
failure, connection, compatibility, and time, then assert one returned value:

- Renewal condition;
- zero or one Next action;
- selected app-to-iPhone relationship;
- Last verified evidence and verification time;
- current progress or recent result;
- destination availability.

Simple, Legacy, and menu-bar adapters consume that Interface. Tests do not
recreate the precedence rules by asserting view-local branches.

### Navigation and mutation

A small app-presentation Module owns destination state and maps semantic actions
to existing `SideRefreshViewModel` commands. Unit tests assert proposal versus
draft versus saved-target transitions and confirmation requirements. UI smoke
tests assert only that SwiftUI exposes and routes the returned semantics.

### System adapters

Existing Core readers and runners retain their fixture-driven unit coverage.
Project handoff, MCP safety profile, filesystem, Xcode process, LaunchAgent, and
CoreDevice adapters receive integration tests at their own Interfaces.

Real-system evidence always uses a release-equivalent app. A fake process result
is not evidence that Xcode signed or installed an app on an iPhone.

## Current baseline and gaps

The following baseline was rerun on 2026-07-31:

- `swift test`: **168 passed, 0 failed**;
- `python3 -m pytest -q`: **10 passed**;
- `Scripts/validate-samples.sh`: passed without signing or installation;
- `Scripts/validate-headless.sh`: passed for CLI, Agent plan, and the current MCP
  protocol.

Existing automated coverage is strong for scheduling, receipt preservation,
bounded processes and logs, Xcode container inspection, Personal Team evidence,
target validation, safe DerivedData cleanup, Bundle ID checking, installed-app
and profile readers, LaunchAgent control, Tailnet identity, and concurrent-run
locking.

The current gaps are release blockers for the relevant gate:

- no Renewal presentation Module or exhaustive condition/action tests;
- no dedicated app-presentation or `SideRefreshViewModel` test surface;
- no macOS UI smoke target;
- no Project handoff implementation or test;
- MCP tests and Headless validation still expect all six mutating tools in the
  default profile;
- no accessibility acceptance record;
- no real-device, background-renewal, expiry-crossing, or migration acceptance
  record;
- no Developer ID-signed and notarized stable artifact.

## Automated acceptance matrix

`D` means required for the Simple-default gate, `P` for public-source
publication, `S` for stable-candidate approval, `V` for immediate
post-publication verification, and `R` for Legacy removal. The carry-forward
rules above govern rows whose historical behavior cannot exist after deletion.

### Renewal presentation and action routing

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `PRES-01` | D | Unit | Every supported Renewal condition returns the specified zero-or-one Next action and destination |
| `PRES-02` | D | Unit | Precedence conflicts retain the serious condition while the action removes the nearest prerequisite: expired plus dirty, due plus disconnected, automation off plus permission required, and failure plus stale evidence |
| `PRES-03` | D | Unit | Healthy renewal requires a saved target, Verified renewal, known next time, enabled/approved automation, and no unresolved failure; it returns no primary action |
| `PRES-04` | D | Unit | Refreshing, timeout, disconnection, and a new failure preserve Last verified evidence and its original verification time without presenting it as live |
| `PRES-05` | D | Unit | Running owns the presentation, advances through every renewal phase, disables conflicting mutations, and exposes no cancel action |
| `PRES-06` | D | Unit | Installation without expiration evidence is not a Verified renewal, writes no successful presentation, and routes to inspection instead of blind retry |
| `PRES-07` | D | Unit | Success is transient and settles into Healthy renewal while version, installation time, expiration, and next renewal remain as recent evidence |
| `PRES-08` | D | Unit | Simple, Legacy, and menu-bar adapters receive the same condition, action label, availability, evidence, and target from one Renewal presentation fixture |
| `PRES-09` | R | Unit | Deleting the Legacy adapter changes no Renewal presentation test or Simple/menu-bar result |
| `PRES-10` | D | Unit + UI smoke | An otherwise Healthy saved target plus a dirty draft produces `Target changes unsaved → Review and save changes`; draft schedule/profile-match evidence is unavailable, while the prior schedule and Last verified evidence are labelled as belonging to the previous saved target until confirmed save |

The resolver table must enumerate all supported input combinations that affect
precedence. Line or branch coverage is useful diagnostics but cannot replace
the explicit state table.

### Setup, target changes, and permissions

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `SETUP-01` | D | Unit + UI smoke | Missing configuration opens the Setup flow at the first missing requirement; completed setup returns to Simple with no persistent checklist |
| `SETUP-02` | D | Integration + UI smoke | Project handoff, direct file selection, and authorized-folder scan produce the same review proposal and require explicit adoption |
| `SETUP-03` | D | Unit | Related workspace/project pairs recommend the workspace; multiple apps, schemes, or Team candidates remain unresolved and no first candidate is guessed |
| `SETUP-04` | D | Unit + Integration | Cancelled, denied, partial, granted, and later-revoked project-folder access remain distinguishable; a failed probe never claims access |
| `SETUP-05` | D | Unit | Setup check validates the draft without build, signing, device contact, install, schedule change, active-target change, or success receipt |
| `SETUP-06` | D | Unit + UI smoke | First install and automatic-renewal activation are separate confirmations; successful install does not silently enable automation |
| `SETUP-07` | D | Unit | Editing an existing target changes only the draft; cancel keeps the old target, schedule, current run, and Last verified evidence |
| `SETUP-08` | D | Unit | Saving while automation is active requires confirmation; until save succeeds, the existing automatic target remains active |
| `SETUP-09` | D | Unit + UI smoke | Missing project, signing, Team, iPhone, trust, Developer Mode, background approval, and Files & Folders permission route to the owning Setup step or contextual System handoff |
| `SETUP-10` | D | Integration | Moving or deleting a selected Xcode container removes the stale candidate and offers direct selection and authorized-folder discovery without altering the saved target |

### Project handoff and Agent safety

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `HAND-01` | D | Unit | Only an absolute, readable `.xcodeproj` or `.xcworkspace` is accepted; alias and symbolic-link identity use the canonical path |
| `HAND-02` | D | Unit | Inspection reads only bounded static metadata from the exact container and workspace references; it performs no home/sibling scan, source read, `xcodebuild`, project script, configuration write, install, or schedule change |
| `HAND-03` | D | Unit + Integration | Same-path retry reactivates one pending request; a different path returns `handoff_in_progress`; accept, cancel, and app quit clear the request |
| `HAND-04` | D | Integration | `app_not_found`, `launch_failed`, invalid path, and unreadable path leave no new pending record |
| `HAND-05` | D | UI smoke | A recognized or unverified Agent-made project opens the existing project picker and changes only the Setup draft after user review |
| `HAND-06` | D | Unit + Integration | Default MCP advertises and dispatches only `get_status`, `handoff_project`, and `dry_run`; hidden mutating calls are unavailable |
| `HAND-07` | D | Unit + Integration | `--allow-headless-mutations` adds the four existing mutating tools; a request argument such as `confirm: true` cannot elevate the default profile |
| `HAND-08` | D | Unit | Result payloads disclose only the handoff result and invariant booleans; no callback, decision polling field, Team ID, device detail, configuration, source, or log is returned |
| `HAND-09` | D | Integration | MCP and `side-refresh project handoff` produce the same result/error codes through one Project handoff Interface |

### Renewal engine and automation

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `AUTO-01` | D | Unit | Next renewal is the earlier of configured interval and 24 hours before actual known expiration; no receipt means immediately due |
| `AUTO-02` | D | Unit | Incremental and clean strategies both build current source, validate the expected app and Bundle ID, read the embedded expiration, then install |
| `AUTO-03` | D | Unit + Integration | Invalid target, placeholder Team, unsafe DerivedData, Bundle ID mismatch, missing profile/expiration, build failure, and install failure cannot write a successful receipt |
| `AUTO-04` | D | Unit + Integration | In-process gating and the engine file lock prevent overlapping manual/background renewals |
| `AUTO-05` | D | Unit | Enable, approval-required, enabled, disable, missing-helper, and unknown background states map to explicit transitions and confirmations |
| `AUTO-06` | D | Unit | Disabling automation preserves target configuration and Last verified evidence; re-enabling recalculates the next run |
| `AUTO-07` | D | Unit + Integration | A not-due background run performs no Xcode, device, Tailnet, receipt, or schedule mutation |
| `AUTO-08` | D | Integration | A due failure remains due, keeps the prior receipt, and releases the lock for a later retry |
| `AUTO-09` | S | Real system | With the app quit, an approved Agent executes a short-interval due renewal and records Verified renewal separately over every connection route advertised for automatic renewal |
| `AUTO-10` | S | Real system | If the Mac sleeps through a due time, wake triggers the supported later run without duplicate execution |
| `AUTO-11` | S | Real system | For every advertised automatic route, making that route unavailable when due fails in connection, preserves evidence, remains due, and succeeds after the same route is restored without changing targets |
| `AUTO-12` | S | Real system | Separately over every route advertised for automatic renewal, the app stays quit while the approved background Agent renews a Personal Team installation before expiry; the app remains launchable after the original profile expiration and the installed receipt shows a later verified expiration |

`AUTO-12` requires an actual expiry-crossing soak. Shortening the configured
interval proves scheduling but not the core promise that the personal app keeps
working past its original signing expiration. For the first release, claiming
both USB and same-local-network automatic renewal requires a recorded
short-interval background run and expiry-crossing soak for each route. An
untested route is removed from the compatibility table and product claims.

### Failure recovery and Diagnostics

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `DIAG-01` | D | Unit + UI smoke | Connection, build, signing/profile, Bundle ID, install, unverified-install, permission, moved-project, and unknown failures show the correct phase, preserved-evidence statement, and one recovery route |
| `DIAG-02` | D | Unit | Bounded stdout/stderr, line count, split UTF-8, truncation, search source, wrapping state, and recent preview remain correct under large and partial output |
| `DIAG-03` | D | UI smoke | Diagnostics opens from a failed result, running progress, Help, Settings, and menu bar without changing the target or condition |
| `DIAG-04` | D | Integration | Copy and `.log` export contain the selected run and truncation notice and do not trigger a retry or configuration mutation |
| `DIAG-05` | D | Unit | Default issue information redacts personal absolute paths, full UDID, exact local account name, and unrelated environment values while retaining versions, phases, error categories, and stable product identifiers |
| `DIAG-06` | D | Unit + UI smoke | Last verified evidence shows provenance and time beside a later failure; device/profile evidence is labelled as evidence rather than proof when association is ambiguous |
| `DIAG-07` | D | Unit | Read-only refresh cannot install/delete an app or profile, alter Xcode/Apple credentials, log into Tailscale, enable VPN, or change permissions |
| `DIAG-08` | S | Human fixture | A person unfamiliar with the implementation can identify what failed, whether the current iPhone app remains usable, and the next recovery action before expanding raw logs |

### Accessibility and semantic UI

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `A11Y-01` | D | UI smoke | Condition, Next action, relationship, Last verified evidence, progress, settings destinations, and confirmations have stable semantic identifiers and meaningful labels |
| `A11Y-02` | D | UI smoke | Healthy has no enabled primary action; each non-Healthy fixture exposes exactly one enabled primary action |
| `A11Y-03` | D | UI smoke | Keyboard-only navigation reaches project choice, Setup controls, Settings, Advanced settings, Diagnostics, logs, and every confirmation in a logical order |
| `A11Y-04` | D | UI smoke | Opening and closing a sheet/window moves focus into it and restores focus to its trigger; Escape cancels only where cancellation is safe |
| `A11Y-05` | D | Human fixture | VoiceOver announces condition before action, combines the app-to-iPhone relationship meaningfully, reports selected candidates, and announces progress without repeating every log line |
| `A11Y-06` | D | Human fixture | Increased contrast, reduced motion, grayscale/color-filter use, and the supported window-size range preserve status and action meaning without color alone, clipping, or hidden controls |
| `A11Y-07` | D | Human fixture | Korean interface copy uses consistent action names from trigger through confirmation and result; technical English identifiers remain distinguishable and copyable |

Pixel-perfect snapshots are not a gate. They are too sensitive to macOS,
locale, font, and rendering changes. Semantic UI assertions plus targeted human
visual evidence protect the actual contract.

### Migration, parity, and deletion

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `MIG-01` | D | Unit + Integration | Existing supported configuration, interval, version/build policy, target, receipt, and Last verified evidence load unchanged into Simple |
| `MIG-02` | D | Unit + UI smoke | Existing unrecognized custom-command configuration remains readable and disableable and offers guided migration; release builds cannot create or edit arbitrary commands |
| `MIG-03` | D | UI smoke | Every launch opens Simple; `Help → Open Legacy Workspace` changes only current-session navigation and relaunch returns to Simple |
| `MIG-04` | D | Unit + UI smoke | Switching Simple ↔ Legacy keeps one view model, target, draft, current run, failure, schedule, and Last verified evidence |
| `MIG-05` | D | Review | A named reviewer maps every inventoried Legacy capability to a destination and automated or human acceptance row; no row is marked `Legacy-only` |
| `MIG-06` | S | Real system | A configuration and receipt created by the latest Legacy build using the current SideRefresh storage identifiers survive upgrade and first launch of the final stable candidate |
| `MIG-07` | R | Release | At least one immutable stable release shipped with Simple default and the session-only Legacy fallback |
| `MIG-08` | R | Integration + Review | `SideRefreshWorkspaceSection`, the four-section `NavigationSplitView`, Legacy-only cards/state, Help fallback, and Legacy-only tests are deleted; the app builds and all non-Legacy tests remain unchanged and green |
| `MIG-09` | R | Unit + UI smoke + Human fixture + Review | Setup, Settings, Advanced settings, Diagnostics, confirmations, System handoffs, menu bar, compatibility fallback, and every failure recovery remain reachable without Legacy |
| `MIG-10` | R | Review | A named reviewer confirms that Legacy deletion adds no condition/action precedence to SwiftUI, alters no Core scheduling/execution, replaces no view-model mutation command, and changes no stored configuration/evidence |

### Stable release artifact

| ID | Gate | Evidence | Scenario and assertion |
| --- | --- | --- | --- |
| `SRC-01` | P | Release + Review | Before public visibility, tracked source/assets and all branches, tags, history, Actions logs, and research complete privacy, secret, credential, and provenance review; the repository contains MIT licensing and required community, security, contribution, and support files |
| `SRC-02` | P | Release | The `v0.2.0-beta.1` tag and final GitHub release draft are prepared as a source-only prerelease; tests and source-build instructions pass and the draft contains no ad-hoc binary or Gatekeeper-bypass instruction |
| `SRC-03` | P | Review | README and prerelease notes state the Personal Team expiration model, Mac/Xcode/initial-pairing requirements, privacy behavior, exact tested compatibility, known limitations, build/install/update/uninstall steps, and community-support policy |
| `SRC-04` | P | Release | Immediately after publication, the public tag and generated source archives resolve to the reviewed commit, the release is visibly a source-only prerelease, and GitHub reports the release immutable; a failure stops promotion and requires a new prerelease version rather than tag or asset replacement |
| `REL-01` | S | Release | The candidate is built from the release tag, every executable is Developer ID-signed with hardened runtime and secure timestamp, notarization is accepted and stapled, and `codesign`, `stapler`, and Gatekeeper assessment pass |
| `REL-02` | S | Release + Review | The final release draft contains the correctly architecture-labelled app archive, `SHA256SUMS`, `LICENSE`, release notes linked to the full changelog, installation/update/complete-uninstall instructions, compatibility table, and known limitations |
| `REL-03` | S | Release | The final candidate archive checksum matches draft `SHA256SUMS`, its commit and workflow are recorded, and build provenance connects the artifact to the tagged source revision |
| `REL-04` | S | Release + Real system | The exact final candidate archive is transferred unchanged to a clean macOS account, passes Gatekeeper, launches the stapled app, finds the embedded Agent/helper, completes the supported flow, and follows the documented uninstall successfully |
| `REL-05` | S | Release + Review | Source and binary assets include the MIT license; tracked code/assets and public history have completed privacy and provenance review; required community, security, support, and compatibility documentation is present |
| `REL-06` | V | Release | Immediately after publication, a fresh public download matches `SHA256SUMS`, the published tag and source revision, the recorded provenance, and the prepublication archive hash; the GitHub release reports immutable |
| `REL-07` | V | Release + Real system | The fresh public download passes signature, stapler, and Gatekeeper verification on a clean account and launches the same app version/build |

If a `V` row fails, do not move the tag, replace an asset, edit a checksum to
match a bad asset, announce the release, or launch on Product Hunt. Record the
failure as a release blocker, preserve the immutable evidence, correct the
problem, and publish a new version after all candidate gates pass.

## Human and real-system acceptance matrix

Each row is performed on a declared supported combination. The record names the
exact macOS version and build, Mac model and architecture, Xcode version, iOS
version, iPhone model, connection route, app commit, app version/build, and
tester.

| ID | Gate | Scenario | Required observation |
| --- | --- | --- | --- |
| `HUM-01` | D | Fresh local account, no SideRefresh configuration | First-run scope is understandable; the user reaches project review without consulting the manual |
| `HUM-02` | D | Agent invokes Project handoff for a generated workspace | SideRefresh activates, shows requested/resolved path and proposal, and changes nothing before review |
| `HUM-03` | D | Direct project selection and separately authorized-folder discovery | Both reach the same proposal; privacy disclosure precedes folder access and source is neither changed nor uploaded |
| `HUM-04` | D | Project with multiple apps/schemes or ambiguous Team evidence | The user is asked to resolve the ambiguity; no candidate is silently chosen |
| `HUM-05` | D | No paired iPhone, one paired iPhone, and two paired iPhones | Missing-device recovery is actionable, one device may preselect, and multiple devices require explicit choice |
| `HUM-06` | D | Setup check on a complete draft | It clearly says no install occurred; active target, iPhone, schedule, and receipt remain unchanged |
| `HUM-07` | D | Replace the target while automation is enabled, then cancel | Current automatic target and Last verified evidence remain visible and active |
| `HUM-08` | D | Replace the target, review, save, and confirm | New target becomes active only after confirmation and schedule/evidence labels update without ambiguity |
| `HUM-09` | D | Files & Folders denial, cancellation, later grant, and revocation | The app reports actual access, opens the correct System Settings destination, and recovers after return |
| `HUM-10` | D | Login Item approval required, granted, disabled, and re-enabled | Simple always presents one correct action; disabling preserves target and evidence |
| `HUM-11` | D | Keyboard-only pass through Setup, Settings, Diagnostics, and confirmations | All required behavior completes without a pointer and focus remains visible/predictable |
| `HUM-12` | D | VoiceOver plus reduced-motion/increased-contrast passes | State, relationship, evidence age, selection, and action remain understandable |
| `HUM-13` | D | Connection, build/signing, install, and unknown failure fixtures | Each explanation preserves previous evidence and points to the correct recovery before raw logs |
| `HUM-14` | D | Copy issue information and export a long truncated log | The shared report is useful, marks truncation, and redacts personal path/account/device values by default |
| `HUM-15` | D | Open Legacy from Help during a run, return to Simple, relaunch | Run and evidence continue; navigation is session-only; relaunch returns to Simple |
| `HUM-16` | S | Clean-account install of the exact final candidate archive | Gatekeeper accepts the stapled app; first launch, helper presence, Settings, Diagnostics, and complete uninstall match documentation |
| `HUM-17` | S | First real Personal Team install over USB | The named app is built from current source, expected Bundle ID is installed on the selected iPhone, expiration is read, and automation remains opt-in |
| `HUM-18` | S | Manual renewal over the same local network after USB pairing | With the cable absent, the selected app updates without target substitution, records the local-network route, and records a later Verified renewal |
| `HUM-19` | S | App quit, short interval, Mac sleep/wake, and background renewal | Once with USB as the recorded route and once with the cable absent on the same local network, the approved Agent runs once, the UI later reads the result, and no open SideRefresh window was required |
| `HUM-20` | S | Each advertised connection route becomes unavailable when a background renewal is due | Failure occurs before build/install, prior evidence remains, and restoring the same route allows the same target to renew |
| `HUM-21` | S | One expiry-crossing soak per advertised automatic route | With no manual renewal during each soak window, the approved background Agent records the intended USB or cable-free local-network route, installs a later verified profile, and the app launches after the original signing expiration |
| `HUM-22` | S | iPhone reboot before a due renewal | Actual required unlock/trust behavior is recorded; any user action is reflected in support claims rather than called Hands-free renewal |
| `HUM-23` | S | Declared minimum and current supported OS/Xcode combinations | Each claimed combination completes setup and a real renewal; untested combinations are not listed as supported |
| `HUM-24` | S | Final archive on every advertised architecture | The exact archive builds, launches, signs, notarizes, and completes the supported flow; a host-only artifact is never called universal |
| `HUM-25` | R | Post-Legacy build repeats setup, renewal, failure, accessibility, menu-bar, and diagnostics smoke | No task or evidence route depends on a removed Legacy surface |

The first release may publish a narrow compatibility table. It must not infer
support for an untested macOS, Xcode, iOS, iPhone, or architecture merely
because compilation succeeds.

## Release evidence record

For each prerelease and stable release candidate, create
`docs/releases/<version>-acceptance.md` from this matrix. Each row records:

- status: `not-run`, `pass`, `fail`, `blocked`, `not-applicable`, or
  `carried-forward`;
- commit SHA, app version/build, and release archive SHA-256;
- automated workflow URL or exact local command and result;
- for UI/real-system evidence, tester, date, environment, and connection route;
- screenshot, screen recording, exported log, or redacted diagnostic artifact
  when it materially proves the observation;
- linked release-blocking issue for every `fail` or `blocked`;
- reason and approver for `not-applicable`.

A `carried-forward` row additionally records the earlier release and artifact,
the original evidence link, and the contract rule that makes a candidate rerun
impossible or unnecessary.

`assumed`, `probably`, and `no reports` are not statuses.

Evidence belongs to the exact candidate. A change to the Renewal presentation,
Setup routing, engine, signing/install path, background Agent, permissions,
Diagnostics redaction, Legacy adapter, packaging, or entitlements invalidates
the affected rows and requires rerun.

Personal paths, Apple Account details, certificate material, full UDIDs,
profiles, and unredacted logs remain out of the repository and public issue
tracker.

## CI and release policy

Every pull request affecting the migration must pass:

1. `swift test`;
2. `python3 -m pytest -q`;
3. `Scripts/validate-samples.sh`;
4. `Scripts/validate-headless.sh`;
5. Renewal presentation and app-presentation tests;
6. Project handoff and MCP profile tests;
7. semantic macOS UI smoke tests when a UI path changes.

The workflow runs on the declared minimum supported toolchain and the current
release toolchain. Architecture-specific jobs match advertised artifacts.

The Simple-default gate has no open failure in a `D` row and no release-blocking
Simple bug. Public visibility additionally has no open `P` failure. Stable
publication requires no open `S` failure and uses the final signed, notarized,
stapled archive. The stable release is accepted for announcement only after
every `V` row passes. The Legacy-removal gate additionally has no
`Legacy-only` capability, no open `R` failure, and a passing deletion diff
review; only the explicitly named coexistence/history rows may be carried
forward.

Non-blocking visual polish may ship with a linked issue only when it does not
change information hierarchy, action availability, safety, recovery,
accessibility, supported compatibility, or the public release contract.

## What this matrix deliberately does not require

- pixel snapshots for every macOS version;
- real-device mutation in pull-request CI;
- public claims for Tailnet, direct-address, pure-cellular, or multi-target
  behavior;
- seven days of waiting for every patch release after the expiry-crossing path
  is unchanged;
- deletion of the custom-command compatibility fallback with Legacy;
- a permanent second UI test implementation of Renewal condition rules.

If the expiry calculation, signing/install path, background Agent, or receipt
recording changes, the stable gate requires a new real expiry-crossing soak even
for a patch.
