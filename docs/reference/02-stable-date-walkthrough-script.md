# Stable Date 🐴 · Guided Walkthrough Script · v2
### "Tinder for horses": the app we break, then fix, live
Part 2 of *Maintainable iOS Apps from a Builder's Perspective* · 40 minutes

> **v2 changes:** this file is now only the *performance* script. What Stable Date is (product) lives in `03-stable-date-product-design.md`, how it's built (architecture) in `04-stable-date-architecture.md`, and the build brief for Opus in `05-stable-date-implementation-plan.md`. Git now has a `-wip` tag before every live-typing moment so there's always something to type and it's always 2–6 lines. A third bug ("matched with a horse I swiped left on") is now real in the spaghetti and fixed by Step 2, so every bug report from Slide 5 pays off. Every step still ends with a Trade-off line (TOR scope item).

---

## 0. What you're driving

| Thing | Value |
|---|---|
| Repo | `stable-date-ios` (public GitHub, see `05`) |
| Xcode | 16.x, Swift 6 language mode, iOS 17 deployment target |
| Simulator | iPhone 16 Pro, light appearance, 100% text size |
| Data | `horses.json` served from the repo's raw GitHub URL |
| Offline trick | Mac Wi-Fi off (clean), or Simulator → Settings → Developer → Network Link Conditioner → 100% Loss (no dropping Webex). **Use the Link Conditioner during the live session; Wi-Fi off kills Webex.** |

### Tags (completed states) and `-wip` tags (before the live typing)

| Tag | State of the code | Compiles? |
|---|---|---|
| `step-0-spaghetti` | One `SwipeView.swift` does everything. All 3 bugs present. | ✅ |
| `step-1-wip` | Model, Service, ViewModel exist. View still has its own `.task` networking block. | ✅ |
| `step-1-split` | View calls `viewModel.load()`. Bugs still present. | ✅ |
| `step-2-wip` | ViewModel has the `State` enum. View `switch` is missing the `.failed` case. | ❌ on purpose ("switch must be exhaustive") |
| `step-2-state` | Full `switch`. Spinner, blank, and wrong-match bugs fixed. | ✅ |
| `step-3-wip` | `HorseService` protocol + `MockHorseService` exist. ViewModel still does `= LiveHorseService()`. | ✅ |
| `step-3-fake-horses` | ViewModel takes the service in `init`. 4 previews. | ✅ |
| `step-4-tested` | Swift Testing tests. ✅ Final. `main` points here. | ✅ |

### Terminal cheat sheet (keep this in a Notes window)

```bash
cd ~/dev/stable-date-ios
git checkout step-0-spaghetti      # start
git checkout -f step-1-wip         # -f throws away whatever you typed in the previous step
git checkout -f step-1-split
git checkout -f step-2-wip
git checkout -f step-2-state
git checkout -f step-3-wip
git checkout -f step-3-fake-horses
git checkout -f step-4-tested
```
Xcode reloads the files automatically. If it gets confused: ⌘⇧K (clean) then ⌘R.

---

## 1. Timing

| Min | Step | Rule it proves | Live typing? |
|---|---|---|---|
| 0–4 | Tour: meet the app, then break it | (callback to Act I) | no |
| 4–10 | Step 0: Read the spaghetti | Why we need rules | no |
| 10–18 | Step 1: Split (+ the detail screen) | Rule 1: one job per thing | 1 line |
| 18–26 | Step 2: State enum | Rule 2: make state explicit | 1 `case` line |
| 26–33 | Step 3: Fake horses (test double) | Rule 3: depend on promises | 2 lines + 1 line |
| 33–38 | Step 4: One test (+ AI moment) | Rule 4: test what users feel | 1 edit (break it on purpose) |
| 38–40 | Wrap: code review questions + "we stop here" | Rule 5: don't over-engineer | no |

Rehearsal rule: if you're past minute 20 when Step 2 ends, skip the live typing in Step 3 (show the diff) and cut the AI moment to one sentence.

---

## 2. Script

### 0–4 min · Tour: meet Stable Date, then break it
**Checkout:** `step-0-spaghetti` · app already running in the Simulator before you share.

**Do:**
1. Swipe a few horses with the buttons. Like "Sir Gallops-a-Lot" → match banner. *"Look, it works. Ship it."*
2. Tap a card → profile sheet. Dismiss. *"List and detail. The TOR is happy."*
3. Enable Network Link Conditioner 100% Loss. Relaunch (⌘R).
4. Infinite spinner. Let it spin awkwardly for 5 seconds. Don't talk.

**Say:**
"Remember the bug reports? Here's the first one, live. 'Rounding up horses' forever. The horses are not coming. Let's find out why."

