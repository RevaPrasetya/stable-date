# Stable Date · Build Direction (for coding agents)
Version 1.0 · 20 Oct 2026 · Owner: Reva Prasetya · Deadline: every tag frozen by **Thu 22 Oct 2026**, rehearsal 23 Oct, talk Sat 24 Oct

This file tells a coding agent (Claude Agent / Codex in Xcode 27, or Claude Code in a terminal) how to turn this empty Xcode project into the demo repo used on stage.

**Precedence when documents disagree:** this file › [`PRD.md`](PRD.md) › [`WALKTHROUGH.md`](WALKTHROUGH.md) › [`reference/`](reference/). The reference docs were written for an older plan (Xcode 16, a repo called `stable-date-ios`, a project called `StableDate`). Use them for the full source code and the reasoning; use this file for names, paths, settings and every decision listed in §3.

If something here is contradictory, make the smallest reasonable call, write it in `NOTES.md` (one line: decision, reason) and keep going. Ask Reva only when a decision can't be undone.

---

## 0. Order of work (TL;DR)

1. **Check the scaffold** (§1). If the `StableDateTests` target doesn't exist yet, stop and ask Reva to add it (§1.2). Don't hand-edit `project.pbxproj` to add a target.
2. **Fix project settings** (§1.1), add `.gitignore`, stop tracking `xcuserdata`, add the three shared schemes (§7). Commit as `chore: project settings, schemes, docs`. This commit is the base for every tag.
3. **Build the final version first** on branch `work/final` (§4, §6, source in `reference/05-…` §4 with the overrides in §3). Build, ⌘U, previews.
4. **Create the history forward on `main`**, one commit and one tag per step (§5). Copy unchanged files from `work/final`.
5. **Branch `demo/super-like`** off `step-4-tested` (§9).
6. **Scripts, README, NOTES** (§8, §10). Run `scripts/verify-tags.sh` and `scripts/check-rules.sh`, paste the output into `NOTES.md`.
7. Don't push. Reva pushes (§11).

---

## 1. The project as it exists, and what to change

Reva created the project with Xcode 27 (`stable-date.xcodeproj`, one commit "Initial Commit"). Current state:

| Thing | Now | Required |
|---|---|---|
| Target / scheme | `stable-date` | Keep the name. The module is `stable_date`, so tests use `@testable import stable_date`. |
| Source folder | `stable-date/` (synchronized root group, objectVersion 90) | Keep. Every file put in a subfolder of `stable-date/` is compiled automatically; never add file references by hand. |
| Files | `MyApp.swift` (`struct MyApp`), `ContentView.swift` (`#Preview`, `#Playground`, `import Playgrounds`) | Delete `ContentView.swift`. Replace `MyApp.swift` with `stable-date/App/StableDateApp.swift` (`struct StableDateApp`). |
| `IPHONEOS_DEPLOYMENT_TARGET` | 27.0 | **17.0** |
| `SUPPORTED_PLATFORMS` / `TARGETED_DEVICE_FAMILY` | iOS + macOS + visionOS / `1,2,7` | `iphoneos iphonesimulator` / `1` (iPhone only). Remove the macOS/visionOS deployment targets from the target. |
| Orientation | portrait + landscape | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait` |
| `SWIFT_VERSION` | 5.0 | **6.0** (Swift 6 language mode = strict concurrency) |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | **`nonisolated`** (decision D1) |
| `SWIFT_APPROACHABLE_CONCURRENCY` | YES | Keep YES. |
| Warnings | default | `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` for **Release** only |
| Bundle id | `devplaceholder.…` | `com.revaprasetya.stabledate`, keep `DEVELOPMENT_TEAM` as is |
| Display name | none | `INFOPLIST_KEY_CFBundleDisplayName = "Stable Date"` |
| App icon | no setting | `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` (the `AppIcon` set is already in the catalog) |
| Assets | was `AccentColor` only | **Already added (20 Oct):** `AccentColor` = rose, 12 color sets (`Rose`, `Blush`, `Plum`, `Lavender`, `LavenderSoft`, `Ink`, `InkSecondary`, `AppBackground`, `PhotoPink`, `PhotoLavender`, `PhotoMint`, `PhotoPeach`), `horse-01…10`, `AppIcon`. Don't regenerate placeholders. |
| `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` | YES | Keep. Use the generated symbols (`Color.rose`, `Color.ink`, …). **Do not** write the `Theme.swift` from `reference/05` §4.3; it would redeclare them. |
| `.gitignore` | none, `xcuserdata/` is tracked | Add `.gitignore` (`xcuserdata/`, `DerivedData/`, `build/`, `*.xcuserstate`, `.DS_Store`) and `git rm -r --cached stable-date.xcodeproj/xcuserdata`. |
| Test target | none | `StableDateTests` (Swift Testing), see §1.2 |

### 1.1 How to change the settings
Edit the build settings of the `stable-date` target in `project.pbxproj` (both Debug and Release), or ask Reva to do it in the target's Build Settings tab if your tool can't. After editing, `xcodebuild -list -project stable-date.xcodeproj` must still work.

### 1.2 Test target (Reva does this in Xcode, ~1 minute)
File → New → Target… → **Unit Testing Bundle** → Product Name `StableDateTests`, Testing System **Swift Testing**, Target to be Tested `stable-date`. Then set its deployment target to iOS 17.0, Swift 6, default actor isolation `nonisolated`, same as the app.

Xcode creates a synchronized folder `StableDateTests/`. Until tag `step-4-tested` the only file in it is `StableDateTests/SwipeViewModelTests.swift` containing exactly:

```swift
import Testing

