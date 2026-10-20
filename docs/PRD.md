# Stable Date 🐴 · PRD
### "Tinder for horses", the sample app for *Maintainable iOS Apps from a Builder's Perspective*
Version 2.0 · 20 Oct 2026 · Owner: Reva Prasetya · Event: Swift Bali × Swift Batam webinar, Sat 24 Oct 2026, 10.00–12.00 WIB (Webex)

> This is the product spec. The build order, project settings, and anything that overrides older docs live in [`DIRECTION.md`](DIRECTION.md). How each git tag is used on stage is in [`WALKTHROUGH.md`](WALKTHROUGH.md).

---

## 1. Why this app exists

Stable Date is not a product. It is a **teaching prop** for a 40-minute live walkthrough in front of students and junior iOS developers. Every product decision serves one of three goals, in this order:

1. **It must demonstrate the event outline:** clean architecture (UI, logic and data separated), reliable features (loading/success/empty/error states, a replaceable data service), and maintainability (one focused test suite, small files, clear names).
2. **It must be funny.** The humor lives in the copy and the fake bug reports, never in the code structure. The structure is the serious part.
3. **It must be boring to build and impossible to break mid-demo.** No backend, no auth, no third-party packages, no remote images.

If a feature idea doesn't serve one of those, it's out.

Tagline: **Swipe right on your soulmare.**

---

## 2. Scope

### In scope

| ID | Feature | Serves | Notes |
|---|---|---|---|
| F1 | **Swipe deck**: a stack of horse cards; the top card is the one you're deciding on | "list" | Buttons ✕ Nope / ★ Super like / ♥ Like are the primary interaction. Drag-to-swipe is a nice-to-have. |
| F2 | **Horse profile** (detail): tap the top card → sheet with photo, name, age, breed, bio, "looking for" | "detail" | Pure display view. No logic. |
| F3 | **Match rule**: liking a horse whose `likesYouBack == true` produces a match; noping never does | A real business rule worth testing | The one piece of logic in the app. On the main tags ★ behaves exactly like ♥ (see DIRECTION D3). |
| F4 | **Match screen**: full-screen overlay when F3 fires | Payoff for the audience | "Say hello" and "Keep trotting" both dismiss it. |
| F5 | **Four screen states**: loading, loaded, empty, failed (with **Try again**) | "states" | The core lesson. |
| F6 | **Live data from the internet**: `Data/horses.json` fetched from this repo's raw GitHub URL | "network" | Lets us demo "offline" and "empty". |
| F7 | **Mock data source** for previews and tests | "replaceable data service" | Fake horses. |
| F8 | **Matches count badge** on the ♥ tab of the bottom bar | Makes `matches` visible so the match test feels real | Tiny. |

### Out of scope (say it on stage: "Stable Date has no chat. Horses can't type.")

Login, chat ("Say hello" just dismisses), push notifications, persistence between launches, a real backend, undo, filters (the filter button is decorative), settings, analytics, remote image loading, localization, working tabs (the tab bar is decorative except for the badge). A Matches list screen is never built.

### Non-functional requirements

| Requirement | Target |
|---|---|
| Platforms | iOS 17.0+, iPhone only, portrait only |
| Toolchain | Xcode 27, Swift 6 language mode (strict concurrency), default actor isolation `nonisolated` (see DIRECTION D1) |
| Dependencies | **Zero** third-party packages |
| Launch to first card (online) | < 2 s on Simulator |
| Tests | Swift Testing, 8 tests, < 1 s of test time, no network access |
| Accessibility | Dynamic Type up to XXL without clipping the card title; every button has a label; VoiceOver reads each card as one element ("Sir Gallops-a-Lot, 7 years, Thoroughbred") |
| Appearance | Light mode is the reference (matches the slides). Dark mode must not look broken. |

---

## 3. Screens and flows

### 3.1 Screen map

```
StableDateApp
└── SwipeView  (switches on state)
    ├── DiscoverHeader         always (title "Discover", "Ubud, Bali", decorative back + filter buttons)
    ├── LoadingView            state == .loading
    ├── CardStackView          state == .loaded(horses)
    │     ├── HorseCardView (top + 2 peeking behind), chips "N km" and "♥ N%"
    │     ├── vertical ✕ ★ ♥ buttons on the lower right of the card
    │     ├── .sheet → HorseProfileView(horse)      ← the "detail"
    │     └── .overlay → MatchOverlayView(horse)    ← on match
    ├── EmptyDeckView          state == .empty
    ├── ErrorView(retry)       state == .failed(message)
    └── StableTabBar           always (decorative; ♥ tab carries the matches badge)
```

