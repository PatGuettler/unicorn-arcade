# Kid-safe AdMob banner (Families / COPPA)

Use this document when adding or changing the bottom **ad bar** in Unicorn Arcade. The app is **for children**. Real network ads are only allowed when **Google Play**, **AdMob**, **privacy policy**, and **in-app SDK settings** all agree on child-directed, non-personalized serving.

**Current code state**

| Stack | Ad bar location | Live AdMob? |
| --- | --- | --- |
| Godot (shipping port) | `godot/autoload/ad_bar_service.gd` + attach from `godot/scripts/main.gd` | No — placeholder until `config/admob.json` + native plugin |
| React / Capacitor (reference) | `src/components/shared/adBar.jsx` | No — commented out in `src/App.jsx` |

Do **not** drop in a generic AdMob snippet. Generic snippets enable personalized ads and adult ad inventory by default, which violates Families policy for this product.

---

## Status (updated August 3, 2026)

**Goal:** bottom **banner ad bar** in the Godot app (`AdBarService` + native AdMob on Android), kid-safe (Families + child-directed).

**You are here → [Part C — Godot plugin](#part-c--godot-implementation-checklist)** (AdMob app + banner unit created; finish B2/B link store while account verifies).

### Your AdMob records (Unicorn Arcade — Android)

| Field | Value | Use in Godot |
| --- | --- | --- |
| **App ID** | `ca-app-pub-2846735043546429~3696195593` | `android_app_id` in `godot/config/admob.json` — note **`~`**, not `/` |
| **Banner ad unit** (`Unicorn_Banner_Bottom`) | `ca-app-pub-2846735043546429/2606475202` | `android_banner_unit_id` when testing production unit |
| **Google test banner** (use first in code) | `ca-app-pub-3940256099942544/6300978111` | Safer until plugin works + account approved |

Copy locally (not committed):

```bash
cp godot/config/admob.example.json godot/config/admob.json
# Set android_app_id to your ~ App ID above; banner to TEST id until device QA passes.
```

### Progress

| Step | Status | Notes |
| --- | --- | --- |
| **A1** Target audience (5 and under, 6–8) | Done | Teacher Approved in Google’s queue |
| **A2** Data safety questionnaire | Submitted | **In review** on Publishing overview (Aug 3, 2026) |
| **A3** Privacy + deletion URLs | Done | Live on GitHub Pages (see A3 below) |
| **A3** Store “Contains ads” | Done | Declared earlier; matches planned AdMob banner |
| **Advertising ID** (App content) | **No** (unchanged) | Flip to **Yes** on the **same release** that ships Mobile Ads SDK |
| **B1** AdMob app + banner unit | **Done** | App ID + `Unicorn_Banner_Bottom` created |
| **B1b** Account / app review | **In progress** | Reactivated after inactivity; **account verifying** (~24h); app **Requires review** / **Limited ad serving** |
| **B1c** Link Play store in AdMob | **Done** | **`com.grapegames.wlarcade`** — mobile **Unicorn Arcade** (not Windows PC row) |
| **B1d** `app-ads.txt` verification | **Pushed — enable Pages** | Content on `PatGuettler/patguettler.github.io` `main`; click **Save** on repo **Settings → Pages** (branch **main**, `/root`), then verify URL |
| **B2** Child-directed + Families self-certified ads | **Confirm in UI** | App settings — must match Play (ages 5–8) |
| **C** Godot AdMob plugin + wire `AdBarService` | **Not started** | **Do this next** in repo; test banner on device |
| **C** Placeholder ad bar in app | Done | `godot/autoload/ad_bar_service.gd`, `godot/scripts/main.gd` |
| **Production** `ads_enabled: true` + production unit ID | Blocked | After plugin works, AdMob/Play approval, Advertising ID **Yes** |

**Android package names** (AdMob must match **what’s on Google Play**, not the folder name):

| Build | Package ID | Where |
| --- | --- | --- |
| **Capacitor / `main` (`android/`)** — likely **live Play app** | **`com.grapegames.wlarcade`** | `capacitor.config.json`, `android/app/build.gradle` (internal label “wl-arcade”) |
| **Godot (`godot-port`)** — future export | **`com.guettler.unicornarcade`** | `godot/export_presets.cfg` |

If AdMob **can’t find** `com.guettler.unicornarcade`, search **`com.grapegames.wlarcade`** instead. Confirm in Play Console → **Dashboard** (or **Test and release** → latest release) → **Application ID**.

When Godot replaces Capacitor on Play, either keep one package ID across both codebases or create a new AdMob app entry for the new package — do not mix app IDs across different store listings.

### Next actions (in order)

1. **GitHub Pages (you, ~2 min)** — repo **`patguettler.github.io`** → **Settings → Pages** → Source: **Deploy from branch** → **main** → **/ (root)** → **Save**. Wait 1–5 min, open `https://patguettler.github.io/app-ads.txt` (must show the `google.com, pub-2846735043546429…` line).
2. **AdMob** → **Verify app** → **Check for updates** (after step 1). Confirm **child-directed** + **Families self-certified ads** in app settings.
3. **Godot (engineering)** — [Part C2](#c2-native-plugin-android): AdMob plugin + wire `AdBarService`; local `godot/config/admob.json` already has your App ID + **test** banner (`ads_enabled: false` until device test).
4. **Play** — first APK with Mobile Ads: **Advertising ID → Yes**; then production banner unit `…/2606475202`.

---

## For AI agents

When the user asks for ads, an ad bar, AdMob, or monetization:

1. Read this file end-to-end before editing code.
2. Assume **child-directed** unless the product owner explicitly changes Play Console target audience.
3. **Allowed in v1:** fixed **bottom banner** only, clear **“Ad”** label, hide on **login** (match `shouldShowAdBar` logic in `App.jsx`).
4. **Do not add** without explicit owner approval: interstitials, rewarded video, app open ads, native ads in gameplay, third-party analytics tied to ads, ATT/IDFA prompts, or Facebook Audience Network.
5. Wire Godot through `AdBarService` and `config/admob.example.json` → copy to gitignored `config/admob.json`.
6. Update `public/privacy-policy.html` (AdMob + data collected for ads) before enabling production ad unit IDs.
7. Use **test ad unit IDs** in debug builds; never commit production IDs in plaintext if the repo is public.

---

## Policy model (what “100% kid approved” means here)

Google does not offer a literal “100% kid approved” switch. You achieve compliance by stacking:

1. **Google Play** — app declared for **children** (or mixed with strict treatment) and **Designed for Families** requirements met.
2. **AdMob** — app marked **child-directed** (or mixed audience with child-directed treatment) and **Families self-certified ads** enabled for the app.
3. **SDK** — request **non-personalized** ads, **child-directed** / **under-age-of-consent** tags, and **G** max content rating (where the plugin exposes them).
4. **Product** — banner at bottom only, no dark patterns, no behaviorally targeted messaging in the UI.
5. **Legal** — privacy policy and Data safety form match what AdMob actually collects.

If any layer is wrong, turn ads off (`ads_enabled: false` in config) and ship placeholders only.

Official references:

- [AdMob — COPPA and child-directed apps](https://support.google.com/admob/answer/9900633)
- [AdMob — Tag an ad request for child-directed treatment](https://support.google.com/admob/answer/8007173)
- [AdMob — Families self-certified ads](https://support.google.com/admob/answer/6223431)
- [Google Play — Designed for Families](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Google Play — Families ads and monetization](https://support.google.com/googleplay/android-developer/answer/9283445)

---

## Part A — Google Play Console

Most of Part A is **complete** for planned ads. Remaining Play work is **wait for Data safety review** and, **later**, update **Advertising ID** when AdMob ships (see [Status](#status-updated-august-3-2026)).

### A1. Target audience and content

**Status: done** (ages 5 and under, 6–8; Teacher Approved submitted).

1. Open [Google Play Console](https://play.google.com/console) → your app.
2. **Policy** → **App content** → **Target audience and content**.
3. Declare that the app **appeals to children** (typical for Unicorn Arcade).
4. Complete **Teacher Approved** / **Families** questionnaires honestly.
5. Resolve any **Families policy** issues shown under **Policy status**.

### A2. Data safety

**Status: submitted Aug 3, 2026 — in review.**

Summary of what was declared (must stay consistent with the app and privacy policy):

- **Collected / shared:** App interactions, Device or other IDs (advertising, optional); Crash logs, Diagnostics (app functionality, optional).
- **Deletion URL + Families commitment + encrypted in transit:** set on preview.

1. **App content** → **Data safety**.
2. Declare data collected/shared by **Google AdMob** (device identifiers, app interactions, diagnostics — use AdMob’s current form guidance).
3. Mark purposes such as **Advertising** where applicable.
4. State whether data is shared with third parties (AdMob / Google).
5. Align answers with your published privacy policy (see Part D).

### A3. Store listing

**Status: privacy policy live; deletion URL on Data safety form.**

1. Use a **privacy policy URL** that mentions third-party ads when ads are live.

   Published URLs (GitHub Pages):

   - Privacy policy: `https://patguettler.github.io/unicorn-arcade/privacy-policy.html`
   - Data deletion (Play Console “Delete data URL”): `https://patguettler.github.io/unicorn-arcade/privacy-policy.html#data-deletion`

2. Do not claim “no data collection” if AdMob is enabled.

### A4. Link Play app to AdMob

**Status: do when creating the AdMob app (Part B1).**

1. In AdMob (Part B), link this Android app package name to the AdMob app record.
2. Package name must match Godot export: **`com.guettler.unicornarcade`**.

### A5. Advertising ID (when AdMob is in the APK)

**Status: still “No” — correct for current builds without Mobile Ads SDK.**

1. **App content** → **Advertising ID**.
2. Before **No** → **Yes** only when the uploaded release includes **Google Mobile Ads (AdMob)**.
3. Answer for **children**: used for advertising, **not** personalized/behavioral ads for kids (Families).
4. Align Android manifest (`AD_ID` / plugin docs) with the declaration on that release.

---

## Part B — Google AdMob

**Most of B1 is done.** Finish store link + Families settings; wait for Google review/verification.

### B1. Account and app

**Done:** Android app **Unicorn Arcade**, App ID `ca-app-pub-2846735043546429~3696195593`, banner **Unicorn_Banner_Bottom** (`ca-app-pub-2846735043546429/2606475202`).

**Still to do:**

1. **`app-ads.txt`** — [B1d](#b1d-app-adstxt-verification) (required after linking Play; fixes “couldn’t verify app”).
2. **App settings** → child-directed + **Families self-certified ads** ([B2](#b2-child-directed--families-critical)).
3. Wait for **account verification** + app review after `app-ads.txt` is live.

### B1d. `app-ads.txt` verification

AdMob shows this line (publisher ID from your account):

```text
google.com, pub-2846735043546429, DIRECT, f08c47fec0942fa0
```

**Where to host it:** at the **root** of the **website domain** listed on your Play store listing (not inside `/unicorn-arcade/` unless Play’s website field is exactly that subdomain path — usually it is not).

| Play listing “Website” domain | File must be reachable at |
| --- | --- |
| `https://patguettler.github.io/...` (typical) | **`https://patguettler.github.io/app-ads.txt`** |

This repo’s GitHub Pages deploys to **`/unicorn-arcade/`**, so `public/app-ads.txt` here becomes `…/unicorn-arcade/app-ads.txt`, which **usually does not satisfy** AdMob. Use one of:

1. **`patguettler.github.io` user site repo** — add `app-ads.txt` at the repo root, enable Pages, confirm `https://patguettler.github.io/app-ads.txt` in a browser, **or**
2. Change Play **Website** to a domain you control at root (advanced).

**Steps:** enable Pages on **`patguettler.github.io`** (see [Next actions](#next-actions-in-order)) → confirm URL → AdMob **Check for updates** (can take up to 24 hours).

**Repo:** `https://github.com/PatGuettler/patguettler.github.io` — file at repo root: `app-ads.txt`.

Source copy in game repo (subpath only): `public/app-ads.txt` on **`unicorn-arcade` `main`**.

### B2. Child-directed / Families (critical)

1. **Apps** → select **Unicorn Arcade** → **App settings**.
2. Set **Target audience** / **Child-directed treatment** to match Play (usually **Yes, child-directed** for this game).
3. Enable **Families self-certified ads** for this app when offered.
4. Confirm you only use **Families-certified** ad formats Google allows for your audience age band.

### B3. Ad units (banner only for v1)

1. **Apps** → your app → **Ad units** → **Add ad unit** → **Banner**.
2. Name example: `Unicorn Arcade — Bottom Banner`.
3. Copy the **ad unit ID** (`ca-app-pub-XXXX/YYYY`) into local `godot/config/admob.json` (not committed).
4. Keep Google’s **test banner** ID for development:
   - Android banner test: `ca-app-pub-3940256099942544/6300978111`

### B4. Mediation (optional later)

If you add mediation networks, each network must be **Families-compliant** for child-directed traffic. Default to **AdMob only** until an expert reviews mediation partners.

---

## Part C — Godot implementation checklist

### C1. Config

```bash
cp godot/config/admob.example.json godot/config/admob.json
```

Edit `admob.json`:

- `ads_enabled`: `false` until the Godot plugin loads banners on device; then `true` with **test** unit ID for QA, production unit only for store builds.
- `android_app_id`: from AdMob app settings (`ca-app-pub-…~…`).
- `android_banner_unit_id`: your banner unit or test ID.
- `child_directed`: must stay `true` for this product.
- `tag_for_under_age_of_consent`: `true` (US COPPA-oriented requests).
- `max_ad_content_rating`: `"G"`.

Example after Part B (test IDs OK for development):

```json
{
  "ads_enabled": true,
  "android_app_id": "ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY",
  "android_banner_unit_id": "ca-app-pub-3940256099942544/6300978111",
  "child_directed": true,
  "tag_for_under_age_of_consent": true,
  "max_ad_content_rating": "G",
  "show_on_login": false,
  "banner_height_dp": 60
}
```

Add `godot/config/admob.json` to `.gitignore` if it contains production IDs.

### C2. Native plugin (Android)

Godot needs a **maintained AdMob GDExtension / plugin** for your Godot version (4.7.x). Before adopting one:

- Supports **Android banner** anchored to bottom.
- Exposes **child-directed**, **under-age-of-consent**, and **max content rating** on each ad request.
- Documents compatibility with **Families self-certified ads**.

Integrate in export preset / `AndroidManifest` per plugin docs (usually `com.google.android.gms.ads.APPLICATION_ID` meta-data).

### C3. UI placement

- Reserve **56–72 px** + bottom safe area (see `SafeArea` autoload).
- Show on hub screens and games; **hide on login** (`AppState.player_name()` empty / login view).
- Always show a visible **“Ad”** label on the placeholder or next to the banner container.

Hook point: `AdBarService.attach_to(control)` from `main.gd` after the root layout is built.

### C4. Debug vs release

| Build | Ad unit | `ads_enabled` |
| --- | --- | --- |
| Local / CI debug | Google test banner ID | `true` only when testing plugin |
| Production | Production banner ID | `true` only after checklist below |

---

## Part D — Privacy policy (required before production ads)

**Status: done on GitHub Pages (Aug 3, 2026).** Source: `public/privacy-policy.html` (deploy via `main` → GitHub Actions).

When changing ad behavior, update the policy and redeploy Pages before flipping production ad units.

Update `public/privacy-policy.html`:

1. **Children’s Privacy** — state the app **is** directed at children (or mixed audience with child treatment), not “does not address anyone under 13,” if that remains the live policy.
2. **Third parties** — add [Google AdMob](https://policies.google.com/privacy) and describe ad-related data.
3. **Parental choices** — contact email for questions / opt-out where applicable.

Republish the policy URL in Play Console.

---

## Part E — React / Capacitor (reference app)

If ads return to the Capacitor build:

1. Use a plugin that maps to **Google Mobile Ads SDK** with child-directed flags (e.g. community Capacitor AdMob plugins — verify Families support).
2. Re-enable `<AdBar />` in `src/App.jsx` only after the same Play + AdMob + privacy steps.
3. Replace rotating fake copy in `adBar.jsx` with a real **banner view**; keep the **“Ad”** label.

---

## Pre-launch checklist (copy into PR / release notes)

- [x] Play target audience / Families declarations complete
- [x] Play Data safety form submitted (wait for **Complete** / approved)
- [ ] Play **Advertising ID → Yes** (same release as first AdMob APK)
- [ ] AdMob app linked to **Play store** (lift limited serving)
- [ ] AdMob account verified + app **Requires review** cleared
- [ ] AdMob app: child-directed + Families self-certified ads
- [x] Banner ad unit created (`Unicorn_Banner_Bottom`)
- [ ] Godot plugin sets child-directed / non-personalized request flags
- [x] Login screen has **no** ad bar (placeholder; keep after AdMob)
- [x] Privacy policy updated and URL live
- [ ] `admob.json` production IDs not committed to public repo
- [ ] Manual QA: ad content looks appropriate; no install prompts for inappropriate apps

---

## Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| “Ad failed to load” | Wrong app ID, unit ID, or SHA-1 not registered in Firebase/Play (plugin-dependent) |
| Policy rejection on Play | Data safety contradicts AdMob; or non-certified ad formats |
| Adult ad content | Child-directed flags off, or mediation partner not certified |
| Blank banner area | `ads_enabled` false — placeholder should still show; check `AdBarService` |

When in doubt, set `ads_enabled` to `false` and ship the COPPA-style placeholder bar until settings are verified.