Turn the Link Conditioner off again now, so you don't forget later.

---

### 4–10 min · Step 0: Read the spaghetti
**Show:** `SwipeView.swift`. Scroll the whole file fast, top to bottom (the length is the joke), then jump to the `.task`.

```swift
.task {
    let url = URL(string: "https://raw.githubusercontent.com/.../horses.json")!
    guard let (data, _) = try? await URLSession.shared.data(from: url),
          let decoded = try? JSONDecoder().decode([Horse].self, from: data)
    else { return }                 // 🙈 failure? just... leave.
    horses = decoded
    isLoading = false
}
```

Then jump to `nope(_:)`:
```swift
func nope(_ horse: Horse) {
    horses.removeAll { $0.id == horse.id }
    if horse.likesYouBack { matches.append(horse) }   // copy-pasted from like(). oops.
}
```

**Say (point at each thing):**
- "`return` on failure. We just leave. `isLoading` stays `true` forever. That's the infinite spinner."
- "If the JSON is empty: `horses` is empty, `isLoading` is false, blank screen. Second bug."
- "And this. `nope` was copy-pasted from `like`. Swipe left on a horse that likes you, and it's a match. Third bug report, the one with the question marks."
- "The matching rule lives inside a View. Want to test it? You'd have to tap buttons on a simulator. Forever."
- "Count the jobs: networking, parsing, matching, animating, drawing. Five jobs, one file. Rule 1 says no."

**Ask chat:** "How many responsibilities do you count?" (Any answer above 3 is right.)

**Trade-off:** "To be fair: for a weekend hack, one file was the right call. It got us users. The mistake was staying here."

---

### 10–18 min · Step 1: Split it (Rule 1: one job per thing)
**Checkout:** `git checkout -f step-1-wip`

**Show the new files, one by one, 20 seconds each:**

`Models/Horse.swift`
```swift
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
*"Be a horse. That's its whole job."*

`Services/LiveHorseService.swift`
```swift
struct LiveHorseService {
    func fetchHorses() async throws -> [Horse] {
        let (data, _) = try await URLSession.shared.data(from: Self.url)
        return try JSONDecoder().decode([Horse].self, from: data)
    }
}
```
*"Get horses from somewhere. Notice `throws`. Errors aren't swallowed anymore. They travel up so someone else can decide."*

`Features/Swipe/SwipeViewModel.swift`
```swift
@MainActor @Observable
final class SwipeViewModel {
    var horses: [Horse] = []
    var isLoading = true
    var errorMessage: String?               // 👀 remember these three
    private(set) var matches: [Horse] = []

    private let service = LiveHorseService() // 👀 remember this too

    func load() async { ... }
    func swipe(_ horse: Horse, liked: Bool) -> Bool { ... }
}
```
*"Decide. The matching rule moved here, and it's one function now, so `nope` can't have its own copy of the bug."*

**Live typing (1 line):** in `SwipeView.swift`, select the whole `.task { ... }` networking block, delete it, and type:
```swift
.task { await viewModel.load() }
```
⌘R. App runs exactly as before.

**Say:**
- "The View went from 'doing everything' to 'drawing things.' Same app, same bugs, but now each file has one reason to change."
- "Still broken though. These three variables, `horses`, `isLoading`, `errorMessage`, can disagree with each other. And the ViewModel builds `LiveHorseService` itself, so it's married to the internet. Two problems, two more steps."

**The detail screen (1 min):** tap a card → `HorseProfileView.swift`.
```swift
struct HorseProfileView: View {
    let horse: Horse      // that's all it needs
    var body: some View { ... }
}
```
*"The detail screen takes one `Horse` and draws it. No service, no ViewModel, no network. Not every screen needs layers. A screen that only displays data stays simple. That's a boundary decision too."*

**Trade-off:** "We went from 1 file to 6. More files to jump between, more ⌘⇧O. Worth it, because each file now has exactly one reason to change, and the AI only needs to open the one that matters."

---

### 18–26 min · Step 2: The State enum (Rule 2: make state explicit)
**Checkout:** `git checkout -f step-2-wip`

**Show** `SwipeViewModel.swift`:
```swift
enum State: Equatable {
    case loading
    case loaded([Horse])
    case empty
    case failed(String)
}
private(set) var state: State = .loading