One screen, four states, one sheet, one overlay. That's the whole app. Reference renders: [`assets/mockups/`](assets/mockups/) (`discover`, `loading`, `empty`, `failed`, `match`, and `blank` = what Bug 2 looks like).

### 3.2 Primary flow (happy path)

1. Launch → `.loading` ("Rounding up horses...") → fetch `horses.json`.
2. `.loaded(horses)` → top card visible, two cards peeking behind it, vertical ✕ ★ ♥ buttons.
3. Tap ♥ (or ★) on a horse with `likesYouBack == true` → match screen with both photos, "It's a match!!" and the horse's name. **Keep trotting** or **Say hello** dismisses it. The badge increments.
4. Tap ✕ or ♥ on other horses → the card animates off (left for ✕, right for ♥/★), the next card becomes top.
5. Tap the top card → `HorseProfileView` sheet. Swipe down to dismiss. Deck unchanged.
6. Last card swiped → `.empty` with the "touch grass" copy and a **Start over** button that reloads.

### 3.3 Failure flows

| Trigger | Result |
|---|---|
| No network / unknown host / 404 / bad JSON on launch | `.failed("The horses ran away. 🐎💨")` with **Try again** → `.loading` → retry |
| JSON returns `[]` | `.empty` with the "No horses nearby." copy and **Try again** |
| Network drops *after* load | Nothing. Data is already in memory. |

### 3.4 State matrix

| State | What the user sees | Primary action | Transitions to |
|---|---|---|---|
| `loading` | Shimmering card placeholder + spinner + "Rounding up horses..." | none | `loaded`, `empty`, `failed` |
| `loaded([Horse])` | Card stack + buttons | ✕ / ★ / ♥ / tap card | `loaded` (fewer horses), `empty` (last one swiped) |
| `empty` | Horse in a pastel circle + copy + button | **Try again** (no data) / **Start over** (swiped all) | `loading` |
| `failed(String)` | 🐎 in a peach circle + message + button | **Try again** | `loading` |

Exactly one state at a time. After Step 2 the code never holds `isLoading`, `errorMessage`, or `horses` as separate variables.

The two empty variants (no data vs. swiped all) are the **same state** with different copy; the ViewModel's `hasSwiped` flag picks the copy. That keeps the enum at four cases, which is what the slides show.

---

## 4. Copy (the jokes live here)

Final strings. From tag `step-4-tested` they live in `App/Copy.swift`; before that, the same literals sit in the views.

| Key (`Copy.`) | Text |
|---|---|
| `appName` | Stable Date |
| `tagline` | Swipe right on your soulmare. |
| `discoverTitle` | Discover |
| `discoverLocation` | Ubud, Bali |
| `loadingTitle` | Rounding up horses... |
| `emptyNoDataTitle` | No horses nearby. |
| `emptyNoDataBody` | Even horses have standards. |
| `emptyNoDataButton` | Try again |
| `emptyExhaustedTitle` | You've seen every horse. |
| `emptyExhaustedBody` | Go touch grass. You're a horse, you'll enjoy it. |
| `emptyExhaustedButton` | Start over |
| `errorTitle` | The horses ran away. 🐎💨 |
| `errorBody` | Check your connection and we'll round them up again. |
| `errorButton` | Try again |
| `matchCaption` | CONGRATULATIONS |
| `matchTitle` | It's a match!! |
| `matchBody(name:)` | You and **{name}** are now trotting together. |
| `sayHelloButton` | Say hello |
| `matchButton` | Keep trotting |
| `nopeLabel` / `superLikeLabel` / `likeLabel` | Nope / Super like / Like (accessibility labels) |
| `profileLookingFor` | Looking for |
| `age(_:)` | {age} years |
| `distance(_:)` | {km} km |
| `matchPercent(_:)` | {percent}% |
| `matchesBadge(_:)` | {count} matches (accessibility label) |

Rule: the `.failed(String)` payload is **always** `errorTitle`. The test asserts on it, so changing the string means changing the test. That's a feature: tests notice copy changes too.

`likesYouBack` is never shown in the UI. It's a secret.

---

## 5. Data

### 5.1 Model

```swift
struct Horse: Identifiable, Codable, Hashable, Sendable {
    let id: String          // stable slug, e.g. "sir-gallops-a-lot"
    let name: String
    let age: Int
    let breed: String
    let bio: String
    let lookingFor: String
    let imageName: String   // asset catalog name, e.g. "horse-01"
    let likesYouBack: Bool  // the secret that makes the match rule testable
}
```

`id` is a `String` slug so `horses.json` is hand-editable. Images are **bundled** in the asset catalog and referenced by name; the JSON never carries URLs, so nothing can 404 mid-demo.

### 5.2 Dataset: [`Data/horses.json`](../Data/horses.json) (10 horses, 2 like you back)

