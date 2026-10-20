# Stable Date 🐴 · Implementation Plan (build brief for Claude Opus 5.5)
### Everything needed to build the repo, the tags, the assets, and the demo safety net
Version 1.0 · 7 Oct 2026 · Owner: Reva · Builder: Opus 5.5 in Claude Code on Reva's Mac

> **Inputs:** `03-stable-date-product-design.md` (what), `04-stable-date-architecture.md` (how), `horses.json` (data). This file is the *order of work* plus the full source of the final tag. When this file and `04` disagree on a signature, `04` wins; when they disagree on sequencing, this file wins.

---

## 0. Kickoff prompt (paste this into Opus 5.5, then attach the four files)

> You're building `stable-date-ios`, a tiny SwiftUI teaching app, from the attached spec. Read `03-stable-date-product-design.md`, `04-stable-date-architecture.md`, and `05-stable-date-implementation-plan.md` fully before writing code. Follow `05` phase by phase; don't skip Phase 1 (build the final version first). Every tag listed in `05` §2 must build with `xcodebuild` except `step-2-wip`, which must fail with exactly one "switch must be exhaustive" error. Swift 6 language mode, strict concurrency, zero warnings, zero third-party packages. Run `scripts/verify-tags.sh` and `scripts/check-rules.sh` before telling me you're done, and paste their output. Ask me only if something in the spec is contradictory; otherwise make the call and note it in `NOTES.md`.

---

## 1. Environment and setup (Reva does this part, ~10 min)

1. Install/confirm **Xcode 16.x** with the iOS 17 and iOS 18 simulators. Confirm `xcode-select -p` points at it.
2. Create the project in Xcode (File → New → Project → iOS → App):
   - Product name `StableDate` (display name “Stable Date”), organization identifier `com.revaprasetya`, Interface **SwiftUI**, Language **Swift**, Testing System **Swift Testing**, Storage **None**.
   - Save to `~/dev/stable-date-ios/`.
3. Project settings: iOS Deployment Target **17.0**, Swift Language Version **6**, `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` for Release, device family **iPhone**, orientation **Portrait** only.
4. Xcode 16 uses **synchronized folders** by default, so files added on disk show up in the navigator. Keep it that way; it's what lets Opus work from the terminal.
5. `git init`, add a `.gitignore` for Xcode (`xcuserdata/`, `DerivedData/`, `*.xcuserstate`), commit as `chore: scaffold empty Stable Date project`.
6. Create a public GitHub repo `stable-date-ios` and push. Note the owner name; it goes into `LiveHorseService.defaultURL`.
7. Open Claude Code in `~/dev/stable-date-ios/`, paste the kickoff prompt, attach the files.

Toolchain check Opus runs first:
```bash
xcodebuild -version && swift --version && xcrun simctl list devices available | grep "iPhone 16"
```

---

## 2. Deliverables

| Deliverable | Definition of done |
|---|---|
| Tags `step-0-spaghetti`, `step-1-wip`, `step-1-split`, `step-2-wip`, `step-2-state`, `step-3-wip`, `step-3-fake-horses`, `step-4-tested` | All on `main` in that order; `main` HEAD == `step-4-tested`; `scripts/verify-tags.sh` passes |
| Branch `demo/super-like` | Off `step-4-tested`, adds the Super Like feature + test (for the "running early" contingency and the AI-moment clip) |
| `Data/horses.json`, `Data/horses-empty.json` | Served raw from GitHub; `LiveHorseService` points at them |
| Assets | 10 placeholder images `horse-01…10` (Reva swaps in real ones), 4 named colors, AppIcon |
| `scripts/verify-tags.sh`, `scripts/check-rules.sh`, `scripts/screenshots.sh` | Executable, documented in README |
| `README.md`, `CREDITS.md`, `NOTES.md` | README has the demo cheat sheet; NOTES lists every judgment call Opus made |
| Screenshots `docs/screenshots/{loading,loaded,empty,failed,match,profile}.png` | 1179×2556 from iPhone 16 Pro, light mode, taken by `scripts/screenshots.sh` |

---

## 3. Phases

### Phase 1 · Build the final version on a work branch (do this first)

Branch: `work/final` off the scaffold commit. Write **every** file in §4 exactly as specified. Then:

```bash
xcodebuild -scheme StableDate -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
xcodebuild -scheme StableDate -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test 2>&1 | grep -E "Test Suite|passed|failed|error:"
```

Exit criteria: builds with 0 warnings, all 7 tests pass, the four `SwipeView` previews render (open Xcode once and check the canvas; take a screenshot into `docs/previews.png`).

Why final first: it's easier to write correct code once and then *remove* structure to create the earlier states than to write five half-finished versions forward. The git history is still created forward in Phase 2.

### Phase 2 · Create the demo history forward on `main`

Starting from the scaffold commit on `main`, for each tag in order: make the working tree match the state described in `04` §8 (copying from `work/final` where files are identical), build, commit, tag. Commit message format: `<tag>: <one line the audience should notice>`.

