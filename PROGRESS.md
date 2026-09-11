# Bagel — Progress Notes

Last updated: 2026-09-11, end of session. **CI is green** (run [34614773388](https://github.com/dennisecc/bagel_app/actions/runs/34614773388), commit `10292a6` — the app icon asset compiles clean through `ASSETCATALOG_COMPILER` and all tests still pass).

## What this is

Native SwiftUI iOS app (no React Native/Flutter — explicit decision) that turns a
photographed/scanned receipt or bank statement into itemized, split expenses:
capture → OCR → LLM structuring → assign each line item to people → categorize →
compute who paid / who owes whom → surface spending insights. Local-only, no
accounts/backend — people are simple named contacts, balances computed on-device.

Repo: **https://github.com/dennisecc/bagel_app** (public)

## Why CI exists at all

This machine (Intel MacBookPro15,2, macOS 15.7.9) **cannot run a current Xcode** —
Apple's latest Xcode requires Apple Silicon, and the App Store has no way to get an
older one. So there is no local compiler. Every commit is verified by GitHub Actions
instead (`.github/workflows/ios-ci.yml`, a `macos-15` runner with real Xcode
preinstalled). **Always push and check the Actions tab — never assume code compiles
just because it "looks right."** See `README`-less context below for exactly how to
check a run without `gh` installed (it isn't — brew install failed on this machine
due to outdated Command Line Tools; not worth fighting further).

### Checking CI status without `gh`
```
WebFetch https://api.github.com/repos/dennisecc/bagel_app/actions/runs?per_page=1&_cb=<random>
```
(the `_cb` cache-buster matters — WebFetch caches for 15 min otherwise). Get
`jobs_url` from the run, fetch that for the step-by-step breakdown. **Raw log
downloads return 403 without auth** — when a step fails and you need the actual
`error:` text, ask the user to open the run, click the gear icon → "View raw logs"
on the failing step, and paste the relevant lines (search "error:" or "BUILD
FAILED"). Don't guess blindly from the generic "Process completed with exit code
70" wrapper line — that's meaningless on its own.

## Architecture

- `BagelCore/` — local Swift Package, pure logic, dependency-free, unit-tested via
  plain `swift test` (no simulator needed): `SplitCalculator` (equal/percentage/
  exact-amount splitting, penny-accurate remainder distribution), `DebtSimplifier`
  (Splitwise-style greedy min-cash-flow settlement), `InsightsAggregator` (category
  totals, trends, MoM deltas, spike detection).
- `BagelApp/` — the app target. SwiftData models (`Person`, `ExpenseCategory`,
  `ExpenseDocument`, `LineItem`, `ItemAssignment`), all Features/ views, and Services
  (OCR, LLM, Persistence).
- `BagelAppTests/` — XCTest target, `@testable import BagelApp`.
- `project.yml` — XcodeGen spec, source of truth. Run `xcodegen generate` after any
  change to it or after adding/removing files (though CI does this itself too).

## Build phases — status

| Phase | What | Status |
|---|---|---|
| 0 | Scaffold, SwiftData container, seeding | ✅ Done |
| 1 | People & Categories CRUD | ✅ Done |
| 2–4 | Capture (VisionKit scan + PhotosPicker) → Vision OCR → Claude tool-use parsing → persisted `ExpenseDocument`/`LineItem` | ✅ Done |
| 5 | Assignment UI (`ItemListView`, `AssignPeopleSheet`, category picker, bulk "assign all"/"split evenly") | ✅ Done |
| 6 | Settlement (`BalancesView`, `DebtSimplifier`) | ✅ Done (built early since data model supported it cheaply) |
| 7 | Expense history browse/edit/delete | ✅ Done (`ExpenseListView` swipe-delete, `EditExpenseDetailsSheet`, line-item swipe-delete/add) |
| 8 | Insights dashboard (Swift Charts) | ✅ Basic version done early |
| 9 | Polish (empty states, accessibility, app icon) | ⚠️ Partial — see "Not done" below |

## Not done yet

- **App icon** — done this session. A white toy-poodle pixel/perler-bead-art icon
  (`AppIcon-1024.png`, generated with Pillow — see scratch script if it ever needs
  regenerating), styled after a Pinterest reference the user shared but recolored
  white on a light-blue canvas, with `Contents.json` pointing at it. Not yet seen
  rendered on an actual home screen/simulator.
- **Accessibility**: substantial pass done this session (see below) but still not
  verified with an actual VoiceOver run (no local device/simulator). Remaining gap:
  `ExpenseListView` row (merchant/date/total as three separate Text elements —
  minor, not broken, just not combined into one swipe stop).
- **Manual entry** line-item editing is minimal (add-only via `AddLineItemSheet`,
  no inline edit of an existing manually-entered item's amount/description — only
  category/assignment/delete).
- Never verified in an actual Simulator UI (no eyes on a running screen) — CI only
  proves it *compiles and unit tests pass*, not that the UI looks/behaves right.
  Once the user has any way to run it (see "Xcode access" below), a real
  interactive pass is still needed.

## Accessibility pass (2026-09-11 session)

Went through every view in `BagelApp/Features/` looking for VoiceOver gaps —
color/icon-only information, `.onTapGesture`-only controls (not exposed to VoiceOver
at all, unlike `Button`), and redundant/fragmented element reads. Fixed:

- `InsightsDashboardView`: per-mark `.accessibilityLabel`/`.accessibilityValue` on
  both the category `SectorMark` and the monthly `BarMark` chart, so VoiceOver users
  can swipe through individual chart data points (category name + amount, month +
  amount) instead of the chart being silent/opaque.
- `BalancesView`: net-balance rows previously conveyed "is owed" vs. "owes" by
  color alone (green/red). Added a combined accessibility element with an explicit
  `accessibilityValue` ("Is owed $X" / "Owes $X").
- `PeopleListView` / `ManageCategoriesView` row views: decorative avatar circle /
  category icon now `.accessibilityHidden`, row combined into one VoiceOver element
  via `.accessibilityElement(children: .combine)`. The "default category" lock icon
  in `ManageCategoriesView` got an explicit label instead of being silently dropped.
- `CategoryEditView`: the icon grid was **not accessible at all** — it used
  `.onTapGesture` on a bare `Image`, which VoiceOver doesn't expose as an
  interactive element. Converted to `Button` + `accessibilityLabel` (per-icon plain-
  English name) + `.isSelected` trait. The color palette `Picker(.palette)` swatches
  were unlabeled circles; added `accessibilityLabel` naming each color.
- `PersonEditView`: same color-palette-swatch fix as above (different palette/hex
  set, separate name mapping).
- `CategoryPickerSheet` / `AssignPeopleSheet`: selection checkmarks were bare
  `Image(systemName: "checkmark")` relying on symbol-name label synthesis (unreliable).
  Hid them from the accessibility tree and added an explicit `.isSelected` trait on
  the row `Button` instead.

**Not verified with real VoiceOver** — no local device/simulator on this machine
(see "Xcode access" below). These are standard, well-documented SwiftUI accessibility
APIs used in the idiomatic way, and CI (compile + unit tests) will catch any build
errors, but only an actual VoiceOver walkthrough would catch behavioral surprises.

## Real bugs CI caught (all fixed, all pushed)

These only surfaced because this was the **first time any real Swift compiler ever
touched this code** — the previous session (before CI existed) had zero compiler
feedback at all.

1. **Simulator destination bug in the CI workflow itself** (not app code): a greedy
   `sed` regex extracted a device name like `iPhone 16 Pro (UUID)` instead of
   `iPhone 16 Pro`. Fixed by parsing `xcrun simctl list devices available -j` as
   JSON via `python3` instead of regexing human-readable text.
2. **`@MainActor` isolation error**: `ModelContainerFactory.makeContainer()` (and
   several test files) accessed `container.mainContext`, which is `@MainActor`-only,
   from plain nonisolated contexts. Fixed by using `ModelContext(container)` instead
   (a plain, non-isolated context bound to the same store) everywhere except the one
   `#Preview` block in `ItemListView.swift`, where `.mainContext` is fine because
   `#Preview` closures are already `@MainActor`-isolated.
3. **`Category` vs `objc/runtime.h`'s `Category` typedef**: naming our model type
   exactly `Category` silently worked inside `BagelApp`'s own files (local
   declaration wins there) but became genuinely ambiguous inside `BagelAppTests`
   once `@testable import BagelApp` brought both names into the same scope. Fixed
   by renaming the model to `ExpenseCategory` everywhere (11 files) — user-facing
   strings like "Category" in the UI were left untouched, only the Swift type
   symbol changed.

**Takeaway for next session**: don't assume "no compiler errors reported" means
clean — always check the Actions run after pushing. There could easily be more
latent issues in code that hasn't been exercised by a real build yet (e.g. Insights
charts, the OCR/VisionKit representable, anything not covered by a unit test).

## Xcode access (unresolved, revisit if it matters)

This machine can't install current Xcode (Apple Silicon–only now). Options
discussed but not pursued further:
- An older Xcode (15.x/16.0) from developer.apple.com/download (free Apple ID,
  no $99/year program needed) would still support macOS Sequoia + iOS 17 SDK and
  give back full local Simulator/debugging — untried.
- CI build + sideload to a real iPhone via Sideloadly/AltStore (free, ad-hoc
  7-day resign cycle) — untried, would let the user actually use the app on a
  device without any Mac purchase.
- Pivoting off native Swift entirely (Expo/React Native) — explicitly rejected
  earlier, would throw away all current work. Only reconsider as an absolute
  last resort.

## Security note

A GitHub Personal Access Token was pasted in plaintext into chat during setup to
authenticate the first `git push`. **Confirm it was revoked** at
https://github.com/settings/tokens — a new one should be generated if further
token-based auth is ever needed (current pushes work via the `osxkeychain`
credential helper, which cached the credential after the first successful push, so
a token shouldn't be needed again for normal `git push`/`git pull`).

## Environment notes

- `git` identity for this repo (local, not global): `Dennise C` /
  `dennisepatriciacruz@gmail.com`.
- `credential.helper` is set to `osxkeychain` globally on this machine.
- `gh` CLI is **not installed** (brew install failed — outdated Command Line
  Tools trying to build a `go` dependency from source). Not worth retrying unless
  CLT gets updated some other way; API access via `WebFetch` on `api.github.com`
  has worked fine for public-repo read operations (runs/jobs), just not log
  downloads (403 without auth).
- `Secrets.xcconfig` (real, gitignored) holds a placeholder
  `ANTHROPIC_API_KEY = your-api-key-here` — **not a real key**. Anthropic API
  calls have never actually been exercised end-to-end (all LLM tests use a mocked
  `URLProtocol`); a real key would be needed to test the live capture pipeline.

## Suggested next steps, in rough priority order

1. If the user got any form of Xcode access over the break, do a real interactive
   Simulator pass with VoiceOver on — this is the first time anyone (human or CI)
   has looked at the actual UI rendering or heard the accessibility changes above.
   (CI confirms it compiles and unit tests pass — run 34611308691, commit `390526c`
   — but not that VoiceOver actually reads it the way it's intended to.)
2. Add a real Anthropic API key to `Secrets.xcconfig` locally (never commit it) and
   test the live capture → OCR → LLM pipeline end-to-end with a real photo.
3. App icon.
4. Consider adding the CI-build-and-sideload path if the user wants the app on
   their actual phone before any of the above.
