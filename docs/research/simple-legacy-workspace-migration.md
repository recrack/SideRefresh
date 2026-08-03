# Simple and Legacy workspace migration contract

This document resolves how the Simple workspace and Legacy workspace coexist
inside one SideRefresh app, where their shared presentation seam lives, and what
must be observable before the Legacy workspace can be deleted.

It complements the
[Legacy workspace parity inventory](legacy-workspace-parity-inventory.md).
Production implementation remains outside this Wayfinder decision.

## Resolved contract

| Concern | Decision |
| --- | --- |
| Product | One SideRefresh app; no separate Simple app and no permanent mode switch |
| Default | Every app launch opens the Simple workspace |
| Fallback | `Help → Open Legacy Workspace` opens the Legacy workspace for the current app session only |
| Persistence | Legacy selection is never stored in `UserDefaults` or configuration |
| Shared seam | Simple, Legacy, and menu-bar adapters read one Renewal presentation |
| Mutation | Both workspaces keep using the same `SideRefreshViewModel` commands, confirmations, and underlying renewal engine |
| Compatibility | Existing unrecognized custom-command configurations receive an isolated read/disable/migrate surface; they do not keep the Legacy workspace alive |
| Removal | Legacy remains through at least one stable release with Simple as the default, then is deleted only when every removal gate passes |

## Why a seam is required

`SideRefreshViewModel` and `SideRefreshCore` already own most configuration,
execution, scheduling, receipt, and safety behavior. However,
`SideRefreshApp.swift` currently derives readiness and action precedence inside
the Legacy SwiftUI hierarchy. The menu-bar surface also derives a smaller
presentation independently.

Copying those branches into a new Simple view would create two implementations
of the product rules. The Legacy view could then be visually deleted while its
policy survived as duplicated branches in the Simple workspace and menu bar.
That would fail the migration's deletion test.

The migration therefore introduces one stable interface:

```text
saved configuration ─┐
live agent state ─────┤
renewal evidence ─────┼─> Renewal presentation resolver
current run ──────────┤            │
compatibility state ──┘            ├─> Simple workspace
                                   ├─> Legacy workspace
                                   └─> menu bar
```

## Renewal presentation interface

The Renewal presentation is a read-only, deterministic value. At minimum it
contains:

- the highest-priority Renewal condition;
- zero or one Next action;
- the selected app-to-iPhone relationship;
- Last verified evidence and its verification time;
- current renewal progress;
- the most recent result;
- the availability of secondary setup, settings, diagnostics, and system
  handoffs.

The resolver owns condition and action precedence. A SwiftUI view may select
layout, labels, disclosure, and accessibility behavior, but it must not
recalculate whether renewal is healthy, due, blocked, or failed, or choose a
different Next action.

The implementation should begin in the app presentation layer, close to
`SideRefreshViewModel`, because these semantics combine app-only state such as
background-service approval with `SideRefreshCore` values. Do not move AppKit,
SwiftUI, or `ServiceManagement` concepts into `SideRefreshCore`.

Use a concrete value and deterministic resolver before introducing a protocol.
There are already three real adapters—Simple, Legacy, and menu bar—so the value
is a real interface and its state table is a real test surface. A protocol is
only justified later if a second resolver implementation appears.

All mutations continue through the existing view-model commands and renewal
engine. The semantic Next action routes through one workspace coordinator so
Simple and menu-bar entry points do not independently map the same action to
different commands or confirmations.

## Coexistence behavior

The Simple workspace owns the primary app window from the first migration
release. The Legacy workspace is a temporary recovery surface, not a preference:

1. Launching or relaunching SideRefresh opens Simple.
2. The Help menu exposes `Open Legacy Workspace`.
3. Opening Legacy changes only current-session navigation state.
4. Returning to Simple is always available without restarting the app.
5. No onboarding prompt, settings toggle, command-line option, or persisted
   default advertises a two-mode product.
6. New capabilities and product rules are implemented for Simple and the shared
   seam, not added only to Legacy.

The same `SideRefreshViewModel` instance remains alive while switching
workspaces. A switch must not reload configuration, interrupt a renewal, clear a
failure, discard Last verified evidence, or change background automation.

## Custom-command compatibility

An existing configuration whose command is not recognized as the bundled guided
iOS-renewal helper is preserved rather than silently rewritten, deleted, or
disabled.

For that configuration:

- Simple shows a migration-required Renewal condition.
- `Migrate to guided setup` is the Next action.
- Advanced diagnostics exposes the current executable and arguments read-only.
- The user can disable existing background automation.
- Saving guided setup replaces the compatibility configuration only after the
  existing confirmation and validation path succeeds.
- Release builds do not create or edit arbitrary custom commands.

This compatibility surface is isolated from the Legacy four-section view. It
may outlive the Legacy workspace until a separate compatibility sunset is
decided, so the presence of an old configuration alone does not fail a Legacy
removal gate.

## Removal gates

Legacy code can be removed only when all gates below pass. Passing a date or
shipping a version is not sufficient.

| Gate | Required evidence |
| --- | --- |
| Stable exposure | At least one stable release shipped with Simple as the default and the Help-menu Legacy fallback available |
| Resolver coverage | Every supported `Renewal condition → Next action` combination, including precedence conflicts and no-action Healthy renewal, passes deterministic automated tests |
| Lifecycle acceptance | First setup and install, manual renewal, background renewal, dirty-target save, and automation enable/disable scenarios pass against the Simple workspace |
| Failure recovery | Connection, build, signing/profile, install, unverified-install, permission, and unknown failures preserve Last verified evidence and expose the intended recovery route |
| Surface parity | Setup, Settings, confirmations, system handoffs, Advanced diagnostics, log copy/export, and menu-bar flows have an owner and no capability remains reachable only from Legacy |
| Release blockers | The release acceptance record has no `Legacy-only` row and no unresolved release-blocking Simple-workspace bug |

If any gate fails, the Help-menu fallback remains for the next release. The
team fixes the shared resolver or destination surface rather than adding a new
Legacy-only branch.

Usage volume, elapsed time, or a lack of reported issues cannot replace the
evidence above. A small open-source user base may produce no feedback while a
critical path is still broken.

## Deletion test

The removal change must be able to delete:

- `SideRefreshWorkspaceSection`;
- the four-section `NavigationSplitView`;
- Legacy-only cards and navigation state;
- the Help-menu Legacy entry and current-session fallback state;
- Legacy-specific snapshots or UI tests.

It must not need to:

- recreate readiness or action precedence in the Simple workspace;
- alter `SideRefreshCore` scheduling, validation, or execution rules;
- replace `SideRefreshViewModel` mutation commands;
- remove custom-command read/disable/migrate compatibility;
- change persisted user configuration or Last verified evidence.

After deletion, the Renewal presentation resolver tests and Simple acceptance
matrix remain unchanged and passing. That is the observable proof that Legacy
was an adapter rather than a second product implementation.