| Tag | How to construct it |
|---|---|
| `step-0-spaghetti` | Write `StableDate/SwipeView.swift` per §5 (the spaghetti spec). Only `StableDateApp.swift`, `SwipeView.swift`, `Assets.xcassets` exist. Build. **Run and manually confirm all three bugs** (use `--mock-*` is not available here; use Network Link Conditioner or temporarily point the URL at a 404 path, then revert before committing). Record `wc -l StableDate/SwipeView.swift` in `NOTES.md`; Reva puts the number on Slide 6. |
| `step-1-wip` | Add final `Models/Horse.swift`, `Services/LiveHorseService.swift` (**without** `: HorseService` conformance yet), `Features/Swipe/HorseCardView.swift`, `Features/Profile/HorseProfileView.swift`, and the Step-1 version of `SwipeViewModel.swift` (§6.1). Remove the inline `Horse` struct and inline card/profile code from `SwipeView.swift` so it uses the new views, **but keep its own `.task` networking block and `@State` booleans.** Build. |
| `step-1-split` | In `SwipeView.swift`: replace the `.task` block with `.task { await viewModel.load() }`, read `viewModel.horses / isLoading / errorMessage`, route buttons to `viewModel.swipe`. Delete the View's own `like`/`nope`. Build. |
| `step-2-wip` | Replace `SwipeViewModel.swift` with the Step-2 version (§6.2). Add final `LoadingView`, `EmptyDeckView`, `ErrorView`, `CardStackView`. Rewrite `SwipeView.body` to the final `switch` **minus the `.failed` case**. Build → must fail with exactly one error containing "exhaustive". Commit anyway (`git commit` doesn't care). |
| `step-2-state` | Add the `.failed` line. Build. |
| `step-3-wip` | Add final `Services/HorseService.swift`, `Services/MockHorseService.swift`, `Models/Horse+Samples.swift`. Add `: HorseService` to `LiveHorseService`. ViewModel still has `private let service = LiveHorseService()`. Give `SwipeView` its final `init(viewModel:)` and change `StableDateApp` to `SwipeView(viewModel: SwipeViewModel())`. No previews on `SwipeView`. Build. |
| `step-3-fake-horses` | ViewModel gets `init(service:)` (final version minus `Copy`, see §6.3). `StableDateApp.swift` passes `LiveHorseService()` on one line (§6.4). Add the four `#Preview`s to `SwipeView.swift`. Build. |
| `step-4-tested` | Add final `App/Copy.swift`, move strings into it, add final `StableDateApp.swift` with `makeService()`, add `StableDateTests/SwipeViewModelTests.swift`. Build + test. This is `main`. |

After tagging, `git diff step-4-tested work/final` must be empty. Delete `work/final`.

### Phase 3 · Verification scripts

`scripts/verify-tags.sh`:
```bash
#!/usr/bin/env bash
set -u
DEST='platform=iOS Simulator,name=iPhone 16 Pro'
TAGS=(step-0-spaghetti step-1-wip step-1-split step-2-wip step-2-state step-3-wip step-3-fake-horses step-4-tested)
START=$(git rev-parse --abbrev-ref HEAD)
fail=0
for t in "${TAGS[@]}"; do
  git checkout -q -f "$t" || { echo "✗ cannot checkout $t"; fail=1; continue; }
  out=$(xcodebuild -scheme StableDate -destination "$DEST" build 2>&1)
  if [[ "$t" == "step-2-wip" ]]; then
    if echo "$out" | grep -q "exhaustive" && [[ $(echo "$out" | grep -c "error:") -eq 1 ]]; then echo "✓ $t fails exactly as intended"; else echo "✗ $t should fail with ONE exhaustive error"; fail=1; fi
  else
    if echo "$out" | grep -q "BUILD SUCCEEDED"; then echo "✓ $t builds"; else echo "✗ $t does not build"; fail=1; fi
    if echo "$out" | grep -q "warning:"; then echo "  ⚠ $t has warnings"; fi
  fi
done
git checkout -q -f step-4-tested
xcodebuild -scheme StableDate -destination "$DEST" test 2>&1 | grep -E "Executed|passed|failed" | tail -2
git checkout -q "$START"
exit $fail
```

`scripts/check-rules.sh` (the dependency rules from `04` §3, as greps; run at `step-4-tested`):
```bash
#!/usr/bin/env bash
set -u; fail=0
chk() { if grep -rqE "$2" $1; then echo "✗ $3"; fail=1; else echo "✓ $3"; fi; }
chk "StableDate/Features"          "URLSession|JSONDecoder|URL\("      "Views/ViewModels never touch networking"
chk "StableDate/Features/Swipe/SwipeViewModel.swift" "import SwiftUI"  "ViewModel doesn't import SwiftUI"
chk "StableDate/Features/Swipe/SwipeViewModel.swift" "LiveHorseService" "ViewModel doesn't name the real service"
chk "StableDate/Features/Swipe/SwipeViewModel.swift" "var isLoading|errorMessage" "ViewModel has no parallel state flags"
chk "StableDate/Services StableDate/Models" "import SwiftUI|ViewModel"        "Services/Models don't know about UI"
n=$(grep -rl "LiveHorseService()" Stable Date | wc -l | tr -d ' ')
if [[ "$n" == "1" ]] && grep -q "LiveHorseService()" StableDate/App/StableDateApp.swift; then echo "✓ only StableDateApp constructs LiveHorseService"; else echo "✗ LiveHorseService constructed in $n files"; fail=1; fi
lit=$(grep -rnE '"[A-Z][a-z].{12,}"' StableDate/Features | grep -v "systemImage" | grep -v "#Preview" | wc -l | tr -d ' ')
if [[ "$lit" == "0" ]]; then echo "✓ no long string literals in Views (all in Copy)"; else echo "⚠ $lit possible user-facing literals outside Copy.swift"; fi
exit $fail
```

`scripts/screenshots.sh` (uses the `--mock-*` launch arguments in `StableDateApp`; final tag only):
```bash
#!/usr/bin/env bash
set -eu
SIM="iPhone 16 Pro"; APP="com.revaprasetya.Stable Date"; OUT=docs/screenshots; mkdir -p "$OUT"
xcrun simctl boot "$SIM" 2>/dev/null || true; open -a Simulator
xcrun simctl ui "$SIM" appearance light
xcodebuild -scheme StableDate -destination "platform=iOS Simulator,name=$SIM" -derivedDataPath build build >/dev/null
xcrun simctl install "$SIM" build/Build/Products/Debug-iphonesimulator/StableDate.app
shot() { xcrun simctl terminate "$SIM" "$APP" 2>/dev/null || true; xcrun simctl launch "$SIM" "$APP" "$1" >/dev/null; sleep 2; xcrun simctl io "$SIM" screenshot "$OUT/$2.png"; }
shot --mock-loading loading
shot --mock-loaded  loaded
shot --mock-empty   empty
shot --mock-failed  failed
echo "match.png and profile.png: launch with --mock-loaded, tap Like on the first card / tap the card, then: xcrun simctl io \"$SIM\" screenshot $OUT/match.png"
```

### Phase 4 · Assets

- **Colors** in `Assets.xcassets`: `Rose #E25587`, `Blush #FCE7F0`, `Plum #B23A6F`, `Lavender #7C5CE0`, `Ink #1F1A24` (light) / `#F5F5F7` (dark), app background `#FFF7FA`. Universal, sRGB. Card photo backgrounds rotate through soft pastels: pink `#FDE2EC`, lavender `#E9E3FF`, mint `#DDF5EA`, peach `#FFE7D6`.
- **Placeholder horse images** `horse-01…horse-10`, 1200×1600 JPEG: generate with Python/Pillow, each a flat pastel background (pink/lavender/mint/peach) with a different hue shift and the horse's name in large text, so the deck is visually distinguishable before real images arrive. Reva replaces them with AI-generated images (prompts in `06` §6) and updates `CREDITS.md`.
- **AppIcon**: 1024×1024 PNG, white rounded square, soft pink heart (`#F9D3E5`) with a cartoon chestnut horse head with big eyes. Use the Stable Date icon from the deck assets (`icon.svg`).
- Put all image generation in `scripts/placeholders.py` so it's reproducible.

### Phase 5 · Rule checks and polish

Run `scripts/check-rules.sh` on `step-4-tested`. Fix anything red. Confirm Dynamic Type XXL doesn't clip the card title (truncate with `.lineLimit(2).minimumScaleFactor(0.7)`). Confirm VoiceOver reads a card as "Sir Gallops-a-Lot, 7 years, Thoroughbred" (set `.accessibilityElement(children: .combine)` on `HorseCardView`).

### Phase 6 · Screenshots and the slide numbers

Run `scripts/screenshots.sh`, then capture `match.png` and `profile.png` manually. Also capture `docs/spaghetti.png`: open `step-0-spaghetti`'s `SwipeView.swift` in Xcode, zoom the editor to the smallest size (⌘-), hide everything but the editor, screenshot the window. This is Slide 6. Write the real line count into `NOTES.md` under "Numbers for the slides".

### Phase 7 · Demo safety net

1. `demo/super-like` branch off `step-4-tested`: add `func superLike(_ horse: Horse) -> Bool` to the ViewModel (always a match if the horse is in the deck), a third button `star.fill` in `CardStackView`, and `@Test func superLikeAlwaysMatches()`. Keep the diff small (≈ 25 lines total); it's what the AI-moment screenshots show.
2. `README.md` with: what Stable Date is (two lines), the tag table from `02` §0, the terminal cheat sheet, how to run tests, how to take screenshots, how the Network Link Conditioner demo works, link to the talk.
3. Reva records one backup video per step (QuickTime, Xcode window only, 1080p, ≤ 8 min each) **after** tags are frozen. Not Opus's job, but Opus adds a `docs/recording-checklist.md` listing the exact clicks per step from `02`.

---

## 4. Final source (tag `step-4-tested`)

All files are complete and should compile as-is under Swift 6 strict concurrency. Replace `<owner>` with the GitHub owner.

### 4.1 `StableDate/App/StableDateApp.swift`

```swift
import SwiftUI

@main
struct StableDateApp: App {
    var body: some Scene {
        WindowGroup {
            SwipeView(viewModel: SwipeViewModel(service: Self.makeService()))
        }
    }

    /// The composition root: the only place in the app that knows which `HorseService` is real.
    /// Launch arguments let rehearsals and screenshot scripts pick a fake without touching any other file.
    private static func makeService() -> any HorseService {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--mock-loaded")  { return MockHorseService(result: .success(Horse.samples)) }
        if args.contains("--mock-empty")   { return MockHorseService(result: .success([])) }
        if args.contains("--mock-failed")  { return MockHorseService(result: .failure(URLError(.notConnectedToInternet))) }
        if args.contains("--mock-loading") { return MockHorseService(result: .success([]), delay: .seconds(999)) }
        return LiveHorseService()
    }
}
```

### 4.2 `StableDate/App/Copy.swift`

```swift
import Foundation

/// Every user-facing string in Stable Date. The jokes live here.
enum Copy {
    static let appName = "Stable Date"
    static let tagline = "Swipe right on your soulmare."

    static let loadingTitle = "Rounding up horses..."

    static let emptyNoDataTitle = "No horses nearby."
    static let emptyNoDataBody = "Even horses have standards."
    static let emptyNoDataButton = "Try again"

    static let emptyExhaustedTitle = "You've seen every horse."
    static let emptyExhaustedBody = "Go touch grass. You're a horse, you'll enjoy it."
    static let emptyExhaustedButton = "Start over"

    static let errorTitle = "The horses ran away. 🐎💨"
    static let errorBody = "Check your connection and we'll round them up again."
    static let errorButton = "Try again"

    static let matchTitle = "It's a match!"
    static func matchBody(name: String) -> String { "You and \(name) are now trotting together." }
    static let matchButton = "Keep trotting"

    static let nopeLabel = "Nope"
    static let likeLabel = "Like"
    static let profileLookingFor = "Looking for"
    static func age(_ years: Int) -> String { "\(years) years" }
    static func matchesBadge(_ count: Int) -> String { "\(count) matches" }
}
```

### 4.3 `StableDate/App/Theme.swift`

```swift
import SwiftUI

extension Color {
    static let rose = Color("Rose")
    static let blush = Color("Blush")
    static let plum = Color("Plum")
    static let lavender = Color("Lavender")
    static let ink = Color("Ink")
}
```

### 4.4 `StableDate/Models/Horse.swift`

```swift
import Foundation

/// Be a horse.
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

### 4.5 `StableDate/Models/Horse+Samples.swift`

Mirror `Data/horses.json` exactly, same order, as `static let samples: [Horse]`. Pattern:

```swift
import Foundation

extension Horse {
    /// Fake horses for previews and tests. Keep identical to Data/horses.json.
    static let samples: [Horse] = [
        Horse(id: "sir-gallops-a-lot", name: "Sir Gallops-a-Lot", age: 7, breed: "Thoroughbred",
              bio: "Won a race once. Will bring it up on the first date, the second date, and at your funeral.",
              lookingFor: "Someone who appreciates a well-timed gallop and doesn't mind that I'm emotionally unavailable before 6 a.m.",
              imageName: "horse-01", likesYouBack: true),
        Horse(id: "hay-girl", name: "Hay Girl", age: 5, breed: "Arabian",
              bio: "Yes, I know what my name sounds like. No, I will not be taking questions.",
              lookingFor: "A stable relationship. Literally.",
              imageName: "horse-02", likesYouBack: false),
        // … horses 3–10 from horses.json …
    ]
}
```

Add a test-time guard in `StableDateTests` (`samplesMatchJSON`) that decodes `Data/horses.json` from the test bundle (add it as a test-target resource) and asserts equality with `Horse.samples`. That's test #8 and it's the only one that touches `Codable`; it exists so the two sources can't drift.

### 4.6 `StableDate/Services/HorseService.swift`

```swift
/// The promise: give me horses, or throw.
protocol HorseService: Sendable {
    func fetchHorses() async throws -> [Horse]
}
```

### 4.7 `StableDate/Services/LiveHorseService.swift`

```swift
import Foundation

/// Fetches horses from the internet. The only type in the app that knows a URL exists.
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

### 4.8 `StableDate/Services/MockHorseService.swift`

```swift
import Foundation

/// Fake horses. A test double: we decide exactly what it returns.
struct MockHorseService: HorseService {
    var result: Result<[Horse], any Error>
    var delay: Duration = .zero

    func fetchHorses() async throws -> [Horse] {
        if delay > .zero { try await Task.sleep(for: delay) }
        return try result.get()
    }
}
```

### 4.9 `StableDate/Features/Swipe/SwipeViewModel.swift`

```swift
import Foundation
import Observation

/// Decides. Owns the screen's one and only state.
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

### 4.10 `StableDate/Features/Swipe/SwipeView.swift`

```swift
import SwiftUI

/// Draws the screen for whatever state the ViewModel is in. Nothing else.
struct SwipeView: View {
    @State private var viewModel: SwipeViewModel
    @State private var presentedHorse: Horse?
    @State private var matchedHorse: Horse?

    init(viewModel: SwipeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    LoadingView()
                case .loaded(let horses):
                    CardStackView(horses: horses, onSwipe: handleSwipe, onTap: { presentedHorse = $0 })
                case .empty:
                    EmptyDeckView(exhausted: viewModel.hasSwiped) { Task { await viewModel.load() } }
                case .failed(let message):
                    ErrorView(message: message) { Task { await viewModel.load() } }
                }
            }
            .navigationTitle(Copy.appName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    MatchesBadge(count: viewModel.matches.count)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $presentedHorse) { HorseProfileView(horse: $0) }
        .overlay {
            if let horse = matchedHorse {
                MatchOverlayView(horse: horse) { matchedHorse = nil }
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.spring(duration: 0.4), value: matchedHorse)
    }

    // MARK: - Actions

    private func handleSwipe(_ horse: Horse, liked: Bool) {
        if viewModel.swipe(horse, liked: liked) {
            matchedHorse = horse
        }
    }
}

