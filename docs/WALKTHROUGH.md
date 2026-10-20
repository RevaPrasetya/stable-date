# Stable Date · Walkthrough bareng slide
Versi 1.0 · 20 Okt 2026 · Live 10.40–11.15 WIB (40 menit, target 34 + buffer 6)

File ini nyambungin deck "Maintainable iOS Apps from a Builder's Perspective" ke repo ini: tiap slide live, tag mana yang di-checkout, apa yang diketik, dan apa yang harus kelihatan di layar biar penonton tahu fix-nya berhasil. Catatan pembicara lengkap tetap ada di deck. Agen: tiap baris "Harus kelihatan" di sini adalah syarat tag-nya (lihat juga [`DIRECTION.md`](DIRECTION.md) §5).

---

## 0. Sebelum share layar

- Build semua tag sekali (`bash scripts/verify-tags.sh`) biar DerivedData hangat. Simulator udah nyala. ⌘U udah pernah jalan.
- `git checkout -f step-0-spaghetti`, scheme **Live**, ⌘R. App nunjukin Sir Gallops-a-Lot.
- Xcode: tema "Presentation (Light)" 22–24 pt, inspector ditutup, Simulator di sebelah editor.
- Webex: share satu display penuh (atau multi-app: Xcode + Simulator + browser deck), "Optimize for text and images". Focus mode nyala.
- Jangan pakai Network Link Conditioner, jangan matiin Wi-Fi (Webex putus). Ganti skenario = ganti scheme + ⌃⌘R.
- Rekaman cadangan per step siap dibuka.

| Scheme | Isinya | Dipakai buat |
|---|---|---|
| Live | URL GitHub raw `Data/horses.json` | normal |
| Offline | `STABLE_DATE_URL=https://horses.invalid/horses.json` | Bug 1, layar error |
| Empty | `STABLE_DATE_URL=…/Data/horses-empty.json` | Bug 2, layar kosong |

---

## 1. Peta slide → tag

| Slide (id) | Jam | Tag | Board setelahnya |
|---|---|---|---|
| `sec-live` | 10.40 | (masih slide) | 🔴 1 · 🔴 2 · 🔴 3 |
| `step0` | 10.41–10.46 | `step-0-spaghetti` | 🔴 🔴 🔴, tapi udah kebukti semua |
| `step1` | 10.46–10.50 | `step-1-wip` → ketik → `step-1-split` | 🔴 🔴 🔴 |
| `step1-swipe` | 10.50–10.53 | `step-1-split` | 🔴 1 · 🔴 2 · 🟢 3 |
| `step2` | 10.53–10.59 | `step-2-wip` → ketik → (`step-2-state`) | 🟢 🟢 🟢 |
| `step3` | 10.59–11.03 | `step-3-wip` → ketik | 🟢 🟢 🟢 |
| `step3-mock` | 11.03–11.06 | `step-3-fake-horses` | 🟢 🟢 🟢 |
| `step4` | 11.06–11.10 | `step-4-tested` | 🔒 🔒 🔒 (Fixed + test) |
| `ai-moment` | 11.10–11.12 | rekaman / screenshot | |
| `board-done` | 11.12–11.13 | | 🔒 🔒 🔒 |
| `pr-review` | 11.13–11.15 | `step-4-tested` (navigator) | |

---

## 2. Step per step

### Step 0 · Reproduksi dulu, baru benerin · `step-0-spaghetti`
Lakukan:
1. Scheme **Live**. Swipe beberapa kuda. ♥ ke Sir Gallops-a-Lot → match.
2. Tap kartu → sheet profil.
3. Scheme **Offline**, ⌃⌘R → spinner muter terus. Balik ke Live.
4. Scheme **Empty**, ⌃⌘R → header + tab bar, tengahnya kosong melompong. Balik ke Live.
5. ✕ ke Sir Gallops-a-Lot → tetap "It's a match!!".
6. Buka `stable-date/SwipeView.swift`, scroll cepat atas ke bawah, lompat ke `.task` dan `nope()`.

Harus kelihatan: tiga bug muncul persis kayak di atas. File-nya 300–500 baris.

### Step 1 · Split · `step-1-wip`
Lakukan:
1. `git checkout -f step-1-wip`. Tunjukin `Models/Horse.swift`, `Services/LiveHorseService.swift`, `Features/Swipe/SwipeViewModel.swift` (±20 detik masing-masing).
2. Live typing di `SwipeView.swift`: blok seluruh networking di `.task { … }`, hapus, ketik `.task { await viewModel.load() }`.
3. ⌘R.
4. Buka `HorseCardView.swift` dan `HorseProfileView.swift`: View kecil, terima satu `Horse`.

Harus kelihatan: Build Succeeded, app jalan persis kayak tadi.

### Step 1 · Satu pintu buat swipe · `step-1-split`
Lakukan:
1. `git checkout -f step-1-split` ("sisanya udah saya siapin": `like`/`nope` dihapus, tombol manggil `viewModel.swipe`). ⌘R.
2. Buka `SwipeViewModel.swift`, tunjuk `swipe(_:liked:)`.
3. ✕ ke Sir Gallops-a-Lot.

