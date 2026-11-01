# home_pantry

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Web error reporting

Flutter Web uses Sentry for error reporting because Firebase Crashlytics does
not support web. The Sentry project DSN is configured as the default in
`lib/main.dart`, so the debug test-error button works without extra launch
arguments. To use a different Sentry project, override it at build or run time:

```powershell
flutter run -d chrome --dart-define=SENTRY_DSN=YOUR_SENTRY_DSN
flutter build web --dart-define=SENTRY_DSN=YOUR_SENTRY_DSN
```

In the debug build, select **Надіслати тестову помилку** on the login form.
The app confirms success or displays the sending error. The event appears in
the Sentry project's **Issues** page after processing.
The DSN is a public client identifier; do not put Sentry auth tokens or other
secrets in the app.

## Firebase Authentication

The app uses Firebase Authentication for email/password registration, sign-in,
password-reset email, profile updates, password changes, sign-out, and restoring
the current session. Users who first signed in with Google can set a password
from their profile; this links email/password to the same Firebase account so
they can continue signing in with either method. The app is currently connected
to Firebase project `homepantry-f22f4`. In Firebase Console, enable
**Email/Password** and **Google** under **Authentication → Sign-in method**.
Check the **Password reset** email template under **Authentication → Templates**.
Add the web host (for example, `localhost`) under
**Authentication → Settings → Authorized domains** for Google popup sign-in.
After requesting a reset, check Gmail's Spam and Promotions folders. Firebase
may return a generic success for addresses without an email/password account
when email-enumeration protection is enabled; Google-only users must first set
a password from their signed-in profile.

Google sign-in on Android additionally requires the app's SHA-1/SHA-256 signing
fingerprints and a web OAuth client. The current `android/app/google-services.json`
has no OAuth clients; after enabling Google, download the updated file from
Firebase Console and replace it. For iOS/macOS, add the Google client ID and
reversed client ID from `GoogleService-Info.plist` to the platform's URL scheme
configuration as described by the `google_sign_in` platform setup guide.

Registration names accept English and Ukrainian letters, spaces, apostrophes,
and hyphens. Profile photos may be set to an HTTPS image URL. Password changes
for email/password accounts ask for the current password and reauthenticate;
Google-only accounts can link an email/password credential from their profile.
