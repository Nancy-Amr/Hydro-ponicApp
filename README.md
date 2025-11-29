📘 SMART Hydroponic – Flutter Mobile Application

A real-time monitoring and control system for small-scale hydroponic environments.

🌱 Overview

SMART Hydroponic is a Flutter-based mobile application designed to monitor, analyze, and control a hydroponic system in real-time. The app integrates hardware sensors with cloud services (Firebase), local storage, and automation features to ensure a stable environment for plant growth. It supports real-time alerts, analytics, automated control rules, and manual override.

This project is part of CSE 431 – Mobile Programming (Fall 2025).

🚀 Key Features
🌡️ Sensor Monitoring

Real-time readings: Temperature, water level, humidity, pH, EC/TDS, and light intensity

Auto-update & manual refresh modes

Calibration controls

Status indicators (Safe / Warning / Critical)

⚙️ Control Panel

Control actuators in real-time:

Water pump

LED grow lights

Cooling fans

Nutrient dosing pumps

Scheduling & automation mode

Emergency stop

Control history log

📊 Analytics & Data Visualization

Historical charts for all sensors

Trend analyses

Exportable logs

Timestamp-based insights

🧠 Intelligent Automation

Threshold configuration

Automated responses when limits are exceeded

Alerts on anomalies (high temperature, low water level)

🔔 Notifications

Push notifications for sensor warnings

Time-based reminders

Custom notification settings

🗄️ Local Storage (SQLite)

Stores alerts, actuator logs, timestamps, schedules

Clean DB structure and optimized queries

Integrated with Provider/BLoC state management

🗣️ Accessibility Features

Text-to-Speech (TTS)

Speech Recognition (SR) for app commands

🔐 Authentication

Firebase Authentication

Login, registration, and password recovery

📱 UI & UX

Modern, responsive UI

MVVM architecture

Support for different screen sizes

🏗️ System Architecture
Sensors → Microcontroller (ESP32/ESP8266/Arduino) → Firebase → Flutter App  
                                               ↓  
                                         SQLite (Local Logs)

🧰 Tech Stack
Category	Technologies
Mobile Framework	Flutter (Dart)
Backend / Cloud	Firebase Realtime DB / Firestore, Firebase Auth
Local DB	SQLite
Architecture	MVVM (+ Provider/BLoC)
Hardware	ESP32 / ESP8266 / Arduino + Sensors (DHT22, EC, pH, Ultrasonic, LDR, etc.)
Testing	Flutter test (unit, widget), integration tests, ADB automated tests
Dev Tools	VS Code, Android Studio, PowerShell/Bash scripts
🗃️ Project Structure (Simplified)
lib/
 ├── models/
 ├── views/
 ├── view_models/   # MVVM controllers
 ├── services/
 │     ├── firebase_service.dart
 │     ├── sqlite_service.dart
 │     ├── notification_service.dart
 ├── widgets/
 ├── tests/
assets/
test_scripts/

🔥 Firebase Integration

The app uses Firebase for:

Real-time sensor data

Actuator commands

User authentication

Cloud-sync configuration

Firebase listeners ensure continuous data streaming to the dashboard.

💾 SQLite Local Database

Stores:

Sensor warnings

Actuator history

Schedule entries

Test logs

Offline mode caching

🧪 Testing & Automation
✔ Unit Tests
✔ Widget Tests
✔ Integration Tests
✔ Automated ADB Test Script

A PowerShell/Bash script automates:

Opening the emulator

Running all test cases

Simulating inputs

Generating logs

Example command:

./run_auto_tests.ps1

🛠️ Installation & Setup

Clone the repository:

git clone https://github.com/Nancy-Amr/Hydro-ponicApp.git
cd Hydro-ponicApp


Install dependencies:

flutter pub get


Run the app:

flutter run

🤝 Team Contribution

(Add each member's contribution here)

Member	Role	Contribution
Name 1	UI/UX	Layout & navigation
Name 2	Backend	Firebase & DB
Name 3	Hardware	Sensor integration
Name 4	Testing	Auto-test script
📝 Video Demo

🎥 YouTube link:
(add link here)

📄 Documentation

A full project manual is included covering:

Introduction

Similar app survey

UI design

Code navigation

Test cases





