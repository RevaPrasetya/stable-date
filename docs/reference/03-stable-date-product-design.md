# Stable Date 🐴 · Product Design Document (PRD)
### "Tinder for horses" · the sample app for *Maintainable iOS Apps from a Builder's Perspective*
Version 1.0 · 7 Oct 2026 · Owner: Reva Prasetya · Builder: Claude Opus 5.5 (see `05-stable-date-implementation-plan.md`)

---

## 1. Why this app exists

Stable Date is not a product. It's a **teaching prop** for a 40-minute live walkthrough in front of students and junior iOS developers (Swift Bali × Swift Batam, 24 Oct 2026). Every product decision below serves one of three goals, in this order:

1. **It must demonstrate the TOR:** a list-and-detail feature, async data loading with loading/success/empty/error states, a replaceable data service (dependency injection), and one focused test.
2. **It must be funny.** The humor lives in copy and in the fake bug reports, never in the code structure. The structure is the serious part.
3. **It must be boring to build and impossible to break mid-demo.** No backend, no auth, no third-party packages, no remote images.

If a feature idea doesn't serve one of those, it's out.

---

## 2. Scope

### In scope (v1, shipped before 24 Oct)

| ID | Feature | Serves | Notes |
|---|---|---|---|
| F1 | **Swipe deck**: a stack of horse cards; the top card is the one you're deciding on | TOR "list" | Buttons Nope ✖️ / Like ❤️ are the primary interaction. Drag-to-swipe is a nice-to-have on top. |
| F2 | **Horse profile** (detail): tap the top card → sheet with photo, name, age, breed, bio, "looking for" | TOR "detail" | Pure display view. No logic. |
| F3 | **Match rule**: liking a horse whose `likesYouBack == true` produces a match; noping never does | A real business rule worth testing | The one piece of logic in the app. |
| F4 | **Match celebration**: full-screen overlay when F3 fires | Payoff for the audience | Dismiss with "Keep trotting". |
| F5 | **Four screen states**: loading, loaded, empty, failed (with **Try again**) | TOR "states" | The core lesson. |
| F6 | **Live data from the internet**: `horses.json` fetched from the repo's raw GitHub URL | TOR "network" + "public or mock data source" | Lets us demo "offline". |
| F7 | **Mock data source** for previews and tests | TOR "replaceable data service" | Fake horses. |
| F8 | **Matches count badge** in the toolbar ("❤️ 2") | Makes `matches` visible so the match test feels real | Tiny. |

### Explicitly out of scope (say it on stage: "Stable Date has no chat. Horses can't type.")

Login, chat, push notifications, persistence between launches, a real backend, undo, filters, settings, analytics, remote image loading, localization. A **Matches list** screen is a stretch goal only if the build finishes a day early; it is never shown in the walkthrough.

### Non-functional requirements

| Requirement | Target |
|---|---|
| Platforms | iOS 17.0+, iPhone only, portrait only |
| Toolchain | Xcode 16.x, Swift 6 language mode, strict concurrency on |
| Dependencies | **Zero** third-party packages |
| Launch to first card (online) | < 2 s on Simulator |
| Build from clean | < 60 s |
| Tests | Swift Testing, run in < 3 s, no network access |
| Accessibility | Dynamic Type works up to XXL; all buttons have labels; VoiceOver reads each card as one element |
| Appearance | Light mode is the reference (matches the slides). Dark mode must not look broken. |

---

## 3. Screens and flows

### 3.1 Screen map

```
StableDateApp
└── NavigationStack
    └── SwipeView  (switches on state)
        ├── LoadingView            state == .loading
        ├── CardStackView          state == .loaded(horses)
        │     ├── HorseCardView (top + 2 peeking behind)
        │     ├── Nope / Like buttons
        │     └── .sheet → HorseProfileView(horse)       ← the "detail"
        │     └── .overlay → MatchOverlayView(horse)     ← on match
        ├── EmptyDeckView          state == .empty
        └── ErrorView(retry)       state == .failed(message)
```