// Tests arrive in step 4.
```

This keeps every tag building with the test target present (an empty synchronized folder isn't tracked by git).

---

## 2. Name mapping (reference docs → this repo)

| In `reference/` | In this repo |
|---|---|
| repo `stable-date-ios`, `~/dev/stable-date-ios/` | repo `stable-date`, folder `Talks/Swift 24 Oct 26/stable-date/` |
| `StableDate/…` source paths | `stable-date/…` (e.g. `stable-date/Features/Swipe/SwipeView.swift`) |
| scheme `StableDate` | schemes `Live`, `Offline`, `Empty` (§7); the auto scheme `stable-date` may stay |
| `@testable import StableDate` | `@testable import stable_date` |
| `StableDate.app`, bundle `com.revaprasetya.Stable Date` | `stable-date.app`, bundle `com.revaprasetya.stabledate` |
| Xcode 16, "iPhone 16 Pro" | Xcode 27, first available iPhone simulator (scripts detect it, §8) |
| `App/Theme.swift` | not used; generated asset symbols |
| Network Link Conditioner / editing the URL | never; use the schemes |
| 7 tests | 8 tests (§6) |
| `Data/horses.json` as a test bundle resource | read from disk via `#filePath` (§6) |

Type names stay as in the reference: `StableDateApp`, `Horse`, `HorseService`, `LiveHorseService`, `MockHorseService`, `SwipeViewModel`, `SwipeView`, `CardStackView`, `HorseCardView`, `LoadingView`, `EmptyDeckView`, `ErrorView`, `MatchOverlayView`, `HorseProfileView`, `Copy`.

---

## 3. Decisions that override the reference docs

**D1 · Concurrency.** Swift 6 language mode, default actor isolation `nonisolated`. That's the setting the slides describe ("Swift 6 language mode, strict concurrency, tanpa default main actor"), and it lets the reference source compile as written: `SwipeViewModel` is `@MainActor @Observable`, the test suite is `@MainActor`, `Horse` and the services are `Sendable` structs. Don't add actors or `nonisolated` annotations beyond what the compiler asks for. Zero warnings.

**D2 · URL override in every tag.** From `step-0-spaghetti` to `step-4-tested`, the horses URL is computed like this (inline in `SwipeView.swift` at step 0, in `LiveHorseService` from step 1 on):

```swift
static var defaultURL: URL {
    #if DEBUG
    if let override = ProcessInfo.processInfo.environment["STABLE_DATE_URL"],
       let url = URL(string: override) {
        return url
    }
    #endif
    return URL(string: "https://raw.githubusercontent.com/<owner>/stable-date/main/Data/horses.json")!
}
```

`<owner>` stays a placeholder until Reva tells you the GitHub owner (§11). Note it in `NOTES.md`.

The `--mock-loaded / --mock-empty / --mock-failed / --mock-loading` launch arguments from `reference/05` §4.1 exist **only at `step-4-tested`** (inside `makeService()`) and are used by `scripts/screenshots.sh`.

**D3 · ★ Super like button.** The ★ button is visible in every tag (the slides show ✕ ★ ♥). On the main tags it calls the same path as ♥: `swipe(horse, liked: true)`. The branch `demo/super-like` turns it into a real super like (§9).