// MARK: - Subviews

private struct MatchesBadge: View {
    let count: Int
    var body: some View {
        Label("\(count)", systemImage: count > 0 ? "heart.fill" : "heart")
            .foregroundStyle(count > 0 ? Color.plum : .secondary)
            .accessibilityLabel(Copy.matchesBadge(count))
    }
}

// MARK: - Previews

#Preview("Loaded")  { SwipeView(viewModel: .init(service: MockHorseService(result: .success(Horse.samples)))) }
#Preview("Empty")   { SwipeView(viewModel: .init(service: MockHorseService(result: .success([])))) }
#Preview("Error")   { SwipeView(viewModel: .init(service: MockHorseService(result: .failure(URLError(.notConnectedToInternet))))) }
#Preview("Loading") { SwipeView(viewModel: .init(service: MockHorseService(result: .success([]), delay: .seconds(999)))) }
```

### 4.11 `StableDate/Features/Swipe/CardStackView.swift`

```swift
import SwiftUI

/// The deck: top card plus two peeking behind it, and the two buttons.
struct CardStackView: View {
    let horses: [Horse]
    let onSwipe: (Horse, Bool) -> Void
    let onTap: (Horse) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating = false

    private var top: Horse? { horses.first }

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                ForEach(Array(horses.prefix(3).enumerated().reversed()), id: \.element.id) { index, horse in
                    if index == 0 {
                        HorseCardView(horse: horse)
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .gesture(dragGesture(for: horse))
                            .onTapGesture { onTap(horse) }
                    } else {
                        HorseCardView(horse: horse)
                            .scaleEffect(1 - CGFloat(index) * 0.04)
                            .offset(y: CGFloat(index) * 8)
                    }
                }
            }
            HStack(spacing: 40) {
                SwipeButton(symbol: "xmark", tint: .plum, label: Copy.nopeLabel) { if let top { swipe(top, liked: false) } }
                SwipeButton(symbol: "heart.fill", tint: .rose, label: Copy.likeLabel) { if let top { swipe(top, liked: true) } }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func dragGesture(for horse: Horse) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimating else { return }
                if abs(value.translation.width) > 120 {
                    swipe(horse, liked: value.translation.width > 0)
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = .zero }
                }
            }
    }

    private func swipe(_ horse: Horse, liked: Bool) {
        guard !isAnimating else { return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeOut(duration: 0.35)) {
            dragOffset = CGSize(width: liked ? 600 : -600, height: -40)
        } completion: {
            onSwipe(horse, liked)
            dragOffset = .zero
            isAnimating = false
        }
    }
}