func load() async {
    state = .loading
    do {
        let horses = try await service.fetchHorses()
        state = horses.isEmpty ? .empty : .loaded(horses)
    } catch {
        state = .failed("The horses ran away. 🐎💨")
    }
}
```

**Show** `SwipeView.swift`, the `switch`, which is missing a case:
```swift
switch viewModel.state {
case .loading:            LoadingView()
case .loaded(let horses): CardStackView(horses: horses, onSwipe: handleSwipe)
case .empty:              EmptyDeckView()
}
```

**The trick:** press ⌘B *before* adding anything. Red error: **"Switch must be exhaustive."** Point at it.

**Say:** "Look. Swift just did a code review for free. It refuses to let me forget the error screen."

**Live typing (1 line):**
```swift
case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }
```
⌘B → green.

**Do:** Link Conditioner on → ⌘R → error screen with **Try again**. Link Conditioner off → tap Try again → horses. 🎉 Then swipe through every horse → empty screen with the "touch grass" copy.

**Say:**
- "Three variables became one. The screen is always in exactly one state. Loading *and* error at the same time is now impossible. Not 'unlikely.' Impossible."
- "The last-horse case came for free: `swipe` updates the state too, so an empty deck shows the empty screen without a single extra `if`."

**Trade-off:** "Reading data out of an enum is a bit more verbose: `if case .loaded(let horses) = state`. We trade a little typing for a whole category of bugs that can't exist. Good deal. And yes, we put a `String` in `.failed`. In a bigger app you'd keep the `Error` too so the View can choose between 'retry' and 'open Settings.' Stable Date doesn't need that yet."

---

### 26–33 min · Step 3: Fake horses (Rule 3: depend on promises)
**Checkout:** `git checkout -f step-3-wip`

**Show** `Services/HorseService.swift`:
```swift
protocol HorseService: Sendable {
    func fetchHorses() async throws -> [Horse]
}
```
*"That's the promise. Give me horses, or throw."*

**Show** `Services/MockHorseService.swift`:
```swift
struct MockHorseService: HorseService {
    var result: Result<[Horse], any Error>
    var delay: Duration = .zero

    func fetchHorses() async throws -> [Horse] {
        try await Task.sleep(for: delay)
        return try result.get()
    }
}
```
*"Fake horses. We decide exactly what it returns."*

**Live typing (2 lines):** in `SwipeViewModel.swift`, replace
```swift
private let service = LiveHorseService()
```
with
```swift
private let service: any HorseService
init(service: any HorseService) { self.service = service }
```
⌘B → one red error in `StableDateApp.swift`: "Missing argument for parameter 'service'." Good. Go there.

**Live typing (1 line):** in `StableDateApp.swift`:
```swift
SwipeView(viewModel: SwipeViewModel(service: LiveHorseService()))
```
*"This is the only file in the whole app that knows the real internet exists."*

**The payoff:** open the Preview canvas on `SwipeView.swift` (⌥⌘↩). Four previews, side by side:
```swift
#Preview("Loaded")  { SwipeView(viewModel: .init(service: MockHorseService(result: .success(Horse.samples)))) }
#Preview("Empty")   { SwipeView(viewModel: .init(service: MockHorseService(result: .success([])))) }
#Preview("Error")   { SwipeView(viewModel: .init(service: MockHorseService(result: .failure(URLError(.notConnectedToInternet))))) }
#Preview("Loading") { SwipeView(viewModel: .init(service: MockHorseService(result: .success([]), delay: .seconds(999)))) }
```
Click through them. No Wi-Fi tricks.

**Say:**
- "The ViewModel doesn't create its service anymore. Someone hands it in. That's dependency injection: passing the thing in instead of creating it inside. That's literally it."
- "This fake has a name: a **test double**. Like a stunt double in a movie, it replaces the real actor for the dangerous scenes. Here the dangerous scene is 'the internet is dead.' We control exactly what it returns, so the behavior is predictable and testable."
- "Four previews, four states, no internet. Designers love this. QA loves this. Future you loves this. Real horses in the app, fake horses everywhere else."

**Trade-off:** "A protocol adds one level of indirection: 'Jump to definition' now lands on the promise, not the real code. For things you need to fake, like network, disk, and time, it's worth it. For everything else, don't bother. We did *not* put `HorseCardView` behind a protocol."

---

### 33–38 min · Step 4: One test (Rule 4: test what users feel)
**Checkout:** `git checkout -f step-4-tested`

**Show** `StableDateTests/SwipeViewModelTests.swift`, just these two:
```swift
@Test func offlineShowsErrorNotInfiniteSpinner() async {
    let vm = SwipeViewModel(service: MockHorseService(
        result: .failure(URLError(.notConnectedToInternet))))

    await vm.load()

    #expect(vm.state == .failed("The horses ran away. 🐎💨"))
}

