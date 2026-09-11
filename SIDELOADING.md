# Installing Bagel on your iPhone (Sideloadly)

No Mac here can run current Xcode, and there's no paid Apple Developer account, so
the app can't be built and installed the normal way. Instead, CI produces an
**unsigned** `.ipa` on every push to `main`, and you sign/install it yourself with
Sideloadly and a free Apple ID.

## 1. Download the build

- Open the latest green run of the `iOS CI` workflow:
  https://github.com/dennisecc/bagel_app/actions/workflows/ios-ci.yml
- Pick the most recent run where both `build-and-test` and `build-unsigned-ipa`
  passed.
- Scroll to the bottom of the run's Summary page to **Artifacts**, and download
  `BagelApp-unsigned-ipa`. You need to be logged into GitHub — it's a private-repo
  artifact, not a public link.
- Unzip it to get `BagelApp-unsigned.ipa`.

Artifacts expire after 14 days, so grab a fresh one if it's been a while.

## 2. Install Sideloadly

Download it from **sideloadly.io** (free) onto whatever computer you'll plug your
iPhone into (Mac or Windows both work).

## 3. Get an app-specific Apple password

- Go to **appleid.apple.com** → Sign-In and Security → App-Specific Passwords →
  generate one.
- Use this in Sideloadly — **never your real Apple ID password**.

## 4. Sideload

1. Plug your iPhone into the computer via USB. Unlock it and tap "Trust This
   Computer" if prompted.
2. Open Sideloadly and drag `BagelApp-unsigned.ipa` into it.
3. Enter your Apple ID email and the app-specific password from step 3 when
   prompted.
4. Confirm your iPhone is selected as the target device, then click **Start**.

## 5. Trust the developer profile on your phone

On the iPhone: **Settings → General → VPN & Device Management** → tap your Apple ID
entry → **Trust**. The app won't open until you do this.

## Things to know

- **7-day expiry**: free Apple ID signing expires after 7 days. After that the app
  just won't launch — re-run Sideloadly (same steps above) to re-sign it. This does
  not reinstall the app or lose its data.
- **Receipt scanning doesn't work yet**: this build has a placeholder Anthropic API
  key baked in, so the OCR → LLM capture step will fail with an auth error. Manual
  entry, assignment, splitting, settlement, and insights all work normally.
- **Getting updates**: every push to `main` produces a fresh artifact the same way —
  download the latest run's `.ipa` and repeat steps 4–5 to update.
