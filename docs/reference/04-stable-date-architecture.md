# Stable Date 🐴 · Architecture
### How the app is built, why, and how it evolves across the five demo tags
Version 1.0 · 7 Oct 2026 · Read `03-stable-date-product-design.md` first.

---

## 1. Architecture in one paragraph

Stable Date is a single-screen SwiftUI app using **MVVM with `@Observable`**, **init-based dependency injection**, and a **single `State` enum per screen**. There are three layers (UI → Logic → Data) and dependencies point one way. The only abstraction is one protocol, `HorseService`, because the network is the only thing we need to fake. Nothing else is abstracted. The whole point of the architecture is that it's the *smallest* set of decisions that fixes the three bugs in the spaghetti version and makes the match rule testable, and then it stops.

---

## 2. Principles (the five rules, as engineering constraints)

| Rule | Constraint the build must satisfy |
|---|---|
| 1. One job per thing | A file is a View, a ViewModel, a Model, a Service, or the App entry. Never two. If a View needs logic, the logic goes in a ViewModel; if it needs data, it asks a ViewModel. |
| 2. Make state explicit | Every screen with async data owns exactly one `State` enum. No parallel `isLoading` / `error` / `items` properties. Views `switch` exhaustively. |
| 3. Depend on promises, not things | Anything that touches network, disk, or time is behind a protocol. ViewModels receive their dependencies in `init`. The only place real implementations are constructed is the composition root (`StableDateApp`). |
| 4. Test what users feel | Tests target ViewModel behavior that maps to a user-visible outcome. No tests of SwiftUI rendering, no tests of `Codable` on trivial structs. |
| 5. Don't over-engineer | No Coordinator, Router, Repository, UseCase, Interactor, DI container, or module split. Add one only when a *named* pain appears (see §10). |

---

## 3. Layer diagram and dependency rules

```
┌───────────────────────────── Stable Date (app target) ─────────────────────────────┐
│                                                                              │
│   UI (SwiftUI)                 Logic                    Data                 │
│  ┌──────────────────┐        ┌─────────────────┐      ┌──────────────────┐   │
│  │ SwipeView        │──owns──▶ SwipeViewModel  │──uses─▶ any HorseService │   │
│  │  ├ LoadingView   │        │  state: State   │      │   (protocol)     │   │
│  │  ├ CardStackView │        │  matches        │      └───────┬──────────┘   │
│  │  │  └ HorseCard  │        │  load()         │          ┌───┴────────────┐ │
│  │  ├ EmptyDeckView │        │  swipe(_:liked:)│          │LiveHorseService│ │
│  │  ├ ErrorView     │        └─────────────────┘          │MockHorseService│ │
│  │  ├ MatchOverlay  │                 │                   └────────────────┘ │
│  │  └ HorseProfile  │                 ▼                            │         │
│  └──────────────────┘        ┌─────────────────┐                   │         │
│                              │ Horse (Model)   │◀──────────────────┘         │
│                              └─────────────────┘                             │
│                                                                              │
│   Composition root: StableDateApp.swift  →  SwipeView(viewModel: .init(service: LiveHorseService()))
└──────────────────────────────────────────────────────────────────────────────┘
                    │ HTTPS GET
                    ▼
        raw.githubusercontent.com/<owner>/stable-date-ios/main/Data/horses.json
```

### Dependency rules (enforce in code review)

1. **Views import SwiftUI and may reference:** other Views, the ViewModel they own, `Horse`, `Copy`. Views never reference `URL`, `URLSession`, `JSONDecoder`, or any `*Service` type.
2. **ViewModels import Foundation + Observation only.** They never import SwiftUI. They reference `Horse` and `any HorseService`. They never reference a concrete service.
3. **Services import Foundation.** They reference `Horse`. They never reference ViewModels or Views.
4. **Models import Foundation.** They reference nothing else.
5. **`StableDateApp.swift` is the only file that names `LiveHorseService`.** Previews and tests name `MockHorseService`.

A quick grep validates all five (see `05`, Phase 5).

---

## 4. Folder structure (final tag)

