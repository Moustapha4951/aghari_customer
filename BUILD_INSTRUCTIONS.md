# Building Your aghari_customer iOS App

This guide provides the steps to build the `aghari_customer` iOS app (`.ipa` file) for App Store distribution.

## 1. Crucial Pre-checks (Your Responsibility in Xcode)

Before you begin the build process, it's critical to ensure the following are correctly configured in your Xcode project and Apple Developer account. Failure to do so will likely result in build errors or App Store rejection.

*   **Bundle Identifier:**
    *   The Xcode project is currently configured with `PRODUCT_BUNDLE_IDENTIFIER` set to `com.aghari.customer`.
    *   **You MUST ensure this exact Bundle ID (`com.aghari.customer`) is registered on your Apple Developer account.** If it's not, you need to either register it or update the `PRODUCT_BUNDLE_IDENTIFIER` in the Xcode project (Runner target > Build Settings > Product Bundle Identifier) to match an existing one you own.

*   **Provisioning Profiles & Signing Certificates:**
    *   You need valid provisioning profiles (specifically, an App Store distribution profile) and signing certificates (Apple Distribution certificate) associated with the Bundle ID (`com.aghari.customer`) and your Apple Developer Team account.
    *   These are managed on the [Apple Developer Portal](https://developer.apple.com/account/).

*   **Xcode Signing Configuration:**
    *   Open your project in Xcode (`ios/Runner.xcworkspace`).
    *   Select the "Runner" target in the project navigator.
    *   Go to the "Signing & Capabilities" tab.
    *   **Select your Team** from the dropdown menu.
    *   Ensure signing is correctly configured.
        *   **Automatic signing:** Xcode will attempt to manage profiles for you. This usually works well if your certificates and profiles are correctly set up in your developer account.
        *   **Manual signing:** If you prefer, you can manually select the Signing Certificate and Provisioning Profile. Ensure you select the correct App Store distribution profile.

*   **Encryption (ITSAppUsesNonExemptEncryption):**
    *   The `Info.plist` file (located in `ios/Runner/Info.plist`) currently has `ITSAppUsesNonExemptEncryption` set to `false`.
    *   **Double-check if your app uses any non-exempt encryption.** Standard HTTPS calls (which Firebase and many network libraries use) are generally exempt from this declaration.
    *   However, if your app includes custom encryption algorithms or uses encryption in ways that are not covered by Apple's exemptions, you might need to set this to `true` and provide necessary documentation to Apple.
    *   **Consult Apple's official guidelines on export compliance if you are unsure.** Incorrect declaration can lead to issues during App Store review or even legal complications.

## 2. Build Steps (Commands to Run in Your Terminal)

Once you've completed all the pre-checks, follow these steps in your terminal:

1.  **Open your Terminal application.**

2.  **Navigate to your project's root directory:**
    ```bash
    cd path/to/aghari_customer
    ```
    (Replace `path/to/aghari_customer` with the actual path to your project)

3.  **Clean the project:**
    This command removes old build artifacts.
    ```bash
    flutter clean
    ```

4.  **Get Flutter packages:**
    This command fetches all the dependencies defined in your `pubspec.yaml` file.
    ```bash
    flutter pub get
    ```

5.  **Navigate to the iOS directory:**
    ```bash
    cd ios
    ```

6.  **Update and install CocoaPods dependencies:**
    This command installs or updates the native iOS libraries (Pods) used by your Flutter plugins and your project. The `--repo-update` flag ensures your local CocoaPods specs repo is updated, which is good practice to fetch the latest versions of pods.
    ```bash
    pod install --repo-update
    ```
    *Note: This step can sometimes take a while, especially on the first run or after a long time.*

7.  **Navigate back to the project root directory:**
    ```bash
    cd ..
    ```

8.  **Run the build command:**
    This command builds the `.ipa` file.
    ```bash
    flutter build ipa --export-options-plist=ios/ExportOptions.plist
    ```
    *   **`ios/ExportOptions.plist`**: This file is pre-configured in your project for App Store distribution (`method: app-store`). It tells the Xcode build system how to package your app.
    *   **Signing Prompts**: You might be prompted by your system to allow `codesign` to access your keychain for signing certificates.
    *   **Xcode Account**: Ensure you are logged into the correct Apple Developer account in Xcode (Xcode > Settings > Accounts). The `flutter build ipa` command utilizes Xcode's underlying build system and its account information for signing.

## 3. Output

If the build process completes successfully:

*   The compiled app archive (`.ipa` file) will be located in the following directory within your project:
    `build/ios/ipa/`

You can then take this `.ipa` file and upload it to the App Store using Transporter or directly from Xcode's Organizer.

---

Good luck with your app submission!
