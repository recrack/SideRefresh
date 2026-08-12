# First-release acceptance matrix

> Decision artifact for the Wayfinder first-release map, under “First public SideRefresh release”.

This matrix defines the first stable claim: one Agent-made personal app, one paired physical iPhone, first installation over USB, and Hands-free automatic renewal (no user action after initial setup) only over USB or a separately verified local-network CoreDevice route. The release ledger must nominate exact iPhone model plus iOS version/build combinations before any support claim; an unspecified combination remains blocked and is not a claim. Once nominated, each exact host/toolchain/device/archive combination is a separate case and each advertised connection path is a separate route; this artifact does not invent missing values. Pure cellular mode, the CoreDevice/Tailnet bridge, and unverified direct-IP paths are not stable-release claims. The matrix has 7 minimum-environment dimensions and 13 required executable rows; at matrix creation, none of those executable rows is `pass`. The existing USB notes in `docs/STATUS.md` describe earlier sample/workspace evidence, not the exact final archive.

## Minimum supported environment matrix

| ID | Declared minimum or test dimension | Current gate |
| --- | --- | --- |
| M-01 | macOS 13 or later (Package.swift and README floor); record exact version/build. | blocked: the minimum host plus the final archive has not been exercised. |
| M-02 | Xcode 16.2 or a compatible Swift 6 toolchain; record Xcode and Swift versions/builds. | not-run: the exact minimum combination is not evidenced. |
| M-03 | Host architecture: arm64 is the baseline; x86_64 is supported only if the archive is universal or explicitly labelled and tested per architecture. | blocked: the current build is host-architecture and no final archive is available. |
| M-04 | One physical iPhone, paired and trusted in Xcode, Developer Mode enabled, with an Apple Account Personal Team. The release ledger must nominate exact iPhone model plus iOS version/build combinations before any support claim; record each exact combination. An unspecified combination remains `blocked` and is not a claim. | blocked: the release ledger names no exact iPhone model plus iOS version/build combination. |
| M-05 | USB: required for first installation and the baseline automatic-renewal route. | not-run for the final archive. |
| M-06 | Local network/CoreDevice: advertise only after a separate real-device run proves the saved route. | not-run; current status does not provide that evidence. |
| M-07 | Tailscale/pure-cellular/direct-IP: diagnostic or experimental only, omitted from the stable compatibility claim. | not-applicable to the stable claim; no pass may be inferred. |

## Required executable rows (13)

Each row is run on the exact release archive and every required case/route record. A fixture, simulator, fake process, dry run, or CI-only result can validate implementation but cannot satisfy a real-device row.

| ID | Scenario and minimum pass condition | State |
| --- | --- | --- |
| A-01 | Fresh macOS account downloads the immutable archive; checksum, provenance, signature, stapler, Gatekeeper, launch, version/build all agree. | blocked: no final Developer ID archive. |
| A-02 | Fresh account completes Setup flow, selects one app/iPhone, runs Setup check, and sees the target review boundary. | not-run |
| A-03 | First USB installation builds/signs/installs the expected Bundle ID and records embedded profile expiration evidence. | not-run |
| A-04 | User explicitly approves Automatic refresh; SMAppService/LaunchAgent registration is visible and build alone does not register it. | not-run |
| A-05 | Confirmed Refresh now succeeds over USB and records a Verified renewal; a failed run does not update success state. | not-run |
| A-06 | Quit and relaunch before/after a due run preserves target, Last verified evidence, schedule state, and bounded logs without duplicate registration. | not-run |
| A-07 | Mac sleeps across a due schedule, wakes, and launchd coalesces one run; outcome and receipt are correct while the app is quit. | not-run |
| A-08 | Real physical-device iPhone reboot: after initial setup, reboot the selected iPhone immediately before or during a due `Hands-free renewal` and take no user action afterward (including unlock, trust, reconnect, or pressing Refresh). Exercise each advertised route separately and capture route-specific reachability, install, and signing-expiration evidence. Preserve the prior state (target, schedule, Last verified receipt, and success state) if reboot blocks or fails renewal; there is no false success—mark `pass` only with verified post-reboot installation/expiration evidence, never for a queued command or process exit. | not-run |
| A-09 | USB/LAN route is lost before or during renewal; no false success/state advance occurs; restoring the route permits recovery. | not-run |
| A-10 | A real failed renewal leaves the prior successful receipt unchanged; a later retry after recovery succeeds and records new expiration. | not-run |
| A-11 | For every advertised route, a short-interval automatic run succeeds with SideRefresh quit and the route-specific evidence. | not-run for USB; blocked for LAN until M-06 is evidenced. |
| A-12 | For every advertised route, a real provisioning-expiration crossing while SideRefresh is quit renews before expiry and records the next safe expiry. | not-run for USB; blocked for LAN until M-06 is evidenced. |
| A-13 | Disable schedule and uninstall/remove SideRefresh without deleting the user's Xcode project or installed app; retained evidence removal is explicit. | not-run |

