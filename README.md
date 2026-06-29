# Mira — the calm parenting companion

A beautiful, private baby & toddler tracker with an AI coach for the tough moments.
Built with Flutter + Material 3. Designed to feel calm, warm and premium — never the
default baby-app look.

## How building works (no local SDK needed)

You never run Flutter on your machine. Every push to GitHub triggers a cloud build:

1. Write code → push to GitHub
2. **GitHub Actions** builds the release APK in the cloud
3. Download the APK artifact and install it on your phone

The repo stays lean — only `lib/` and `pubspec.yaml` are committed. The Android
project files are generated during CI by `flutter create`, so there's nothing
platform-specific to maintain by hand.

### Getting your APK

- Go to the **Actions** tab on GitHub after a push
- Open the latest **Build Mira APK** run
- Download the **mira-apk** artifact (it's a `.zip` containing `app-release.apk`)
- Transfer to your phone and install (enable "install from unknown sources")

## Roadmap

- [x] **Phase 1** — Design system + premium home screen + CI/APK pipeline
- [ ] **Phase 2** — On-device persistence, full timeline, pediatrician PDF report
- [ ] **Phase 3** — AI chat advisor (Gemini via a free Cloudflare Worker proxy)
- [ ] **Phase 4** — Calm Mode (in-the-moment coach) + voice input
- [ ] **Phase 5** — Paywall, premium gating, themes

## Tech

- Flutter + Dart, Material 3
- Plus Jakarta Sans (Google Fonts)
- All tracking data stored on-device (private by default)
- AI (later) via Gemini free tier behind a Cloudflare Worker proxy — keys never ship in the app