// MARK: - Subviews

private struct SwipeButton: View {
    let symbol: String
    let tint: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 64, height: 64)
                .background(Circle().fill(.background).shadow(color: .black.opacity(0.12), radius: 8, y: 4))
        }
        .accessibilityLabel(label)
    }
}

#Preview { CardStackView(horses: Horse.samples, onSwipe: { _, _ in }, onTap: { _ in }) }
```

### 4.12 `StableDate/Features/Swipe/HorseCardView.swift`

```swift
import SwiftUI

/// Draws one horse. That's it.
struct HorseCardView: View {
    let horse: Horse

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            photo
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                Text(horse.name)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text("\(Copy.age(horse.age)) · \(horse.breed)")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(horse.name), \(Copy.age(horse.age)), \(horse.breed)")
    }

    @ViewBuilder
    private var photo: some View {
        if UIImage(named: horse.imageName) != nil {
            Image(horse.imageName).resizable().scaledToFill()
        } else {
            ZStack {
                Color.rose
                Image(systemName: "hare").font(.system(size: 96)).foregroundStyle(Color.ink.opacity(0.5))
            }
        }
    }
}

#Preview { HorseCardView(horse: Horse.samples[0]).padding() }
```

### 4.13 `StableDate/Features/Swipe/LoadingView.swift`

```swift
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView(Copy.loadingTitle)
            .controlSize(.large)
    }
}

