# AGENTS.md · Stable Date

A tiny SwiftUI dating app for horses, used to teach maintainable iOS code. Building or changing the demo repo itself (tags, schemes, scripts)? Read `docs/DIRECTION.md` first; it wins over everything in `docs/reference/`.

## Stack
- SwiftUI, iOS 17+, iPhone, portrait. Xcode 27.
- Swift 6 language mode, default actor isolation `nonisolated`. `SwipeViewModel` is `@MainActor @Observable`.
- Swift Testing. Zero third-party packages.

## Rules
- A file is one of: View, ViewModel, Model, Service, App entry. Never two.
- Views never touch `URL`, `URLSession`, `JSONDecoder` or any `*Service` type.
- One `State` enum per screen with async data (`loading`, `loaded`, `empty`, `failed`). Views `switch` on it exhaustively. No parallel `isLoading` / `errorMessage` flags.
- Services come in through `init`. Only `StableDateApp` creates `LiveHorseService`; previews and tests use `MockHorseService`.
- Every user-facing string lives in `App/Copy.swift`.
- Colors come from the asset catalog's generated symbols (`Color.rose`, `Color.ink`, …).
- Don't add Coordinator, Repository, UseCase, DI container, or another protocol without a named pain.

## Done means
- Build is clean (zero warnings) with the **Live** scheme.
- ⌘U is green, and no test touches the network.
- The four `SwipeView` previews render without internet.

## Layout
`stable-date/App`, `Models`, `Services`, `Features/Swipe`, `Features/Profile`; tests in `StableDateTests/`; data in `Data/`. Copy and visual design: `docs/PRD.md`.