**D4 · UI follows PRD §6 and `docs/assets/mockups/`.** That means: custom `DiscoverHeader` instead of `navigationTitle`, vertical ✕ ★ ♥ buttons on the card's lower right, decorative `StableTabBar` with the matches badge on the ♥ tab (replaces the toolbar `MatchesBadge` from `reference/05` §4.10), the match screen with two tilted photos, "CONGRATULATIONS", "It's a match!!", **Say hello** and **Keep trotting**. Add `Features/Swipe/DiscoverHeader.swift` and `Features/Swipe/StableTabBar.swift` (one type per file). `SwipeView` lays out `VStack(spacing: 0) { DiscoverHeader(); <switch>; StableTabBar(matchCount:) }` on `Color.appBackground`. The header and tab bar are visible in all four states.

**D5 · Copy.** PRD §4 is final, including the double "!!" in `matchTitle` and the new keys (`discoverTitle`, `discoverLocation`, `matchCaption`, `sayHelloButton`, `superLikeLabel`, `distance(_:)`, `matchPercent(_:)`). `Copy.swift` appears only at `step-4-tested`; before that the views use identical literals.

**D6 · Assets are done.** Horses, app icon and colors are in `Assets.xcassets` already. Don't write `scripts/placeholders.py`. `CREDITS.md` says: "All horse art and the app icon are original drawings made for this talk. Free to reuse for learning."

**D7 · Tests.** Eight tests on `SwipeViewModel` (§6). The suite is `@MainActor`. `samplesMatchJSON` reads `Data/horses.json` from disk; no bundle resource.

**D8 · Docs live in every tag.** `README.md`, `AGENTS.md`, `CLAUDE.md` and `docs/` are committed in the base commit, so every tag has them. Don't change them per tag.

**D9 · No Network Link Conditioner, no Wi-Fi toggling, no URL edits during the demo.** Both cut Webex. Offline and empty are scheme switches + ⌃⌘R.

---

## 4. Final folder layout (tag `step-4-tested`)

```
stable-date/                              ← repo root
├── README.md · AGENTS.md · CLAUDE.md · CREDITS.md · NOTES.md · .gitignore
├── Data/
│   ├── horses.json                       ← served raw from GitHub (the "live" source)
│   └── horses-empty.json                 ← []
├── docs/  (PRD, DIRECTION, WALKTHROUGH, assets/, reference/)
├── scripts/  verify-tags.sh · check-rules.sh · screenshots.sh
├── stable-date.xcodeproj/
│   └── xcshareddata/xcschemes/  Live.xcscheme · Offline.xcscheme · Empty.xcscheme
├── stable-date/
│   ├── App/
│   │   ├── StableDateApp.swift           ← @main, composition root, the only `LiveHorseService()`
│   │   └── Copy.swift                    ← every user-facing string
│   ├── Models/
│   │   ├── Horse.swift
│   │   └── Horse+Samples.swift
│   ├── Services/
│   │   ├── HorseService.swift            ← the promise (protocol)
│   │   ├── LiveHorseService.swift        ← URLSession + JSONDecoder + D2 URL
│   │   └── MockHorseService.swift        ← test double, app target (previews need it)
│   ├── Features/
│   │   ├── Swipe/
│   │   │   ├── SwipeViewModel.swift
│   │   │   ├── SwipeView.swift
│   │   │   ├── DiscoverHeader.swift
│   │   │   ├── StableTabBar.swift
│   │   │   ├── CardStackView.swift
│   │   │   ├── HorseCardView.swift
│   │   │   ├── MatchOverlayView.swift
│   │   │   ├── EmptyDeckView.swift
│   │   │   ├── ErrorView.swift
│   │   │   └── LoadingView.swift
│   │   └── Profile/
│   │       └── HorseProfileView.swift
│   └── Assets.xcassets
└── StableDateTests/
    └── SwipeViewModelTests.swift
```

The step-1 slide shows this tree (App, Models, Services, Features/Swipe, Features/Profile). Keep the folder names exactly.

---

## 5. Tags (built forward on `main`, one commit each)

Commit message: `<tag>: <one line the audience should notice>`. Every tag must build with the **Live** scheme, except `step-2-wip`, which must fail with **exactly one** error containing "exhaustive". Each tag must also run: `step-0` through `step-3-fake-horses` show the same UI as the final app (header, card, ✕ ★ ♥, tab bar, match screen, profile sheet); only the structure and the bugs differ.

