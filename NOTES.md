# NOTES · build log for the Stable Date demo repo

Built by Claude (Opus 5.5) in Xcode 27.0 (27A266a) on 20 Oct 2026, following `docs/DIRECTION.md`.
Nothing is pushed. Simulator used for every check: iPhone 18 Pro, iOS 27.0.

## Numbers for the slides

| What | Number |
|---|---|
| `step-0-spaghetti`: `wc -l stable-date/SwipeView.swift` | **418** |
| `step-4-tested`: Swift lines in the app target (18 files) | 844 |
| `step-4-tested`: biggest file | `MatchOverlayView.swift`, 115 lines |
| `step-4-tested`: `SwipeView.swift` | 64 lines (including the 4 previews) |
| `step-4-tested`: `SwipeViewModel.swift` | 48 lines |
| Tests | 8 (`step-4-tested`), 9 (`demo/super-like`); the whole suite runs in < 0.1 s |
| `demo/super-like` diff vs `step-4-tested` | 4 files, +34 / −5 |

The AI-moment numbers (files read, context tokens, files changed) are not measured here; WALKTHROUGH §4 says Reva measures them on fresh sessions.

## Judgment calls

1. **Build settings went through Xcode's build-setting tool** (Swift 6, iOS 17, iPhone only, portrait, `nonisolated`, bundle id, display name), for both targets. Two settings had to go into `project.pbxproj` by hand, because the tool rejects `ASSETCATALOG_COMPILER_APPICON_NAME` ("unknown build setting" in Xcode 27) and can't scope a setting to one configuration (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, Release only). I tried to ask first, but the question tool timed out; DIRECTION §1.1 allows the edit. That is 3 added lines, and `xcodebuild -list` still works. Afterwards Xcode re-sorted the keys; the sorted file is what's in the base commit.
2. **Test target settings fixed too.** It had Swift 5 and inherited iOS 27. Now: Swift 6, iOS 17, `nonisolated`, iPhone only. The template `StableDateTests.swift` became `SwipeViewModelTests.swift` with the placeholder from §1.2.
3. **Base commit = "chore: project settings, schemes, docs"** (amended twice while setting up; nothing was pushed). It also stops tracking `xcuserdata`. The template `MyApp.swift`/`ContentView.swift` are removed in `step-0-spaghetti`.
4. **`@State` in SDK 27 is a macro.** `SwipeView.init(viewModel:)` assigns `self.viewModel = viewModel` to a `@State` declared without an initial value, which is the documented pattern (Apple's SwiftUI 27 notes). Before step 3 it's `@State private var viewModel = SwipeViewModel()`.
5. **Preview-safe `SwipeView`.** On first render after a file change, Xcode 27's preview thunk failed on `Group { switch … }` ("ambiguous use of `__designTimeSelection`") and on passing the method reference `handleSwipe`. So the switch lives in a `@ViewBuilder private var screen` (still in `SwipeView.swift`, still exhaustive, same fix-it on stage), and `onSwipe:` takes a closure. The `MatchOverlayView` buttons use a small `ButtonStyle` for the same reason.
6. **The `.failed` line is one line in every tag** (`case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }`), exactly as typed on stage, so `step-2-state` → `step-4-tested` doesn't reformat it.
7. **`MatchOverlayView` arrives at `step-2-wip`** together with the other extracted views. DIRECTION's table doesn't list it, but D4 needs it and it's in the final layout. Steps 0–1 keep the match screen inline (with the hand-rolled confetti `Canvas`).
8. **Previews that need `Horse.samples`** (card, deck, match, profile) appear at `step-3-fake-horses`, when the samples exist. Before that only sample-free previews exist (loading, empty, error, header, tab bar). Step 0 and step 1 keep the one network-hitting `#Preview { SwipeView() }`.
9. **Extra `Copy` keys** beyond PRD §4, for accessibility labels of decorative controls: `backLabel` "Back", `filterLabel` "Filters", `messagesLabel` "Messages", `profileLabel` "Profile". The ♥ tab uses `matchesBadge(_:)` ("1 matches", as written in the PRD). `matchBody(name:)` returns Markdown (`**name**`) so the name is bold, as in the mockup.
10. **Cards render in light mode in both appearances** (`.environment(\.colorScheme, .light)` on the card and the match screen). The gradient is `ink` at 70 %, and `ink` turns light in dark mode, which would make white text unreadable.
11. **Profile sheet**: card + "7 years · Thoroughbred" + bio + "Looking for". The name isn't repeated under the card.
12. **Haptics** use `.sensoryFeedback(.impact(weight: .medium), trigger:)` (iOS 17) from step 2 on; steps 0–1 call `UIImpactFeedbackGenerator` inline (it's spaghetti).
13. **Scripts.** The simulator is the newest "iPhone NN Pro" (`sort | tail -1`, not `grep -m1`): several runtimes have an "iPhone 16 Pro", which makes `name=` ambiguous. Warnings are counted as compiler diagnostics only (`^/path: warning:`), because `appintentsmetadataprocessor` prints a harmless "warning:" log line on every build. Tests run with `-parallel-testing-enabled NO` so the Swift Testing summary line is printed. `verify-tags.sh` runs from a temp copy because `scripts/` doesn't exist in older tags, and it refuses to run with local changes.
14. **Owner is `revaprasetya`** (21 Oct): replaced in every tag (`SwipeView.swift` at step 0, `LiveHorseService.swift` from step 1) and in the **Empty** scheme by rewriting the tags (`git filter-branch`, docs untouched). Live and Empty only load once the repo is pushed; until then they show the error screen (step 0: the spinner). I tested the network path with `STABLE_DATE_URL` set to `https://horses.invalid/…` (error) and to `data:` URLs (step 0: data and `[]`), and the UI with the `--mock-*` launch arguments.
15. **Stage tip:** after `git checkout -f <tag>`, press ⌘B once before opening the canvas. Xcode's preview canvas can show stale previews right after a checkout.

## What Reva must do by hand

1. Create the public GitHub repo `revaprasetya/stable-date` (empty: no README, no license) and add it: `git remote add origin git@github.com:revaprasetya/stable-date.git`.
2. Push: `git push -u origin main --tags demo/super-like`, then check that `https://raw.githubusercontent.com/revaprasetya/stable-date/main/Data/horses.json` returns 200 and that **Live** shows Sir Gallops-a-Lot and **Empty** shows "No horses nearby."
3. Clone fresh into another folder and run `bash scripts/verify-tags.sh` there.
4. Before recording: walk WALKTHROUGH.md once with a timer, using the **Live** scheme with the real URL. (Not done here: no URL yet.)
5. Measure the AI moment (WALKTHROUGH §4) and fill the six `[__]`, the line count (418), the repo link and the QR in the deck.
6. Optional: `docs/spaghetti.png` (ref 05 Phase 6) and `docs/previews.png` need an editor window screenshot. They're not in DIRECTION's definition of done, so I left them out.

## Definition of done

```
[x] scripts/verify-tags.sh → all ✓ (output below)
[x] scripts/check-rules.sh at step-4-tested → all ✓ (output below)
[x] ⌘U at step-4-tested → 8 tests, 0 failures
[x] Break-it check: guard horse.likesYouBack → only nopingNeverMatches fails (2 issues: !isMatch, matches.isEmpty)
[x] git diff step-4-tested work/final → empty for the app and test code; work/final deleted
[x] demo/super-like builds, 9 tests green
[x] Each live-typing contract in §5 tried once on a scratch checkout and works as described
      step-1-wip: .task { await viewModel.load() } → builds
      step-2-wip: 1 error "switch must be exhaustive"; typed .failed line → builds
      step-3-wip: init(service:) → 1 error in StableDateApp.swift "missing argument for parameter 'service' in call"; typed argument → builds
      step-3-fake-horses: the four SwipeView previews render (Loaded, Empty, Error, Loading)
      step-4-tested: see break-it check
[x] step-0: three bugs reproduced (spinner forever with the Offline URL; header + tab bar and nothing between on []; ✕ on Sir Gallops-a-Lot → match)
[x] docs/screenshots/{loading,loaded,empty,failed,match,profile}.png
[x] NOTES.md: line count of step-0 SwipeView.swift, every judgment call, everything Reva must do by hand
[x] README tag table and cheat sheet still true (unchanged, D8)
```

Also checked in the Simulator at the final version: profile sheet, ♥ → match → badge 1, ✕ and ★ with no match, swiping all 10 → "You've seen every horse." → **Start over** reloads, a fast double tap removes one card, Offline → error → **Try again** → error, and VoiceOver sees only the match screen while it's up.

### scripts/verify-tags.sh

```
Simulator: iPhone 18 Pro
✓ step-0-spaghetti builds
✓ step-1-wip builds
✓ step-1-split builds
✓ step-2-wip fails exactly as intended (1 error: switch must be exhaustive)
✓ step-2-state builds
✓ step-3-wip builds
✓ step-3-fake-horses builds
✓ step-4-tested builds
✓ step-4-tested: ✔ Test run with 8 tests in 1 suite passed after 0.005 seconds.
✓ demo/super-like: ✔ Test run with 9 tests in 1 suite passed after 0.003 seconds.
```

### scripts/check-rules.sh (at step-4-tested)

```
✓ Views/ViewModels never touch networking
✓ ViewModel doesn't import SwiftUI
✓ ViewModel doesn't name the real service
✓ ViewModel has no parallel state flags
✓ Services/Models don't know about UI
✓ only StableDateApp constructs LiveHorseService
✓ no long string literals in Views (all in Copy)
```