```
stable-date-ios/
├── README.md                          ← tags, how to run, how to demo
├── CREDITS.md                         ← image licenses
├── Data/
│   ├── horses.json                    ← the "live" source (served raw from GitHub)
│   └── horses-empty.json              ← [] for demoing the empty state from the network
├── StableDate.xcodeproj
├── StableDate/
│   ├── App/
│   │   ├── StableDateApp.swift             ← @main, composition root
│   │   └── Copy.swift                 ← every user-facing string
│   ├── Models/
│   │   ├── Horse.swift                ← be a horse
│   │   └── Horse+Samples.swift        ← Horse.samples for previews/tests
│   ├── Services/
│   │   ├── HorseService.swift         ← the promise (protocol)
│   │   ├── LiveHorseService.swift     ← URLSession + JSONDecoder
│   │   └── MockHorseService.swift     ← test double
│   ├── Features/
│   │   ├── Swipe/
│   │   │   ├── SwipeViewModel.swift   ← State enum, load(), swipe()
│   │   │   ├── SwipeView.swift        ← switch on state, owns the sheet/overlay
│   │   │   ├── CardStackView.swift    ← top card + 2 peeking + buttons
│   │   │   ├── HorseCardView.swift    ← one card
│   │   │   ├── MatchOverlayView.swift
│   │   │   ├── EmptyDeckView.swift
│   │   │   ├── ErrorView.swift
│   │   │   └── LoadingView.swift
│   │   └── Profile/
│   │       └── HorseProfileView.swift ← detail, takes a Horse
│   └── Resources/
│       └── Assets.xcassets            ← AppIcon, Colors (rose/blush/plum/lavender/ink), horse-01…10
└── StableDateTests/
    └── SwipeViewModelTests.swift
```

Folders are **by feature, then by role**, not by type. `Models/` and `Services/` are shared because two features (Swipe, Profile) use `Horse`. If a second feature ever needed its own service, it would get its own `Features/<Name>/` folder with its ViewModel and the service would stay in `Services/`.

`MockHorseService` ships in the **app target**, not the test target, because SwiftUI previews (which run in the app target) need it. That's a deliberate trade-off: one small file of fake data in the production binary in exchange for previews of every state.

---

## 5. Types (final tag)

### 5.1 Model

```swift
// Models/Horse.swift
import Foundation

struct Horse: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let age: Int
    let breed: String
    let bio: String
    let lookingFor: String
    let imageName: String
    let likesYouBack: Bool
}
```

`Sendable` because it crosses from the service (nonisolated) to the ViewModel (`@MainActor`). `Hashable` so `[Horse]` is `Equatable`, which makes `State` `Equatable`, which makes tests one line.

### 5.2 Service protocol and implementations

```swift
// Services/HorseService.swift
protocol HorseService: Sendable {
    func fetchHorses() async throws -> [Horse]
}
```

```swift
// Services/LiveHorseService.swift
import Foundation

struct LiveHorseService: HorseService {
    static let defaultURL = URL(string:
        "https://raw.githubusercontent.com/<owner>/stable-date-ios/main/Data/horses.json")!

    var url: URL = Self.defaultURL
    var session: URLSession = .shared

    func fetchHorses() async throws -> [Horse] {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Horse].self, from: data)
    }
}
```