| # | id | name | age | breed | likesYouBack | image (art) |
|---|---|---|---|---|---|---|
| 1 | sir-gallops-a-lot | Sir Gallops-a-Lot | 7 | Thoroughbred | **true** | horse-01 (chestnut, pink) |
| 2 | hay-girl | Hay Girl | 5 | Arabian | false | horse-02 (grey, lavender) |
| 3 | mane-attraction | Mane Attraction | 6 | Friesian | false | horse-03 (black, peach) |
| 4 | neigh-sayer | Neigh Sayer | 9 | Quarter Horse | false | horse-04 (bay, mint) |
| 5 | oat-milk-latte | Oat Milk Latte | 3 | Shetland Pony | false | horse-05 (cream, pink) |
| 6 | hoof-hearted | Hoof Hearted | 8 | Appaloosa | false | horse-06 (grey, peach) |
| 7 | dusty-trails | Dusty Trails | 12 | Mustang | false | horse-07 (bay, lavender) |
| 8 | sugar-cube | Sugar Cube | 4 | Welsh Pony | **true** | horse-08 (cream, mint) |
| 9 | clip-clop | Clip Clop | 6 | Clydesdale | false | horse-09 (chestnut, lavender) |
| 10 | professor-whinny | Professor Whinny | 15 | Lipizzaner | false | horse-10 (grey, mint) |

Sir Gallops-a-Lot is **first** so the match demo (♥) and Bug 3 (✕ still matches) both happen on the very first card. Sugar Cube is 8th as a second chance.

`Horse.samples` (previews and tests) is the same 10 horses written in Swift, so tests never need the network. One test (`samplesMatchJSON`) checks that the Swift samples and the JSON file agree.

### 5.3 Live source

`LiveHorseService` fetches `https://raw.githubusercontent.com/<owner>/stable-date/main/Data/horses.json`. `Data/horses-empty.json` (`[]`) exists so the empty state can be demoed from the network without editing code. In Debug builds the URL can be overridden with the `STABLE_DATE_URL` environment variable, which is what the **Live / Offline / Empty** schemes do (DIRECTION §7).

---

## 6. Visual design

Reference feel: light, white and soft pink dating-app UI (glassy chips, big rounded photo card, vertical ✕ ★ ♥ buttons, bottom tab bar), slightly ridiculous because everyone is a horse. Nothing should look like a copy of any real dating app's UI or branding. The renders in [`assets/mockups/`](assets/mockups/) are the target; match their layout and colors, not their pixels.

| Token (asset catalog color → generated `Color.` symbol) | Value | Use |
|---|---|---|
| `Rose` → `.rose` | `#E25587` | Primary accent, ♥ button fill, "Say hello", active tab, spinner |
| `Blush` → `.blush` | `#FCE7F0` | "Keep trotting" border, match screen gradient end, chips |
| `Plum` → `.plum` | `#B23A6F` | ✕ icon tint, error accents |
| `Lavender` → `.lavender` | `#7C5CE0` | ★ icon, match % chip text |
| `LavenderSoft` → `.lavenderSoft` | `#EDE9FE` | ★ button fill, match % chip fill |
| `Ink` → `.ink` | `#1F1A24` (dark: `#F5F5F7`) | Primary text |
| `InkSecondary` → `.inkSecondary` | `#8A8394` | Secondary text |
| `AppBackground` → `.appBackground` | `#FFF7FA` (dark: `#17121A`) | Screen background |
| `PhotoPink` `PhotoLavender` `PhotoMint` `PhotoPeach` | `#FDE2EC` `#E9E3FF` `#DDF5EA` `#FFE7D6` | Pastels behind horses (already baked into the horse PNGs; use them for circles and placeholders) |
| Type | SF Pro (system). Horse name on card `.title.bold()`, breed/bio `.subheadline`, match title `.largeTitle.bold()` | Dynamic Type everywhere |
| Icons | SF Symbols: `xmark`, `star.fill`, `heart.fill`, `heart`, `chevron.left`, `slider.horizontal.3`, `mappin`, `rectangle.stack.fill`, `bubble.left`, `person`, `hare` | No custom icon fonts |

### Discover header
Title "Discover" (bold) with "Ubud, Bali" below it, centered. A white rounded-square button on each side: `chevron.left` (left) and `slider.horizontal.3` (right). Both are decorative (no action, still have accessibility labels).