| Tag | Files (under `stable-date/`) | What changed | Bugs present | Live-typing contract on stage |
|---|---|---|---|---|
| `step-0-spaghetti` | `App/StableDateApp.swift` (`SwipeView()`), `SwipeView.swift` (300–500 lines, at the root of `stable-date/`) | Everything in one View (§5.1) | 1 spinner forever · 2 blank on `[]` · 3 ✕ still matches | none (reproduce the bugs) |
| `step-1-wip` | + `Models/Horse.swift`, `Services/LiveHorseService.swift` (no `: HorseService` yet), `Features/Swipe/SwipeViewModel.swift` (§5.2), `Features/Swipe/HorseCardView.swift`, `Features/Profile/HorseProfileView.swift`; `SwipeView.swift` moves to `Features/Swipe/` | New files exist and compile. `SwipeView` owns `@State private var viewModel = SwipeViewModel()` and **reads `viewModel.horses` / `viewModel.isLoading`**, but still has its **old `.task` networking block** (writing into `viewModel.horses` / `viewModel.isLoading`) and its **own `like()` / `nope()`** (the copy-paste, writing into its own `@State matches`). | 1 · 2 · 3 | Reva deletes the whole `.task { … }` networking block and types `.task { await viewModel.load() }`. ⌘R must build and the app must behave the same. |
| `step-1-split` | `Features/Swipe/SwipeView.swift` | The typed `.task` line, plus: `like()`/`nope()` and the View's own `matches` deleted, buttons call `viewModel.swipe(horse, liked:)`, overlay shows when it returns `true`. Rendering per `reference/05` §6.5 (no `errorMessage` check). | 1 (now a blank screen on failure, still a bug) · 2 | Reva checks this tag out after typing (`git checkout -f`). |
| `step-2-wip` | `SwipeViewModel.swift` (§5.3), `SwipeView.swift`, + `LoadingView`, `EmptyDeckView`, `ErrorView`, `CardStackView`, `DiscoverHeader`, `StableTabBar` | `State` enum replaces the three properties. `SwipeView` switches with `.loading`, `.loaded`, `.empty`; **no `.failed`** → one "Switch must be exhaustive" error. | n/a | Reva presses ⌘B, uses the fix-it, types `case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }`. ⌘B must succeed with nothing else changed. |
| `step-2-state` | `SwipeView.swift` | The `.failed` case, exactly as typed above. | none | |
| `step-3-wip` | + `Services/HorseService.swift`, `Services/MockHorseService.swift`, `Models/Horse+Samples.swift`; `LiveHorseService: HorseService`; `SwipeView` gets `init(viewModel:)`; `StableDateApp` = `SwipeView(viewModel: SwipeViewModel())`. ViewModel still has `private let service = LiveHorseService()`. No previews. | | none | Reva changes the ViewModel to `private let service: any HorseService` + `init(service: any HorseService) { self.service = service }`. ⌘B → exactly one error, in `StableDateApp.swift` ("Missing argument for parameter 'service'"). Reva types `SwipeViewModel(service: LiveHorseService())`. ⌘B succeeds. |
| `step-3-fake-horses` | `SwipeViewModel.swift`, `StableDateApp.swift`, `SwipeView.swift` | `init(service:)` as typed; composition root `SwipeView(viewModel: SwipeViewModel(service: LiveHorseService()))`; four `#Preview`s (Loaded, Empty, Error, Loading) with `MockHorseService`. | none | Reva opens the canvas (⌥⌘↩); all four previews render offline. |
| `step-4-tested` | + `App/Copy.swift`, final `StableDateApp.swift` with `makeService()`, `StableDateTests/SwipeViewModelTests.swift` (8 tests) | Strings move to `Copy`. This is `main`. | none | Reva breaks `guard liked, horse.likesYouBack` → `guard horse.likesYouBack`; ⌘U turns **only** `nopingNeverMatches` red; ⌘Z, ⌘U green. |

After tagging: `git diff step-4-tested work/final` must be empty (apart from files that only exist on `work/final` by mistake). Delete `work/final`. Tags are immutable once Reva records the backup videos.

### 5.1 `step-0-spaghetti` · `stable-date/SwipeView.swift`
Follow `reference/05` §5 (all ten points), plus:
- The UI of D4 inline: header, card with chips, vertical ✕ ★ ♥, tab bar with badge, match screen, profile sheet, all in this file. Copy-paste between the top card and the peeking cards is welcome.
- The URL from D2 as a computed property in this file.
- The two bug sites must read like the step-0 slide (Reva scrolls straight to them):