`url` and `session` are `var` with defaults so the demo can point at `horses-empty.json` or a 404 path by changing one line in `StableDateApp`, and so the same type could be tested against a stubbed `URLProtocol` later (we don't; Rule 5).

```swift
// Services/MockHorseService.swift
struct MockHorseService: HorseService {
    var result: Result<[Horse], any Error>
    var delay: Duration = .zero

    func fetchHorses() async throws -> [Horse] {
        if delay > .zero { try await Task.sleep(for: delay) }
        return try result.get()
    }
}
```

This is a **stub** (returns canned data), the simplest kind of test double. It isn't a spy or a mock with expectations, and it doesn't need to be. Call it a "test double" on stage, which is the umbrella term the TOR uses.

### 5.3 ViewModel

```swift
// Features/Swipe/SwipeViewModel.swift
import Foundation
import Observation

@MainActor @Observable
final class SwipeViewModel {

    enum State: Equatable {
        case loading
        case loaded([Horse])
        case empty
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var matches: [Horse] = []
    private(set) var hasSwiped = false

    private let service: any HorseService

    init(service: any HorseService) {
        self.service = service
    }

    func load() async {
        state = .loading
        hasSwiped = false
        do {
            let horses = try await service.fetchHorses()
            state = horses.isEmpty ? .empty : .loaded(horses)
        } catch {
            state = .failed(Copy.errorTitle)
        }
    }

    /// Removes the horse from the deck. Returns `true` if it's a match.
    @discardableResult
    func swipe(_ horse: Horse, liked: Bool) -> Bool {
        guard case .loaded(var deck) = state else { return false }
        deck.removeAll { $0.id == horse.id }
        state = deck.isEmpty ? .empty : .loaded(deck)
        hasSwiped = true

        guard liked, horse.likesYouBack else { return false }
        matches.append(horse)
        return true
    }
}
```

Design notes:
- `@MainActor` on the class: all state mutation happens on the main actor, which is what SwiftUI needs, and the compiler enforces it. The `await service.fetchHorses()` hop is the only place work leaves the main actor.
- `private(set)` on everything: Views read, only the ViewModel writes.
- `swipe` is synchronous and pure with respect to its inputs. That's what makes the match test run in microseconds.
- `State` is nested, so it's `SwipeViewModel.State` and doesn't collide with SwiftUI's `@State` property wrapper in View files.
- `.failed(String)` carries the user-facing message, not the error. Trade-off accepted for the demo; §10 says when to change it.
- `hasSwiped` exists only to pick between the two empty-state copies. It is not screen state (the screen is still `.empty`).

### 5.4 Views (signatures only; full bodies in `05`)

```swift
struct SwipeView: View          { @State var viewModel: SwipeViewModel; ... }          // switches on state
struct LoadingView: View        { }                                                      // ProgressView + copy
struct CardStackView: View      { let horses: [Horse]; let onSwipe: (Horse, Bool) -> Void; let onTap: (Horse) -> Void }
struct HorseCardView: View      { let horse: Horse }
struct MatchOverlayView: View   { let horse: Horse; let onDismiss: () -> Void }
struct EmptyDeckView: View      { let exhausted: Bool; let onRetry: () -> Void }
struct ErrorView: View          { let message: String; let onRetry: () -> Void }
struct HorseProfileView: View   { let horse: Horse }
```

`SwipeView` owns the ViewModel with `@State` (the iOS 17 way for `@Observable` objects) and receives it through `init(viewModel:)`, so previews and the composition root can inject whatever service they want.

The only View-local state is presentation: `@State private var presentedHorse: Horse?` (sheet), `@State private var matchedHorse: Horse?` (overlay), `@State private var isAnimating = false` (double-tap guard). None of it is screen state; all of it would be meaningless to test.

---

## 6. State machine

```
            ┌──────────┐
   launch   │          │  fetch ok, n > 0
 ──────────▶│ loading  │─────────────────────▶ loaded([Horse])
            │          │                           │   ▲
            └────┬─────┘                           │   │ swipe (n-1 > 0)
          fetch  │   fetch ok, n == 0              │   │
          throws │ ┌───────────────────────────────┘   │
                 │ │  swipe (last horse)               │
                 ▼ ▼                                   │
            ┌──────────┐                               │
            │  empty   │──── Try again / Start over ───┤
            └──────────┘                               │
            ┌──────────┐                               │
            │  failed  │──── Try again ────────────────┘   (both go via loading)
            └──────────┘
```

Invariants the tests pin down:
- `loading` never persists after `load()` returns.
- `failed` is only reachable from `loading`.
- `empty` is reachable from `loading` (no data) and from `loaded` (last swipe).
- `matches` only grows on `swipe(liked: true)` with `likesYouBack == true`.

---

## 7. Concurrency and error handling

| Concern | Decision |
|---|---|
| Language mode | Swift 6, strict concurrency. Everything compiles with zero warnings. |
| Where async work starts | SwiftUI `.task { await viewModel.load() }` on `SwipeView`. Retry buttons call `Task { await viewModel.load() }`. |
| Cancellation | `.task` cancels on disappear. `SwipeView` never disappears in Stable Date (single screen), so `load()` doesn't special-case `CancellationError`. If a second screen is ever added, add `if error is CancellationError { return }` before setting `.failed`. Say this if asked. |
| Errors in the service | Thrown, never swallowed. `LiveHorseService` throws `URLError` for transport and non-2xx, `DecodingError` for bad JSON. |
| Errors in the ViewModel | Caught in `load()` and converted to `.failed(message)`. The ViewModel is the only place that decides what an error *means to the user*. |
| Errors in the View | None. Views never see an `Error`. |
| Threading in services | `LiveHorseService` is a `Sendable` struct with no mutable state. `URLSession.data(from:)` is already async-safe. |
| Image loading | Synchronous from the asset catalog (`Image(horse.imageName)`), so no loading state for images. |

---

## 8. Evolution across tags (what each checkout contains)

The repo is built **forward**, one commit per tag, on `main`. The demo checks tags out in order. Each row says what changed and what the audience is supposed to notice.

| Tag | Files | What changed | Bugs present |
|---|---|---|---|
| `step-0-spaghetti` | `StableDateApp.swift`, `SwipeView.swift` (≥ 300 lines), `Assets` | Everything in one View: inline `Horse` struct, `.task` with `try?` + `return`, `@State` booleans, `like`/`nope` with copy-pasted match logic, card UI, animations, match overlay, profile sheet, all inline. | Spinner forever on failure · blank on empty · nope can match |
| `step-1-wip` | + `Models/Horse.swift`, `Services/LiveHorseService.swift`, `Features/Swipe/SwipeViewModel.swift`, `HorseCardView.swift`, `Profile/HorseProfileView.swift` | New files exist and compile. `SwipeView` still has its own `.task` networking and its own `@State`s; it doesn't use the ViewModel yet. | all 3 |
| `step-1-split` | `SwipeView.swift` | `.task { await viewModel.load() }`; View reads `viewModel.horses / isLoading / errorMessage`. Match logic now only in `SwipeViewModel.swipe`. | spinner · blank (nope-match fixed as a side effect of having one `swipe`) |
| `step-2-wip` | `SwipeViewModel.swift`, `SwipeView.swift`, + `LoadingView`, `EmptyDeckView`, `ErrorView`, `CardStackView` | `State` enum replaces the three properties. View `switch` has `.loading`, `.loaded`, `.empty`. **Missing `.failed` → does not compile.** | n/a |
| `step-2-state` | `SwipeView.swift` | `.failed` case added. | none |
| `step-3-wip` | + `Services/HorseService.swift`, `Services/MockHorseService.swift`, `Models/Horse+Samples.swift`; `SwipeView.swift`, `StableDateApp.swift` | Protocol and stub exist. `LiveHorseService` conforms. ViewModel still `= LiveHorseService()`. `SwipeView` now takes `init(viewModel:)` and `StableDateApp` passes `SwipeViewModel()`, so the live `init(service:)` change produces one error in `StableDateApp`. No previews yet. | none |
| `step-3-fake-horses` | `SwipeViewModel.swift`, `StableDateApp.swift`, `SwipeView.swift` | `init(service:)`. Composition root passes `LiveHorseService()`. Four `#Preview`s with `MockHorseService`. | none |
| `step-4-tested` | + `StableDateTests/SwipeViewModelTests.swift`, `App/Copy.swift` | Swift Testing target. Strings moved to `Copy`. `main` = this tag. | none |

Rule for the builder: **every tag must `xcodebuild` cleanly** except `step-2-wip`, which must fail with exactly one error on the `switch`. Tags are immutable once the backup videos are recorded.

---

## 9. Testing strategy

**Target:** `StableDateTests`, Swift Testing (`import Testing`), `@MainActor` suite because the ViewModel is main-actor isolated.

**What we test (ViewModel only):**

| Test | User-visible behavior it protects | Walkthrough? |
|---|---|---|
| `offlineShowsErrorNotInfiniteSpinner` | Bug #1 | ✅ shown |
| `likingAHorseThatLikesYouBackIsAMatch` | The business rule | ✅ shown |
| `nopingNeverMatches` | Bug #3; turns red in "break it on purpose" | ✅ mentioned |
| `emptyResponseShowsEmptyState` | Bug #2 | ran, not shown |
| `swipingTheLastHorseShowsEmptyState` | The free empty-deck behavior | ran, not shown |
| `likingAHorseThatDoesNotLikeYouBackIsNotAMatch` | Match rule, other direction | ran, not shown |
| `retryAfterFailureLoadsHorses` | Try again works (uses a mock that fails once, then succeeds) | ran, not shown |

Seven tests, all on `SwipeViewModel`, all through the public API, all < 10 ms, no network, no sleep (the `delay` on the mock stays `.zero` in tests).

**What we deliberately don't test:** `Horse` decoding (trivial `Codable`), `LiveHorseService` against a real or stubbed URL (would need `URLProtocol` plumbing; Rule 5), any View (SwiftUI rendering is Apple's job), `MockHorseService` itself.