### Card
- Fills the width minus 24pt margins, aspect 3:4, 32pt corner radius, soft rose-tinted shadow.
- The horse PNG fills the card. A bottom gradient (clear → 70% ink) carries "Name, age" (bold, white) and "Breed · bio" (one line, truncated, white 85%).
- Two glass chips at the top: `mappin` + distance on the left, `heart.fill` + match % on the right (lavender text). Both are decorative and computed in the view from `age` only: distance = `age % 4 + 1` km, match % = `70 + (age * 7) % 29`. They never use `likesYouBack`.
- Two cards peek behind the top card (offset 8pt down, scaled 0.96 and 0.92).
- Tap anywhere on the top card → profile sheet.
- Swipe-off animation: 0.35 s, rotates ±12°, moves off-screen. Buttons trigger the same animation. A second tap during the animation is ignored.

### Buttons
Three 62pt circles stacked vertically, 12pt apart, overlapping the lower-right edge of the card: ✕ Nope (white, plum `xmark`), ★ Super like (`lavenderSoft` fill, lavender `star.fill`), ♥ Like (rose fill, white `heart.fill`). Haptic `.medium` on tap.

### Tab bar
Four icons in a white bar at the bottom: `rectangle.stack.fill` (active, rose), `heart` (shows the matches count as a small rose badge when > 0), `bubble.left`, `person`. Decorative apart from the badge.

### Match overlay
- Full-screen gradient `#FFF7FA` → `#FCE7F0`.
- Two tilted photo cards (horse-04 as "you", the matched horse on top) with white borders and small heart badges.
- "CONGRATULATIONS" caption in rose, letter-spaced; "It's a match!!" in `.largeTitle.bold()`; body copy with the horse's name in bold.
- **Say hello** (rose capsule, white text) and **Keep trotting** (white capsule, blush border). Both dismiss.
- Appears with a spring. Confetti optional, pure SwiftUI only.

### Loading / empty / error
- Loading: a shimmering rounded placeholder where the card would be, a rose spinner and "Rounding up horses...".
- Empty: a 180pt pastel circle with a horse (horse-02), title, body, rose-outlined capsule button.
- Error: a 180pt peach circle with 🐎, title, body, rose-filled capsule button.

### Images and icon
`horse-01` … `horse-10` (1200×1600 PNG, original cartoon art made for this talk, already in `Assets.xcassets`). If an image is missing, `HorseCardView` shows `hare` on a pastel background instead of a blank card. The app icon (`AppIcon`, 1024×1024) is also already in the catalog.

---

## 7. Interaction details that affect code

| Behavior | Decision | Why |
|---|---|---|
| Who decides a match | **ViewModel** (`swipe(_:liked:) -> Bool`) | It's the business rule; it has to be testable without UI |
| Who shows the overlay | **View**, from the Bool the ViewModel returns | Presentation stays in the View |
| ★ on the main tags | Calls the same path as ♥ (`liked: true`) | The real Super Like is the AI-moment feature (branch `demo/super-like`) |
| Does the deck reorder | No. Top card is always `horses.first` | Predictable |
| Double-tapping fast | Ignored while the swipe animation runs | Avoids double removal |
| Rotation | Portrait only | One less thing to demo |
| Retry from `.failed` | Same `load()` as launch | One code path |

---

## 8. Acceptance criteria

**Functional (final tag)**
- [ ] Scheme **Live**: first card is Sir Gallops-a-Lot within 2 s.
- [ ] ♥ on Sir Gallops-a-Lot shows the match screen with his name; the ♥ tab badge reads 1.
- [ ] ✕ on Sir Gallops-a-Lot does **not** match (final tag) and **does** (step-0 tag).
- [ ] Tapping a card opens the profile sheet with all six fields.
- [ ] Swiping all 10 horses shows the "touch grass" screen; **Start over** reloads.
- [ ] Scheme **Offline**: error screen; **Try again** goes to loading and back to error.
- [ ] Scheme **Empty**: "No horses nearby." screen.

**Structural (these are the lesson)**
- [ ] Every tag in DIRECTION §5 checks out and builds, except `step-2-wip`, which fails with exactly one "must be exhaustive" error.
- [ ] At the final tag, no file under `Features/` mentions `URL(`, `URLSession` or `JSONDecoder`.
- [ ] At the final tag, `SwipeViewModel` has exactly one stored piece of screen state: `state` (plus `matches` and `hasSwiped`).
- [ ] `StableDateApp.swift` is the only file that constructs `LiveHorseService`.
- [ ] Four `#Preview`s on `SwipeView` render without network.
- [ ] ⌘U: 8 tests green; the "break it on purpose" edit (`guard liked, horse.likesYouBack` → `guard horse.likesYouBack`) turns exactly `nopingNeverMatches` red.

**Content**
- [ ] All copy matches §4 exactly.
- [ ] `step-0-spaghetti`'s `SwipeView.swift` is 300–500 real lines; the count is written to `NOTES.md` for the slides.