```swift
.task {
    guard let (data, _) = try? await URLSession.shared.data(from: Self.horsesURL),
          let decoded = try? JSONDecoder().decode([Horse].self, from: data)
    else { return }                       // Bug 1: isLoading stays true forever
    horses = decoded; isLoading = false   // [] → Bug 2: nothing to show, no empty screen
}

func like(_ horse: Horse) {
    horses.removeAll { $0.id == horse.id }
    if horse.likesYouBack { matches.append(horse); matchedName = horse.name; showMatch = true }
}

func nope(_ horse: Horse) {
    horses.removeAll { $0.id == horse.id }
    if horse.likesYouBack { matches.append(horse); matchedName = horse.name; showMatch = true } // copy-paste from like()
}
```

(No `// Bug` comments in the real file; the slide adds those. A `// TODO: fix later` and a `// don't touch this, it works` are required.)
- ★ calls `like(_:)`.
- One `#Preview` that hits the real network.
- Run it and confirm all three bugs: **Offline** scheme → spinner forever; **Empty** scheme → header + tab bar and nothing in between (compare `docs/assets/mockups/blank.png`); ✕ on Sir Gallops-a-Lot → match screen.
- Write `wc -l stable-date/SwipeView.swift` into `NOTES.md` under "Numbers for the slides".

### 5.2 `SwipeViewModel` at `step-1-wip` / `step-1-split`
`reference/05` §6.1, with `var horses` and `var isLoading` internal-settable (the step-1-wip View writes them from its old `.task`). `matches` stays `private(set)`; at `step-1-wip` the View keeps its own `@State matches`.

### 5.3 `SwipeViewModel` at `step-2-*` and `step-3-*`
`reference/05` §6.2 / §6.3: final shape (`State` enum, `load()`, `swipe(_:liked:)`, `hasSwiped`), with `private let service = LiveHorseService()` until `step-3-fake-horses`, and the literal `"The horses ran away. 🐎💨"` until `step-4-tested`.

---

## 6. Final source and tests

Use `reference/05-stable-date-implementation-plan.md` §4.1–4.18 as the source, with these edits:
- Paths per §2. Drop §4.3 (`Theme.swift`); use `Color.rose` etc. from the asset catalog.
- `LiveHorseService.defaultURL` per D2.
- `SwipeView` per D4 (header, tab bar with badge, no `NavigationStack` title/toolbar). Keep the four previews.
- `CardStackView`: vertical ✕ ★ ♥ column overlapping the lower-right of the top card; ★ calls `onSwipe(horse, true)`.
- `HorseCardView`: chips per PRD §6; `.accessibilityElement(children: .combine)`; name `.lineLimit(2).minimumScaleFactor(0.7)`.
- `MatchOverlayView(horse:onDismiss:)`: PRD §6 match overlay; both buttons call `onDismiss`.
- `Copy`: PRD §4.

Tests (`StableDateTests/SwipeViewModelTests.swift`, `@testable import stable_date`, `@MainActor @Suite`), exactly these eight:

| Test | Protects | Shown on stage |
|---|---|---|
| `offlineShowsErrorNotInfiniteSpinner` | Bug 1 | ✅ (step-4 slide) |
| `emptyResponseShowsEmptyState` | Bug 2 | ran |
| `likingAHorseThatLikesYouBackIsAMatch` | the match rule | ✅ scrolled to |
| `likingAHorseThatDoesNotLikeYouBackIsNotAMatch` | match rule, other direction | ran |
| `nopingNeverMatches` | Bug 3; the one that turns red when Reva breaks it | ✅ |
| `swipingTheLastHorseShowsEmptyState` | empty after last swipe | ran |
| `retryAfterFailureLoadsHorses` | Try again works (`FlakyHorseService`, test target only) | ran |
| `samplesMatchJSON` | `Horse.samples` == `Data/horses.json` | ran |

`samplesMatchJSON` reads the file from the repo instead of a bundle resource:

```swift
@Test func samplesMatchJSON() throws {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()          // StableDateTests/
        .deletingLastPathComponent()          // repo root
        .appending(path: "Data/horses.json")
    let decoded = try JSONDecoder().decode([Horse].self, from: Data(contentsOf: url))
    #expect(decoded == Horse.samples)
}
```

The `delay` on `MockHorseService` stays `.zero` in tests. No test touches the network.

---

