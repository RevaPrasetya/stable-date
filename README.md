# Stable Date 🐴
**Swipe right on your soulmare.**

A tiny SwiftUI dating app for horses, built to be broken and fixed live in the Swift Bali × Swift Batam webinar *Maintainable iOS Apps from a Builder's Perspective* (Sat 24 Oct 2026, Reva Prasetya).

The app has three bugs on purpose. The git tags fix them one small step at a time:

| Tag | Step | What you'll notice | Bugs left |
|---|---|---|---|
| `step-0-spaghetti` | 0 · Spaghetti | Everything in one 300+ line View. Works… until it doesn't. | 1 spinner forever · 2 blank screen on empty · 3 ✕ still matches |
| `step-1-wip` | 1 · Split (start) | Model, service and ViewModel files exist; the View still does its own networking | 1 · 2 · 3 |
| `step-1-split` | 1 · Split | One file, one job. One `swipe(_:liked:)` instead of copy-pasted `like`/`nope` | 1 · 2 |
| `step-2-wip` | 2 · State (start) | **Doesn't compile on purpose**: the `switch` forgot `.failed` | — |
| `step-2-state` | 2 · State | One `State` enum instead of three variables that can disagree | none |
| `step-3-wip` | 3 · Fake horses (start) | `HorseService` protocol and a mock exist; the ViewModel still builds its own service | none |
| `step-3-fake-horses` | 3 · Fake horses | Service passed in through `init`; four previews that work offline | none |
| `step-4-tested` | 4 · One test | 8 Swift Testing tests lock the bugs out. This is `main`. | none, locked |

Branch `demo/super-like` adds a real Super Like on top of `step-4-tested`.

**Try it yourself:** check out `step-0-spaghetti`, reproduce the three bugs, and fix them without peeking at the next tag.

## Run it
- Xcode 27, iOS 17+ Simulator. Open `stable-date.xcodeproj`.
- Pick a scheme and press ⌘R:
  - **Live** loads `Data/horses.json` from GitHub.
  - **Offline** points at a host that doesn't exist (error screen).
  - **Empty** loads `Data/horses-empty.json` (empty screen).
- Switching scenarios during a demo: change scheme, then ⌃⌘R (Run Without Building).
- Tests: ⌘U (at `step-4-tested`). No network needed.

## Cheat sheet
```bash
git checkout -f step-1-wip           # jump to a step (discards local edits)
bash scripts/verify-tags.sh          # every tag builds (step-2-wip fails on purpose)
bash scripts/check-rules.sh          # the architecture rules, as greps
bash scripts/screenshots.sh          # docs/screenshots/*.png
```

## Docs
- [`AGENTS.md`](AGENTS.md): the rules, short, for humans and coding agents
- [`docs/PRD.md`](docs/PRD.md): what the app is, copy, data, visual design
- [`docs/DIRECTION.md`](docs/DIRECTION.md): how the repo and its tags are built (agents start here)
- [`docs/WALKTHROUGH.md`](docs/WALKTHROUGH.md): how each tag is used next to the slides
- [`docs/assets/mockups/`](docs/assets/mockups/): the target UI
- [`docs/reference/`](docs/reference/): the original long spec (older; DIRECTION wins)

## Architecture in one breath
SwiftUI + `@Observable` MVVM, one `State` enum per screen, one protocol (`HorseService`) because the network is the only thing worth faking, the real service created in exactly one place (`StableDateApp`). No Coordinator, Repository, UseCase or DI container. We stop here.

Horse art and app icon are original drawings made for this talk. Free to reuse for learning.