#Preview { LoadingView() }
```

### 4.14 `StableDate/Features/Swipe/EmptyDeckView.swift`

```swift
import SwiftUI

struct EmptyDeckView: View {
    let exhausted: Bool
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(exhausted ? Copy.emptyExhaustedTitle : Copy.emptyNoDataTitle, systemImage: "hare")
        } description: {
            Text(exhausted ? Copy.emptyExhaustedBody : Copy.emptyNoDataBody)
        } actions: {
            Button(exhausted ? Copy.emptyExhaustedButton : Copy.emptyNoDataButton, action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(.lavender)
        }
    }
}

#Preview("No data")   { EmptyDeckView(exhausted: false) {} }
#Preview("Exhausted") { EmptyDeckView(exhausted: true) {} }
```

### 4.15 `StableDate/Features/Swipe/ErrorView.swift`

```swift
import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(message, systemImage: "wifi.slash")
        } description: {
            Text(Copy.errorBody)
        } actions: {
            Button(Copy.errorButton, systemImage: "arrow.clockwise", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(.plum)
        }
    }
}

#Preview { ErrorView(message: Copy.errorTitle) {} }
```

### 4.16 `StableDate/Features/Swipe/MatchOverlayView.swift`

```swift
import SwiftUI

struct MatchOverlayView: View {
    let horse: Horse
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.blush.opacity(0.98).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "sparkles").font(.system(size: 48)).foregroundStyle(Color.ink)
                photo
                Text(Copy.matchTitle).font(.largeTitle.bold())
                Text(Copy.matchBody(name: horse.name)).font(.title3).multilineTextAlignment(.center)
                Button(Copy.matchButton, action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(.ink)
                    .padding(.top, 8)
            }
            .foregroundStyle(Color.ink)
            .padding(32)
        }
    }

    @ViewBuilder
    private var photo: some View {
        Group {
            if UIImage(named: horse.imageName) != nil {
                Image(horse.imageName).resizable().scaledToFill()
            } else {
                Image(systemName: "hare").font(.system(size: 64)).foregroundStyle(Color.ink.opacity(0.5))
            }
        }
        .frame(width: 160, height: 160)
        .background(Color.ink.opacity(0.1))
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.ink, lineWidth: 4))
    }
}