## 7. Demo schemes (shared, in `stable-date.xcodeproj/xcshareddata/xcschemes/`)

Three schemes, each a copy of the `stable-date` scheme (Build: app target; Test: `StableDateTests`; Run: Debug):

| Scheme | Run → Arguments → Environment Variables |
|---|---|
| **Live** | none |
| **Offline** | `STABLE_DATE_URL` = `https://horses.invalid/horses.json` (host that doesn't exist → `URLError(.cannotFindHost)`, reads like offline) |
| **Empty** | `STABLE_DATE_URL` = `https://raw.githubusercontent.com/<owner>/stable-date/main/Data/horses-empty.json` |

Schemes are part of the base commit, so every tag has them. On stage: pick the scheme, ⌃⌘R (Run Without Building).

---

## 8. Scripts (`scripts/`, executable, `set -u`)

Adapt `reference/05` §3 Phase 3 with these changes:
- Simulator: `SIM=$(xcrun simctl list devices available | grep -m1 -oE "iPhone [0-9]+ Pro \(" | sed 's/ ($//')`; fall back to the first available iPhone. `DEST="platform=iOS Simulator,name=$SIM"`.
- `xcodebuild -project stable-date.xcodeproj -scheme Live -destination "$DEST" build` (and `test` at the last tag; expect 8 tests).
- `check-rules.sh` paths: `stable-date/Features`, `stable-date/Services`, `stable-date/Models`, `stable-date/App/StableDateApp.swift`. Fix the typo in the reference (`grep -rl "LiveHorseService()" Stable Date` → `grep -rl "LiveHorseService()" stable-date`).
- `screenshots.sh`: bundle id `com.revaprasetya.stabledate`, app path `…/Debug-iphonesimulator/stable-date.app`, outputs to `docs/screenshots/`.

---

## 9. Branch `demo/super-like` (for the AI-moment slide and as a spare demo)

Off `step-4-tested`: add `func superLike(_ horse: Horse) -> Bool` to `SwipeViewModel` (removes the horse; always a match if the horse was in the deck), wire ★ to it, add `@Test func superLikeAlwaysMatches()`. About 25 lines. 9 tests green.

Reva measures the AI moment himself (WALKTHROUGH §4) with this prompt on fresh sessions at `step-0-spaghetti` and `step-4-tested`: *"Add Super Like: a super-like that always creates a match. Update SwipeViewModel and add a test."* Don't pre-solve it on `main`.

---

## 10. Definition of done (paste into `NOTES.md`, filled in)

```
[ ] scripts/verify-tags.sh → all ✓ (output pasted)
[ ] scripts/check-rules.sh at step-4-tested → all ✓ (output pasted)
[ ] ⌘U at step-4-tested → 8 tests, 0 failures
[ ] Break-it check: guard horse.likesYouBack → only nopingNeverMatches fails
[ ] git diff step-4-tested work/final → empty; work/final deleted
[ ] demo/super-like builds, 9 tests green
[ ] Each live-typing contract in §5 tried once on a scratch checkout and works as described
[ ] step-0: three bugs reproduced with the Offline / Empty schemes and ✕ on Sir Gallops-a-Lot
[ ] docs/screenshots/{loading,loaded,empty,failed,match,profile}.png
[ ] NOTES.md: line count of step-0 SwipeView.swift, every judgment call, everything Reva must do by hand
[ ] README tag table and cheat sheet still true
```

---

## 11. What Reva does by hand

1. Add the `StableDateTests` target (§1.2) before the agent starts.
2. Create the public GitHub repo `stable-date`, tell the agent the owner so `<owner>` gets replaced in D2 and the **Empty** scheme, then push `main`, all tags and `demo/super-like` (`git push origin main --tags demo/super-like`). Check that the raw URL of `Data/horses.json` returns 200.
3. Clone fresh into another folder and run `bash scripts/verify-tags.sh` there.
4. Walk `WALKTHROUGH.md` once with a timer, record one backup video per step, measure the AI moment.
5. Put the numbers from `NOTES.md` into the deck: the line count, the six `[__]` on the AI-moment slide, the repo link and QR on the "Bahan belajar" slide.

---

## 12. Don't add

Coordinator, Router, Repository, UseCase, Interactor, DI container, module split, SwiftData, third-party packages, SwiftLint, localization, a Matches screen, chat, persistence, remote images, `AsyncImage`, extra protocols (only `HorseService` exists), tests of views or `Codable`. The slides literally list these as "yang sengaja nggak kita pasang".