**Conventions:** one `@Suite` per ViewModel, test names read as sentences describing the user outcome, Arrange/Act/Assert separated by blank lines, `#expect` on `state ==` (enum is `Equatable`), no shared mutable fixtures.

`retryAfterFailureLoadsHorses` needs a mock that changes its answer, so the test file defines a tiny `FlakyHorseService` (fails on the first call, succeeds after) locally. It stays in the test target; it is not promoted to the app target.

---

## 10. Trade-offs and "when would I change this?" (Q&A ammunition)

| Decision | Why it's right for Stable Date | Change it when |
|---|---|---|
| MVVM with `@Observable`, no TCA/VIPER | Smallest pattern that separates the three layers; the audience can read it in one sitting | A team of 5+ needs enforced consistency, or state must be shared across many screens |
| One `State` enum with `.failed(String)` | Four cases fit on a slide; the message *is* what the user sees | The View must react differently to different errors (offline vs. 401 vs. 500): switch to `.failed(any Error)` or a small `LoadError` enum |
| Protocol only for the service | Network is the only thing we need to fake | You add disk cache, analytics, time/clock, or auth: each gets its own protocol |
| No Repository | One source, no caching, no merging | You combine network + cache + disk |
| No Coordinator/Router | One screen + one sheet | Deep links, multi-step flows, or UIKit interop |
| `MockHorseService` in the app target | Previews need it | Binary size matters or legal says no fake data in prod: move to a `StableDatePreviews` dev-only target |
| JSON on GitHub, not Supabase | Zero infra, zero keys, zero live-demo risk | You want to show auth or writes. The service protocol is the same; only `LiveHorseService` changes. |
| `id: String` slug | Hand-editable JSON, stable across builds | Server assigns IDs |
| Bundled images | Nothing can 404 on stage | Real product; then image loading becomes its own state (`AsyncImage` or a service) |
| Match decided client-side | Demo | Real matching must be server-side; the client would call `service.like(horse)` and get a result |
| `hasSwiped` flag for empty copy | Keeps the enum at four cases that match the slides | Add `.exhausted` as a fifth case when the two empty screens diverge in behavior, not just copy |
| No `CancellationError` handling | Single screen never disappears | Any second screen |

---

## 11. Conventions for the codebase

- Swift 6 language mode, strict concurrency, treat warnings as errors in Release.
- One type per file; file name == type name.
- `// MARK: -` sections in Views: `Body`, `Subviews`, `Actions`, `Previews`.
- No force unwraps outside `static let` URLs and test fixtures.
- All user-facing strings in `Copy.swift` as `static let`s; no string literals in Views (except SF Symbol names).
- Every View has at least one `#Preview`; `SwipeView` has four.
- Commits: one per tag, message = tag name + one line of what the audience should notice.
- No third-party packages. No `swiftlint` either (Rule 5; the conventions above are short enough to check by eye).