#Preview { MatchOverlayView(horse: Horse.samples[0]) {} }
```

### 4.17 `StableDate/Features/Profile/HorseProfileView.swift`

```swift
import SwiftUI

/// The detail screen. Takes one Horse and draws it. No service, no ViewModel, no network.
struct HorseProfileView: View {
    let horse: Horse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HorseCardView(horse: horse)
                Text(horse.bio).font(.body)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Copy.profileLookingFor).font(.headline).foregroundStyle(.secondary)
                    Text(horse.lookingFor).font(.body)
                }
            }
            .padding(24)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview { HorseProfileView(horse: Horse.samples[0]) }
```

### 4.18 `StableDateTests/SwipeViewModelTests.swift`

```swift
import Foundation
import Testing
@testable import StableDate

@MainActor
@Suite("SwipeViewModel")
struct SwipeViewModelTests {

    private func makeVM(_ result: Result<[Horse], any Error>) -> SwipeViewModel {
        SwipeViewModel(service: MockHorseService(result: result))
    }

    @Test func offlineShowsErrorNotInfiniteSpinner() async {
        let vm = makeVM(.failure(URLError(.notConnectedToInternet)))

        await vm.load()

        #expect(vm.state == .failed(Copy.errorTitle))
    }

    @Test func emptyResponseShowsEmptyState() async {
        let vm = makeVM(.success([]))

        await vm.load()

        #expect(vm.state == .empty)
    }

    @Test func likingAHorseThatLikesYouBackIsAMatch() async {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let crush = Horse.samples.first { $0.likesYouBack }!

        let isMatch = vm.swipe(crush, liked: true)

        #expect(isMatch)
        #expect(vm.matches == [crush])
    }

    @Test func likingAHorseThatDoesNotLikeYouBackIsNotAMatch() async {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let stranger = Horse.samples.first { !$0.likesYouBack }!

        let isMatch = vm.swipe(stranger, liked: true)

        #expect(!isMatch)
        #expect(vm.matches.isEmpty)
    }