Harus kelihatan: kartu berikutnya muncul, **nggak ada** match. Bug 3 hijau. Bug 1 dan 2 masih merah (Offline sekarang layar kosong, bukan spinner: "bug-nya pindah, belum beres").

### Step 2 · State enum · `step-2-wip`
Lakukan:
1. `git checkout -f step-2-wip`. Tunjukin `enum State` dan `load()`.
2. `SwipeView.swift`: `switch` cuma punya `.loading`, `.loaded`, `.empty`.
3. ⌘B → error merah "Switch must be exhaustive". Klik fix-it "Add missing case".
4. Ketik: `case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }`. ⌘B.
5. Scheme **Offline**, ⌃⌘R → layar error. Tap **Try again** → loading → error lagi. Balik Live.
6. Scheme **Empty**, ⌃⌘R → "No horses nearby." Balik Live.
7. Swipe semua kuda → "You've seen every horse."

Harus kelihatan: Build Succeeded setelah satu case. Tiga layar (error, kosong, habis) muncul. Board: tiga-tiganya hijau.
Cadangan: kalau ketikan salah, `git checkout -f step-2-state`.

### Step 3 · Dependency injection · `step-3-wip`
Lakukan:
1. `git checkout -f step-3-wip`.
2. Di `SwipeViewModel`: ganti `private let service = LiveHorseService()` jadi `private let service: any HorseService` + `init(service: any HorseService) { self.service = service }`.
3. ⌘B → satu error di `StableDateApp.swift`: "Missing argument for parameter 'service'".
4. Ketik `SwipeViewModel(service: LiveHorseService())`. ⌘B.

Harus kelihatan: error-nya cuma satu, di composition root. Habis diisi, Build Succeeded.
Kalau mepet waktu: skip ketikan, tunjukin diff aja.

### Step 3 · Kuda palsu · `step-3-fake-horses`
Lakukan:
1. `git checkout -f step-3-fake-horses`. Buka `Services/MockHorseService.swift`.
2. `SwipeView.swift`, canvas (⌥⌘↩). Klik preview Loaded, Empty, Error, Loading.

Harus kelihatan: empat preview tampil tanpa internet.

### Step 4 · One test · `step-4-tested`
Lakukan:
1. `git checkout -f step-4-tested`. Buka `StableDateTests/SwipeViewModelTests.swift`: `offlineShowsErrorNotInfiniteSpinner`, scroll ke `likingAHorseThatLikesYouBackIsAMatch`.
2. ⌘U → 8 test hijau.
3. Rusak: di `SwipeViewModel`, `guard liked, horse.likesYouBack` → `guard horse.likesYouBack`. ⌘U.
4. ⌘Z, ⌘U.

Harus kelihatan: langkah 3 bikin **cuma** `nopingNeverMatches` merah. Langkah 4 hijau lagi. Board: tiga bug "Fixed + test".

### Code review · `pr-review`
Di navigator, tutup semua folder sampai kelihatan `App`, `Models`, `Services`, `Features/Swipe`, `Features/Profile`, `StableDateTests`. Balik ke slide.

---

## 3. Kalau ada yang macet

| Masalah | Lakukan |
|---|---|
| Ketikan live nggak mau build | `git checkout -f` tag berikutnya, lanjut |
| Xcode hang / Simulator nggak mau launch | Putar rekaman cadangan step itu |
| Lewat 11.00 pas Step 2 selesai | Step 3 cukup diff, AI moment satu kalimat |
| Preview canvas lama | Tunjukin `docs/screenshots/` |
| Internet beneran putus | Scheme Live juga jadi layar error. Bilang aja: "nah, ini demo Bug 1 gratis." Lanjut pakai preview dan test (nggak butuh internet) |

---

## 4. Ngukur AI moment (sebelum 23 Okt)

Slide `ai-moment` punya enam `[__]`: file yang dibaca agen, token konteks, file yang berubah, buat tag spaghetti dan tag final.

1. Bikin dua salinan repo: satu di `step-0-spaghetti`, satu di `step-4-tested` (`git worktree add ../sd-step0 step-0-spaghetti`, `git worktree add ../sd-step4 step-4-tested`). Docs dan AGENTS.md sama di keduanya, jadi adil.
2. Sesi agen baru di tiap salinan, prompt yang sama: *"Add Super Like: a super-like that always creates a match. Update SwipeViewModel and add a test."*
3. Catat file yang dibaca, angka konteks dari `/context`, dan file yang berubah. Ulang 3 kali per tag, tulis rentangnya (misalnya 9–12 file).
4. Isi slide. Kalau hasilnya nggak sejelas harapan, sampaikan apa adanya.
5. Opsional: rekam layar ≤ 60 detik sebagai cadangan. Hasil "jawaban benar"-nya ada di branch `demo/super-like`.
