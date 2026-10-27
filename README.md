# Ostadchi Flutter v0.4.1

Flutter source for the Ostadchi skilled-workers marketplace prototype.

The project source is arranged at the repository root so build services can identify it as a Flutter project. The Codemagic workflow first runs `flutter create --platforms=android .` to generate the Android platform files and Gradle wrapper, then fetches dependencies, runs analysis and tests, and builds a debug APK.

**Important:** If using the ZIP, extract it first and put the project contents in the GitHub repository root so `pubspec.yaml` is visible on the repository home page. Do not upload only the ZIP file; Codemagic does not automatically treat files inside a ZIP as the project.

Current prototype: Persian home page and service categories only. Phone OTP, database, worker profiles, reviews, contracts, and payments are not connected yet.

The APK build has not been run in this environment; the Codemagic workflow must confirm the final build.
