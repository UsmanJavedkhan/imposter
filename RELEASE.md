# Releasing Imposter to the Google Play Store

A start-to-finish walkthrough. The repo is already configured for signed
Android release builds — you mostly need to do the **Console + accounts**
work, generate a keystore once, and run two build commands.

---

## 0 · Cost and accounts

| Item | One-time / annual | What it gets you |
| --- | --- | --- |
| Google Play Console account | **$25 one-time** | Ability to publish on Google Play. Requires a Google account + government ID. |
| Google Cloud / Firebase project | free | Already created: `imposter-game-89391`. |
| Privacy policy hosting | free | Already deployed: `https://imposter-game-89391.web.app/privacy.html`. |

---

## 1 · Generate the upload keystore (once, ever)

The keystore signs every release. **Lose it and you can never update the
app on Play** — back it up to a password manager / cloud drive.

```bash
keytool -genkey -v \
  -keystore %USERPROFILE%\imposter-upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

(On macOS/Linux replace `%USERPROFILE%` with `~`.)

When prompted:

- **Keystore password**: pick a strong one and save it.
- **Key password**: same as keystore password is fine.
- **Distinguished name** ("first/last name", org, city…): can be anything
  truthful — players don't see this.

Then create `android/key.properties` (this file is git-ignored — never
commit it):

```properties
storePassword=<the password you typed>
keyPassword=<same password>
keyAlias=upload
storeFile=C:/Users/<you>/imposter-upload-keystore.jks
```

`android/app/build.gradle.kts` already reads this file and applies the
release signing config automatically.

---

## 2 · Bump the version

In `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^^^^^ ^
#        name  versionCode
```

- The part before `+` (e.g. `1.0.0`) is what users see in the store.
- The part after `+` (e.g. `1`) is the **Play `versionCode`** — must be
  **strictly increasing** with every upload, even for the same version
  name. Bump it every time.

---

## 3 · Build the AAB

App Bundle (`.aab`) is what Play accepts — Google then generates per-device
APKs from it.

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The signed bundle lands at:

```
build/app/outputs/bundle/release/app-release.aab
```

Sanity-check it on your own device first:

```bash
flutter build apk --release
flutter install --release
```

---

## 4 · Required store assets

Prepare these before opening Play Console — the form won't save without
them.

| Asset | Spec | Where it shows up |
| --- | --- | --- |
| App icon | **512 × 512** PNG, 32-bit, no alpha, < 1 MB | Store listing thumbnail |
| Feature graphic | **1024 × 500** PNG/JPG | Top banner on your store page |
| Phone screenshots | **at least 2**, max 8, 16:9 or 9:16, min 320 px short edge | Carousel on store page |
| Tablet screenshots (optional) | 7" + 10" | Improves tablet visibility |
| Short description | ≤ 80 chars | Above the install button |
| Full description | ≤ 4000 chars | Full store page |
| Privacy policy URL | public HTTPS | Already hosted (see § 0) |
| App category | "Games → Word" (suggested) | Browse listings |
| Content rating | filled via Console questionnaire | Required before publishing |
| Data safety form | filled via Console form | Required since 2022 |

### Suggested copy

**Short description** (80 chars max):

> A party word game of deception. Find the imposter. 3–10 players, local or online.

**Full description** (paste into Play Console):

> **Imposter** is a fast, social word game for 3–10 players.
>
> One player is the secret imposter — they don't know the secret word.
> Everyone else does. Take turns dropping a one-word clue, then vote who
> you think doesn't really know it.
>
> 🎭 Imposter wins by surviving the vote. Civilians win by sniffing them out.
>
> ✨ Features:
> • Pass-and-play on a single device — no internet needed
> • Or share a 6-letter room code and play online with friends on their own phones
> • Themed word packs: Animals, Food & Drink, Movies, Sports, Countries, Jobs…
> • Hold the card to peek your role, release to hide it again — no peeking
> • Hosts can play again with the same lineup in one tap
>
> No ads. No tracking. No sign-up.

### Data Safety form answers (when filling out the Console form)

- Does your app collect or share any of the required user data types? **Yes** (because of anonymous Firebase Auth UID + display name).
- Personal info → Name → "Optional, collected, processed ephemerally, not shared." Purpose: App functionality.
- User-generated content → Other → Clue text players type (room-scoped, ephemeral).
- App activity → No.
- Personal identifiers → No (anonymous UID is not a "user ID" in the Play sense — it's not tied to PII).
- Encrypted in transit? **Yes** (Firestore is HTTPS).
- Can users request data deletion? **Yes** — describe the leave-room flow.

---

## 5 · Console flow

1. Sign up at <https://play.google.com/console>, pay the $25, finish ID verification (1–48h).
2. Create a new app:
   - App name: **Imposter**
   - Default language: **English (United States)**
   - App or game: **Game**
   - Free or paid: **Free**
3. Set up **Internal testing** track first (instant — no review). Add yourself as a tester, upload `app-release.aab`, install via the opt-in link, smoke-test.
4. Fill the left-nav checklist: Store listing, App content (privacy policy, ads declaration, target audience, content rating, data safety, government API access, news app status), App access (mark "No login required" — anonymous sign-in qualifies).
5. Promote the build from Internal → Closed testing (12+ testers, helps the algorithm) → Open testing → Production.
6. First **production** review usually takes 1–7 days. Subsequent updates are typically same-day.

---

## 6 · Things still TODO in the repo before first release

These don't block a test upload but should be done before going public:

- [ ] **Real app icon.** Currently the default Flutter logo. Drop a 1024×1024 PNG at `assets/icon/icon.png` and add the `flutter_launcher_icons` package + a config block to generate every Android density.
- [ ] **Real splash screen.** Currently the default. Add `flutter_native_splash` with the brand orange/black palette.
- [ ] **Email address.** Replace `imposter.game.support@gmail.com` in `web/privacy.html` with one you actually monitor.
- [ ] **Bundle ID.** Currently `net.impostergame.imposter_game`. Anyone publishing on Play needs this to be unique — it already is, but the namespace looks like a real domain (`impostergame.net`); only matters if someone tries to claim that domain later.
- [ ] **ProGuard / R8.** Flutter's defaults are fine for Firebase, but if you start seeing release-only crashes, add `-keep` rules in `android/app/proguard-rules.pro`.

---

## 7 · After launch

- Watch the Console **Pre-launch report** — Google runs your AAB on a farm of real devices and flags crashes / accessibility issues.
- Track installs / vitals / ratings under **Statistics**.
- Every update: bump `version:` in `pubspec.yaml`, run `flutter build appbundle --release`, drag the new AAB into Play Console's release track, write release notes.