@Test func likingAHorseThatLikesYouBackIsAMatch() async {
    let vm = SwipeViewModel(service: MockHorseService(result: .success(Horse.samples)))
    await vm.load()
    let crush = Horse.samples.first { $0.likesYouBack }!

    #expect(vm.swipe(crush, liked: true))
    #expect(vm.matches.contains(crush))
}
```

**Do:** ⌘U → green ✅ (there are a few more tests in the file; let them all run, it takes a second).

**Break it on purpose (live edit):** in `SwipeViewModel.swift`, change
```swift
guard liked, horse.likesYouBack else { return false }
```
to
```swift
guard horse.likesYouBack else { return false }
```
⌘U → `nopingNeverMatches` goes red ❌. *"That's the copy-paste bug from Step 0, trying to come back. The test caught it. The horse's heart is safe."* ⌘Z, ⌘U, green.

**Say:**
- "The first test is the infinite spinner bug from the beginning, turned into a test. It can never come back without us knowing."
- "The second is the business rule. No simulator, no tapping. Runs in milliseconds."
- "Notice what we did *not* test: that SwiftUI draws a `ProgressView`. Apple tested that."

**Trade-off:** "Tests are code you also have to maintain. That's why there are five in this file, on the things users would actually notice, not fifty."

**🤖 The AI moment (1 min, prerecorded clip or 2 screenshots, not live):**
Prompt shown on screen: *"Add Super Like: a super-like that always creates a match, even if the horse doesn't like you back. Update SwipeViewModel and add a test."*
Then the diff: ~10 lines in `SwipeViewModel`, ~8 lines in the test file, nothing else touched. Then ⌘U green.

**Say:** "Now the AI only needs to read one ViewModel and one test file, not the whole app. And when it's done, we run the tests, and *we* know if it worked, not just the AI. Your codebase is the prompt."

---

### 38–40 min · Wrap: code review questions + "we stop here" (Rule 5)
**Show:** the final folder tree in the Xcode navigator, collapsed to folders:

```
StableDate/
  App/        Models/        Services/        Features/Swipe/        Features/Profile/
StableDateTests/
```
*"Folders by feature, not by file type. When I work on swiping, everything I need is in one folder. So is everything the AI needs."*

**Then the slide:**
> **5 questions before you approve a PR** (yours, a teammate's, or the AI's)
> 1. Does each file still have one job?
> 2. Can this screen be in two states at once?
> 3. What does the user see when this request fails? When it's empty?
> 4. Can I test this without the internet?
> 5. Is this new layer solving a real pain, or just looking smart?

**Say:**
"These are the four steps we just did, turned into review questions, plus the over-engineering check. Use them on your teammates' PRs, and especially on AI-generated code.

That's it. Four changes. We didn't add Coordinators, UseCases, a Repository, or a dependency injection framework. Stable Date doesn't need them. If Stable Date gets 10 screens and 5 developers, maybe. Not today. Fix what hurts, then stop. Now, your questions."

→ Hand over to the moderator.

---

## 3. Contingency plan

| If this happens | Do this |
|---|---|
| Xcode freezes or the build is slow | Switch to the **prerecorded recording** of that step (one video per step, see `05`, Phase 7) |
| Webex dies on your side | Co-host plays the backup recording; you rejoin |
| Simulator won't boot | Show the SwiftUI previews instead (Step 3 previews cover every state) |
| Link Conditioner doesn't bite | Fallback: in `LiveHorseService`, change the URL to `.../horses-404.json` (a path that doesn't exist). Same result. |
| Running late at min 20 | Skip live typing in Step 3 (show the diff), AI moment = one sentence |
| Running early | Live-add "Super Like" with its test (it's already on the `demo/super-like` branch if you want to cheat) |
| A question derails you mid-step | "Great question, hold it for Q&A, I'll come back to it." Then actually do. |

**Webex setup:** share the Xcode window only. Editor font 18–20pt (Xcode → Settings → Themes → Presentation). Hide the minimap, hide the inspector (⌥⌘0), show the navigator (⌘0). Close Slack/WhatsApp. Light appearance in the Simulator so screenshots match the slides. Do Not Disturb on.

---

## 4. Rehearsal checklist

- [ ] Can checkout every tag with `-f` and the app runs (or fails to compile *exactly* where intended, `step-2-wip`)
- [ ] All three Step 0 bugs reproduce on `step-0-spaghetti`
- [ ] Link Conditioner path rehearsed twice (on, relaunch, error, off, retry)
- [ ] The four previews render on `step-3-fake-horses`
- [ ] ⌘U green on `step-4-tested`; the "break it on purpose" edit turns exactly one test red
- [ ] AI-moment clip exported, ≤ 60 s, 1080p
- [ ] Explained every line of every file out loud to a human at least once
- [ ] Full run with timer: ≤ 40 min with a 2-minute buffer