One screen, four states, one sheet, one overlay. That's the whole app.

### 3.2 Primary flow (happy path)

1. Launch → `.loading` ("Rounding up horses...") → fetch `horses.json`.
2. `.loaded(horses)` → top card visible, two cards peeking behind it, Nope/Like buttons below.
3. User taps **Like** on a horse with `likesYouBack == true` → `MatchOverlayView` appears with the horse's photo and "It's a match!" copy. **Keep trotting** dismisses it. The matches badge increments.
4. User taps **Nope** or **Like** on other horses → card animates off (left for Nope, right for Like), next card becomes top.
5. User taps the top card → `HorseProfileView` sheet. Swipe down to dismiss. Deck unchanged.
6. Last card swiped → `.empty` with the "touch grass" copy and a **Start over** button that reloads.

### 3.3 Failure flows

| Trigger | Result |
|---|---|
| No network / 404 / bad JSON on launch | `.failed("The horses ran away. 🐎💨")` with **Try again** → `.loading` → retry |
| JSON returns `[]` | `.empty` with the "no horses nearby" copy and **Try again** |
| Network drops *after* load | Nothing. Data is already in memory. (Say this if asked: the app doesn't need the network after the first fetch.) |

### 3.4 State matrix (the slide-worthy table)

| State | What the user sees | Primary action | Transitions to |
|---|---|---|---|
| `loading` | Spinner + "Rounding up horses..." | none | `loaded`, `empty`, `failed` |
| `loaded([Horse])` | Card stack + buttons + badge | Nope / Like / tap card | `loaded` (fewer horses), `empty` (last one swiped) |
| `empty` | Illustration + copy + button | **Try again** (no data) / **Start over** (swiped all) | `loading` |
| `failed(String)` | Illustration + message + button | **Try again** | `loading` |

Exactly one state at a time. The View never holds `isLoading`, `errorMessage`, or `horses` as separate variables after Step 2.

The two empty variants (no data vs. swiped all) are the **same state** with different copy. The ViewModel tracks `hasSeenAtLeastOneHorse` to pick the copy; this keeps the enum at four cases, which is what the slides show. (Trade-off to mention if asked: a fifth case `.exhausted` would be cleaner in a bigger app.)

---

## 4. Copy (the jokes live here)

All user-facing strings, final. Keep them in one file (`Copy.swift`) so they're easy to find and the slides can quote them exactly.

| Key | Text |
|---|---|
| `app.name` | Stable Date |
| `app.tagline` | Swipe right on your soulmare. |
| `loading.title` | Rounding up horses... |
| `empty.noData.title` | No horses nearby. |
| `empty.noData.body` | Even horses have standards. |
| `empty.noData.button` | Try again |
| `empty.exhausted.title` | You've seen every horse. |
| `empty.exhausted.body` | Go touch grass. You're a horse, you'll enjoy it. |
| `empty.exhausted.button` | Start over |
| `error.title` | The horses ran away. 🐎💨 |
| `error.body` | Check your connection and we'll round them up again. |
| `error.button` | Try again |
| `match.title` | It's a match! |
| `match.body` | You and **{name}** are now trotting together. |
| `match.button` | Keep trotting |
| `card.likesYouBack.hint` | *(not shown; it's a secret)* |
| `button.nope.a11y` | Nope |
| `button.like.a11y` | Like |
| `profile.lookingFor` | Looking for |
| `profile.age` | {age} years |
| `badge.matches.a11y` | {count} matches |

Rule: the `.failed(String)` payload is **always** `error.title`. The test asserts on it, so changing the string means changing the test (that's a feature: tests notice copy changes too).

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

`id` is a `String` slug, not a `UUID`, so `horses.json` is hand-editable and stable across builds. Images are **bundled** in the asset catalog and referenced by name; the JSON never carries URLs, so nothing can 404 mid-demo.

### 5.2 Dataset: `horses.json` (10 horses, 2 like you back)

The authoritative copy is `horses.json` next to this document. Summary:

| # | id | name | age | breed | likesYouBack |
|---|---|---|---|---|---|
| 1 | sir-gallops-a-lot | Sir Gallops-a-Lot | 7 | Thoroughbred | **true** |
| 2 | hay-girl | Hay Girl | 5 | Arabian | false |
| 3 | mane-attraction | Mane Attraction | 6 | Friesian | false |
| 4 | neigh-sayer | Neigh Sayer | 9 | Quarter Horse | false |
| 5 | oat-milk-latte | Oat Milk Latte | 3 | Shetland Pony | false |
| 6 | hoof-hearted | Hoof Hearted | 8 | Appaloosa | false |
| 7 | dusty-trails | Dusty Trails | 12 | Mustang | false |
| 8 | sugar-cube | Sugar Cube | 4 | Welsh Pony | **true** |
| 9 | clip-clop | Clip Clop | 6 | Clydesdale | false |
| 10 | professor-whinny | Professor Whinny | 15 | Lipizzaner | false |

Sir Gallops-a-Lot is **first** in the array so the match demo happens on the very first Like in the tour. Sugar Cube is 8th so the "swipe left on a horse that likes you" bug is reachable in Step 0 without swiping the whole deck.

`Horse.samples` (used by previews and tests) is the same 10 horses, defined in Swift, so tests never read the JSON file.

### 5.3 Live source

`LiveHorseService` fetches `https://raw.githubusercontent.com/<owner>/stable-date-ios/main/Data/horses.json`. The file lives in the repo under `Data/` (not inside the app bundle) so it's one source of truth and the URL is visible on stage as "a real network call."

A second file `Data/horses-empty.json` (`[]`) exists so the empty state can be demoed from the network without editing code.

---

## 6. Visual design

Reference feel: light, white and soft pink dating-app UI (glassy chips, big rounded photo card, vertical ✕ ★ ♥ buttons, bottom tab bar), slightly ridiculous because everyone is a horse. No saturated orange. Nothing should look like a copy of any real dating app's UI or branding.

| Token | Value | Use |
|---|---|---|
| `brand.rose` | `#E25587` | Primary accent, Like button fill, “Say hello” button, active tab |
| `brand.blush` | `#FCE7F0` | Secondary buttons (“Keep trotting”), match screen gradient, chips |
| `brand.plum` | `#B23A6F` | Nope icon tint, error accents, matches badge |
| `brand.lavender` | `#7C5CE0` on `#EDE9FE` | Super-like ★ button, match % chip |
| `brand.ink` | `#1F1A24` (secondary `#8A8394`) | Primary text (light mode) |
| `surface.app` | `#FFFFFF` / `#FFF7FA` | App background (white, faint blush) |
| `surface.photo` | `#FDE2EC` `#E9E3FF` `#DDF5EA` `#FFE7D6` | Pastel backgrounds behind the horse on cards |
| `surface.card` | system background + 24pt radius + soft shadow | Cards |
| Type | SF Pro (system), `.largeTitle.bold()` for horse name on card, `.title3` for breed/age, `.body` for bio | Dynamic Type everywhere |
| Icons | SF Symbols only: `xmark`, `heart.fill`, `heart`, `hare`, `wifi.slash`, `arrow.clockwise`, `sparkles` | No custom icons |

### Card

- Portrait, fills width minus 24pt margins, aspect 3:4.
- Photo fills the card; a bottom gradient (clear → 70% ink) carries name, age, breed in white.
- Two cards peek behind the top card (offset 8pt down, scaled 0.96 and 0.92).
- Tap anywhere on the top card → profile sheet.
- Swipe-off animation: 0.35 s, rotates ±12°, moves off-screen in the swipe direction. Buttons trigger the same animation.

### Buttons

- Three 62pt circles stacked vertically on the lower right of the card: Nope (white, plum `xmark`), Super like (lavender, `star.fill`), Like (rose fill, white `heart.fill`).
- 12pt gap between them. Haptic `.medium` on tap. Header: “Discover” + location, back and filter buttons in white rounded squares; chips on the card for distance (“1 km”) and match %.

### Match overlay

- Full-screen blush gradient (`#FFF7FA` → `#FCE7F0`) at 0.98 opacity.
- Two tilted photo cards (yours and the horse's) with small heart badges, “CONGRATULATIONS” caption in rose, "It's a match!!" in `.largeTitle.bold()`, body copy, **Say hello** (rose fill, white text; chat is out of scope, so it just dismisses) and **Keep trotting** (white with blush border).
- Appears with a spring; confetti is optional and must be pure SwiftUI (no package).

### Empty / error screens

Use `ContentUnavailableView` (iOS 17) with a custom SF Symbol: `hare` for empty, `wifi.slash` for error. Button below.

### Images

10 horse photos, `horse-01` … `horse-10`, 1200×1600 JPEG, ≤ 400 KB each, **AI-generated or CC0**. Keep a `CREDITS.md` in the repo. If an image is missing, `HorseCardView` shows a `hare` symbol on a pastel `surface.photo` background rather than a blank card. (That fallback is also what previews show before images are added.)

### App icon

White rounded square, soft pink heart, cartoon chestnut horse head with big eyes (original drawing, see deck assets). Single 1024×1024 PNG in the asset catalog.

---

## 7. Interaction details that affect code

| Behavior | Decision | Why |
|---|---|---|
| Who decides a match | **ViewModel** (`swipe(_:liked:) -> Bool`) | It's the business rule; it has to be testable without UI |
| Who shows the overlay | **View**, from the Bool the ViewModel returns | Presentation stays in the View |
| Does the deck reorder | No. Top card is always `horses.first` | Simple, predictable, matches the mental model |
| Double-tapping Like fast | Second tap is ignored while the swipe animation runs | Avoids double-removal |
| Rotation | Locked to portrait | One less thing to demo |
| Retry from `.failed` | Same `load()` as launch | One code path |

---

## 8. Acceptance criteria (what "done" means for the build)

**Functional**
- [ ] Launch online shows the first card (Sir Gallops-a-Lot) within 2 s.
- [ ] Like on Sir Gallops-a-Lot shows the match overlay with his name; badge reads 1.
- [ ] Nope on Sugar Cube does **not** show a match (final tag) and **does** (step-0 tag).
- [ ] Tapping a card opens the profile sheet with all six fields.
- [ ] Swiping all 10 horses shows the "touch grass" empty screen; **Start over** reloads.
- [ ] Network Link Conditioner 100% loss → error screen with **Try again**; turning it off and tapping retry loads horses.
- [ ] Pointing the service at `horses-empty.json` → "No horses nearby" empty screen.

**Structural (these are the lesson)**
- [ ] Each of the git tags in `04-stable-date-architecture.md` §8 checks out and builds (or fails exactly as intended).
- [ ] At the final tag, `SwipeView` contains no `URL`, no `URLSession`, no `JSONDecoder`.
- [ ] At the final tag, `SwipeViewModel` has exactly one stored piece of screen state: `state`.
- [ ] `StableDateApp.swift` is the only file that mentions `LiveHorseService`.
- [ ] Four `#Preview`s on `SwipeView` render in the canvas without network.
- [ ] `⌘U` is green; the "break it on purpose" edit turns exactly `nopingNeverMatches` red.

**Content**
- [ ] All copy matches §4 exactly.
- [ ] 10 images present, credited, ≤ 400 KB each.
- [ ] `step-0-spaghetti`'s `SwipeView.swift` is ≥ 300 lines and the real count is written into the slides.