    @Test func nopingNeverMatches() async {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let crush = Horse.samples.first { $0.likesYouBack }!

        let isMatch = vm.swipe(crush, liked: false)

        #expect(!isMatch)
        #expect(vm.matches.isEmpty)
    }

    @Test func swipingTheLastHorseShowsEmptyState() async {
        let only = Horse.samples[0]
        let vm = makeVM(.success([only]))
        await vm.load()

        vm.swipe(only, liked: false)

        #expect(vm.state == .empty)
        #expect(vm.hasSwiped)
    }

    @Test func retryAfterFailureLoadsHorses() async {
        let vm = SwipeViewModel(service: FlakyHorseService(horses: Horse.samples))

        await vm.load()
        #expect(vm.state == .failed(Copy.errorTitle))

        await vm.load()
        #expect(vm.state == .loaded(Horse.samples))
    }

    @Test func samplesMatchJSON() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "horses", withExtension: "json"))
        let decoded = try JSONDecoder().decode([Horse].self, from: Data(contentsOf: url))

        #expect(decoded == Horse.samples)
    }
}

/// Fails on the first call, succeeds after. Lives only in the test target.
private actor FlakyHorseService: HorseService {
    private var calls = 0
    private let horses: [Horse]
    init(horses: [Horse]) { self.horses = horses }
    func fetchHorses() async throws -> [Horse] {
        calls += 1
        if calls == 1 { throw URLError(.timedOut) }
        return horses
    }
}