## Evidence records, cardinality, and statuses

### Case, route, and record identity

The release ledger must nominate exact environment cases before execution. A case covers one exact tuple of Mac model, host architecture, macOS version/build, Xcode version/build, Swift toolchain identifier (including its exact version/build), iPhone model, iOS version/build, and the final archive identity (`archive_sha256`; `archive_filename` is recorded alongside it). `case_id` is the deterministic lowercase SHA-256 of the canonical UTF-8, newline-delimited `key=value` serialization of these keys in this order: `mac_model`, `architecture`, `macos_version`, `macos_build`, `xcode_version`, `xcode_build`, `swift_toolchain`, `iphone_model`, `ios_version`, `ios_build`, `archive_sha256`. Surrounding whitespace is normalized and no values are inferred. Any changed tuple member produces a new `case_id`; the missing M-04 iPhone/iOS nomination therefore produces no synthetic case ID and remains a blocked gate.

`route_id` is the deterministic lowercase SHA-256 of the canonical UTF-8 descriptor for one advertised connection route (route kind plus route-specific configuration), and is unique within the release. A changed route or route configuration gets a new `route_id`; a pass on one route never identifies or satisfies another.

For every executable row, create exactly one record for each required `row_id × case_id × route_id` tuple: one record per nominated exact case and each advertised route applicable to that row. A row with no route dependency must still declare one route-neutral `route_id` so the record dimension is never omitted. The release ledger declares `applicable_case_ids`, `applicable_route_ids`, and, when applicability is not a full Cartesian product, the explicit `applicable_combinations` of case/route pairs. A missing or unavailable required tuple is not silently covered by another case or route. `record_key` is the unique composite `${row_id}::${case_id}::${route_id}`; changing any component creates a new record.

### Evidence schema

Every executable record has these exact fields (redact Apple Account data, Team IDs, UDIDs, Tailnet names/addresses, private paths, profiles, certificates, and source): `row_id`; `case_id`; `route_id`; `record_key`; `applicable_case_ids`; `applicable_route_ids`; `applicable_combinations`; `status`; `expected`; `observed`; `tester`; `captured_at` with timezone; `release_commit` (full SHA); `release_tag`; `app_version` (`CFBundleShortVersionString`); `build_number` (`CFBundleVersion`); `archive_filename`; `archive_sha256`; `provenance_or_attestation`; `environment` containing Mac model/architecture, macOS version/build, Xcode version/build, Swift toolchain identifier (including exact version/build), iPhone model, iOS version/build, and the route descriptor; and `logs` containing sanitized log paths or artifact links, hashes, capture time, and any screenshot/video or profile-expiration receipt needed by the row.

Allowed statuses are:

- `not-run`: the record is defined but execution has not completed or produced execution evidence.
- `pass`: the exact candidate and environment met the row with complete evidence.
- `fail`: execution completed and the criterion was not met; retain the failure logs.
- `blocked`: a required artifact, approval, device, route, or environment is unavailable; record the blocker.
- `not-applicable`: intentionally outside the stable claim; record the exclusion (for example, M-07).
- `carried-forward`: prior evidence is for the same exact candidate/case/route, is linked in the record, and was rechecked; historical fixtures or a different build do not qualify.

Aggregate a row's required records with this precedence, highest first: `fail` > `blocked` > `not-run` > `carried-forward` > `pass` > `not-applicable`. A row is `fail` when any required record fails, `blocked` when none fails but any required record is blocked, `not-run` when none above applies but any required record is not-run, and `carried-forward` when none above applies but at least one required record is carried-forward. A row is `pass` only when every required record is `pass`; carried-forward evidence never counts as pass. `not-applicable` is terminal only when the release ledger explicitly puts the row outside the claim and there are no required case/route tuples. It is not valid for an advertised required tuple and cannot hide another route's `fail`, `blocked`, `not-run`, or `carried-forward` record. An unenumerated required set, including the missing M-04 nomination, is blocked rather than pass or not-applicable.

## Boundary with release execution

This artifact owns dimensions, row IDs, pass criteria, status semantics, evidence schema, and explicit exclusions. It does not run a device, sign/notarize/publish an archive, or choose testers. The separate final-release execution and approval track owns final-artifact execution, human approval, immutable publication, post-publication download verification, and narrowing or stopping the claim when a row is missing or fails. `docs/DISTRIBUTION.md` remains the operational release checklist; `docs/HEADLESS.md` supplies the LaunchAgent and route behavior to exercise.

Sources: [CONTEXT.md](../../CONTEXT.md), [README.md](../../README.md), [STATUS.md](../STATUS.md), [DISTRIBUTION.md](../DISTRIBUTION.md), [HEADLESS.md](../HEADLESS.md), and the [public-release maintenance contract](../research/public-release-maintenance-contract.md), together with the Wayfinder map and its release-decision tickets.
