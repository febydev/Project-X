# Partner Sync setup (one-time, when you're ready)

Partner sync lets two phones share the same baby and logs. It's **built and
wired in the UI** (Settings → Family → Add a partner generates a code), but the
real-time backend is **dormant** until you connect Firebase — because adding the
Firebase packages without a config file would break the cloud APK build.

When you want to turn it on:

1. Create a free **Firebase** project at https://console.firebase.google.com (no card).
2. Add an **Android app** with package name `com.miraapp.mira`.
3. Download **google-services.json** and commit it to `android/app/` (the CI build
   uses it). Since CI regenerates `android/`, we'll switch the workflow to keep a
   committed `android/` folder, or inject the file in the build step.
4. Enable **Cloud Firestore** (test mode to start).
5. Tell me, and I'll add `firebase_core` + `cloud_firestore`, wire the pairing
   code to a shared Firestore document, and flip sync on. The app code is already
   structured for it (codes are generated and stored now).

Until then: everything stays **on-device**, and the pairing code is saved locally.
