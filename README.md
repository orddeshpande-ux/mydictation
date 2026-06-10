# 🎙️ OmniScribe AI — Smart Dictation & Voice Assistant

OmniScribe AI is a cross-platform helper designed for intelligent multilingual dictation, automated grammar cleanup, and voice cloning. It is specifically tailored for **Legal, Academic, and Spiritual workflows**, supporting English, Hindi, and Marathi (including code-switching—mixing languages in a single sentence).

---

## 🚀 How to Run on Your Laptop (Windows)

We have created a one-click script that starts the background AI services and launches the application for you.

1. Locate **`run_windows.bat`** in the project folder.
2. **Double-click** the file to run it.
3. The script will:
   * Start the local AI voice cloning server in a minimized background window.
   * Launch the OmniScribe AI desktop application on your screen.

---

## 📱 How to Run on Your Android Phone

To run and install the application directly onto your connected Android phone:

1. **Connect your phone** to your laptop using a USB cable.
2. **Enable USB Debugging** on your phone:
   * Go to **Settings** -> **About Phone**.
   * Find **Build Number** and tap it **7 times** (you will see a message saying "You are now a developer!").
   * Go back to Settings -> System -> **Developer Options** (or search developer options in Settings).
   * Scroll down and turn on **USB Debugging**.
   * If prompted on your phone's screen, select **Allow / Trust this computer**.
3. **Set USB Mode**: Ensure your phone's USB connection mode is set to **File Transfer** / **MTP** (not just Charging).
4. **Double-click `run_mobile.bat`** in the project folder.
5. Select Option **`[1] Build and Sideload`** (Recommended) by typing `1` and pressing Enter.
6. The script will build the app, install it permanently on your phone, and copy your generated voice files/profiles.

---

## 🔧 First-Time Quick Installation Guide (If things don't work)

If double-clicking the batch files shows errors about missing tools, here is how to set them up:

### 1. Install Flutter (For running the app)
* Flutter is already installed and set up in this environment. If you are setting up on a new computer:
  * Download the Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows).
  * Extract it to a folder (e.g., `C:\src\flutter`) and add its `bin` folder to your computer's Path environment variables.

### 2. Install Python & UV (For the voice server)
* If the terminal window says Python is missing:
  * Open a PowerShell/Terminal window and run: `uv python install`
  * Or download Python 3.10 from [python.org](https://www.python.org/downloads/release/python-3100/) and check "Add Python to PATH" during installation.

### 3. Install Android SDK (For phone deployment)
* If `run_mobile.bat` says the Android SDK is not found:
  * Download and install **Android Studio** from [developer.android.com](https://developer.android.com/studio).
  * Launch Android Studio and follow the initial Setup Wizard (this downloads the SDK).
  * Open Android Studio -> **More Actions** -> **SDK Manager** -> Select **SDK Tools** -> Check **Android SDK Command-line Tools (latest)** -> click **Apply**.

---

## ❓ Frequently Asked Questions (FAQ)

### Q1: How do I connect the app on my phone to the AI server on my laptop?
1. Make sure both your phone and laptop are connected to the **same Wi-Fi network**.
2. Find your laptop's local IP address (e.g., `192.168.1.50`). You can find this by running `ipconfig` in the Windows Command Prompt.
3. Open the OmniScribe AI app on your phone, tap the **Settings** icon (top-right gear), and enter the IP address (e.g., `http://192.168.1.50:5050`) in the server URL field.

### Q2: Why is the app not listening to my voice?
* Ensure that you have allowed **Microphone** and **Speech Recognition** permissions.
* On first startup, the app will ask for permission. If you denied it, go to your phone's Settings -> Apps -> OmniScribe AI -> Permissions -> Allow Microphone.

### Q3: What do the three "Domain Modes" do?
* **Legal Mode**: Automatically corrects transcripts to match legal terminology, structures text into standard sections (e.g., jurisdiction, facts), and highlights missing standard clauses.
* **Academic Mode**: Formats citations, structures paragraphs for thesis standards, and flags missing references.
* **Spiritual Mode**: Focuses on phonetic clarity, removes speech fillers (like "um", "ah"), and preserves the flow of spoken spiritual or philosophical content.

---

## 📂 Project Structure Overview

Here is a quick look at where the important files live in this project:

* 📁 `lib/src/screens/` — App screens (Home, History, Settings, Voice Manager).
* 📁 `lib/src/services/` — Integrations with system services:
  * `stt_service.dart` — Speech-to-Text translation.
  * `brain_service.dart` — Custom prompts and AI cleanup.
  * `voice_clone_service.dart` — Local Voice Cloning server communicator.
* 📁 `lib/src/blocs/` — Logic and state manager for dictation actions.
* 📁 `voice_server/` — Python background server for voice generation and text-to-speech.
* 📄 `run_windows.bat` & `run_mobile.bat` — Direct launchers for Windows and Android.