private final class BundleToken {}
```

Add `Data/horses.json` to the **test target** as a bundle resource (not the app target; the app must fetch it from the network). If Opus prefers `Bundle.module`, it would need an SPM package; don't. `Bundle(for:)` with a token class is the plain-Xcode way.

---

## 5. The spaghetti (tag `step-0-spaghetti`) · spec for `StableDate/SwipeView.swift`

This file is the "before." It must be **genuinely long and genuinely working**, not padded with comments. Target **300–500 lines**. Everything below lives in this one file:

1. `struct Horse: Identifiable, Decodable` with a hand-written `init(from decoder:)` using `try?` everywhere (silently defaulting fields). ~40 lines.
2. `struct SwipeView: View` with `@State` for: `horses`, `isLoading`, `matches`, `showMatch`, `matchedName`, `selectedHorse`, `dragOffset`, `cardRotation`, `isAnimating`, `confettiVisible`, `confettiSeed`. The three booleans that will later become the enum must be visibly separate.
3. `.task` block exactly as shown in `02` §2 Step 0: `try?` + `return` on failure, `isLoading = false` only on success. **Bug #1 and #2 live here.**
4. `like(_:)` and `nope(_:)` as two near-identical functions; `nope` contains the copy-pasted `if horse.likesYouBack { matches.append(horse) }`. **Bug #3 lives here.**
5. Card UI inline (no `HorseCardView`): the `ZStack` + gradient + text, repeated for the top card and the peeking cards (copy-paste, slightly different modifiers).
6. Drag gesture, swipe-off animation, haptics, inline.
7. Match overlay inline, with a hand-rolled confetti `Canvas` (~50 lines of pure SwiftUI, seeded randomness).
8. Profile sheet inline as a `.sheet` with a `VStack` (no `HorseProfileView`).
9. Three or four small `private func`s with vague names (`refresh()`, `handle(_:)`, `update()`), and at least one `// TODO: fix later` and one `// don't touch this, it works`.
10. A `#Preview` that hits the real network (so it's useless offline — a visible contrast with Step 3).

It must compile under Swift 6 with no warnings (warnings would be a cheap joke; the point is that it *looks* fine). Run it and confirm: offline → spinner forever; `horses-empty.json` → blank screen with the two buttons and no cards; Nope on Sugar Cube → match overlay.

---

## 6. Intermediate versions of files that differ from final

### 6.1 `SwipeViewModel.swift` at `step-1-wip` and `step-1-split`

```swift
import Foundation
import Observation

@MainActor @Observable
final class SwipeViewModel {
    var horses: [Horse] = []
    var isLoading = true
    var errorMessage: String?               // 👀 remember these three
    private(set) var matches: [Horse] = []

    private let service = LiveHorseService() // 👀 remember this too

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            horses = try await service.fetchHorses()
        } catch {
            errorMessage = "The horses ran away. 🐎💨"
        }
        isLoading = false
    }

    /// Returns true if it's a match.
    func swipe(_ horse: Horse, liked: Bool) -> Bool {
        horses.removeAll { $0.id == horse.id }
        guard liked, horse.likesYouBack else { return false }
        matches.append(horse)
        return true
    }
}
```

(Yes, this version *does* set `isLoading = false` on failure, so after Step 1 the spinner bug turns into a different bug: the View shows `errorMessage` only if the View happens to check it, and at `step-1-split` the View does **not** check it, so the user sees a blank screen on failure. Say on stage: "we moved the bug, we didn't fix it. The three variables can still disagree." The blank-on-empty bug is unchanged. The nope-match bug is fixed as a side effect of there being only one `swipe`.)

### 6.2 `SwipeViewModel.swift` at `step-2-wip` and `step-2-state`

Final version (§4.9) with two differences: `private let service = LiveHorseService()` instead of the injected one (no `init`), and the literal `"The horses ran away. 🐎💨"` instead of `Copy.errorTitle`.

### 6.3 `SwipeViewModel.swift` at `step-3-wip` / `step-3-fake-horses`

`step-3-wip`: same as 6.2. `step-3-fake-horses`: final version (§4.9) with the literal string instead of `Copy.errorTitle`.

### 6.4 `StableDateApp.swift` at `step-0` … `step-3-fake-horses`

```swift
import SwiftUI

@main
struct StableDateApp: App {
    var body: some Scene {
        WindowGroup {
            SwipeView(viewModel: SwipeViewModel(service: LiveHorseService()))   // step-3-fake-horses onward
        }
    }
}
```
(At `step-0` through `step-2-state` it's just `SwipeView()`, because `SwipeView` creates its own `SwipeViewModel()`. At `step-3-wip` it's `SwipeView(viewModel: SwipeViewModel())` and `SwipeView` already has `init(viewModel:)`, so that when Reva adds `init(service:)` to the ViewModel live, the one compile error lands in `StableDateApp.swift`, exactly as the script says, and the fix is one argument.)

### 6.5 `SwipeView.swift` at `step-1-split`

Uses `@State private var viewModel = SwipeViewModel()` and renders:
```swift
if viewModel.isLoading {
    ProgressView("Rounding up horses...")
} else if viewModel.horses.isEmpty {
    // nothing. (bug #2, still here)
} else {
    // card stack using HorseCardView, buttons call handleSwipe
}
```
No reference to `errorMessage` (see 6.1 note). `.task { await viewModel.load() }`.

### 6.6 `SwipeView.swift` at `step-2-wip`

Final `body` (§4.10) with the `switch` **missing** `case .failed`, no `#Preview`s, `@State private var viewModel = SwipeViewModel()` (no `init(viewModel:)` yet), literal strings instead of `Copy`.

### 6.7 Strings before `step-4-tested`

Every view uses string literals matching `03` §4 exactly. `Copy.swift` is introduced only at the final tag, and the commit message says why: "strings in one place so the tests and the slides can quote them."

---

## 7. Definition of done (Opus pastes this filled in)

```
[ ] scripts/verify-tags.sh → all ✓ (paste output)
[ ] scripts/check-rules.sh on step-4-tested → all ✓ (paste output)
[ ] xcodebuild test → 8 tests, 0 failures, < 5 s
[ ] git diff step-4-tested main → empty; work/final deleted
[ ] demo/super-like builds, 9 tests pass, diff vs main ≈ 25 lines
[ ] docs/screenshots/*.png (6 files) + docs/spaghetti.png + docs/previews.png
[ ] NOTES.md has: real line count of step-0 SwipeView.swift, every judgment call, anything Reva must do by hand
[ ] README.md has the demo cheat sheet and tag table
[ ] Pushed to GitHub; raw URL for Data/horses.json returns 200 and decodes
```

## 8. What Reva does after Opus is done (24 Oct minus 5 days)

1. Replace the 10 placeholder images and the AppIcon (`06` §6 has the prompts), commit as `assets: real horses`, **re-tag `step-4-tested` and `main` only** (earlier tags keep placeholders; nobody will notice and the videos stay valid).
2. Clone fresh into a second folder and run `scripts/verify-tags.sh` there. If it passes on a clean clone, it'll pass on stage.
3. Walk `02-stable-date-walkthrough-script.md` once with a timer. Record the backup videos. Take the AI-moment screenshots from `demo/super-like`.
4. Put the line count from `NOTES.md` into Slide 6 and Slide 8.

---

## Tambahan 16 Okt 2026 · switch demo tanpa edit URL (semua tag)

Supaya live demo nggak perlu edit URL + rebuild:

- Di **setiap tag** (step-0 sampai step-4), URL data dibaca dari env var `STABLE_DATE_URL` di dalam blok `#if DEBUG`; kalau kosong, pakai URL GitHub raw biasa.
- Buat tiga shared scheme: **Live** (tanpa env var), **Offline** (`STABLE_DATE_URL=https://horses.invalid/horses.json`, host yang nggak ada → `URLError(.cannotFindHost)`, terasa seperti offline, cocok dengan copy "Check your connection…"), **Empty** (`…/Data/horses-empty.json`).
- Saat demo: ganti scheme lalu ⌃⌘R (Run Without Building).
- Jangan pakai Network Link Conditioner atau matikan Wi-Fi (memutus Webex).
- Test target tetap tidak menyentuh network (MockHorseService). Test yang mengakses `SwipeViewModel` ditandai `@MainActor` (project Xcode 16, tanpa default MainActor isolation); `SwipeViewModel.State` conform ke `Equatable`.
