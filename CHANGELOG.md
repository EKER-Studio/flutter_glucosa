# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-12

### Release v1.1.0 — Bluetooth LE Glucometer Sync & Measurement Context

Adds full support for wireless Bluetooth Low Energy (BLE) blood glucose meter synchronization adhering to the official Bluetooth SIG Glucose Service (GLS) specification.

#### 🚀 Features

* **Bluetooth Low Energy (GLS 0x1808) Glucometer Synchronization:**
  * **Standard GLS Protocol:** Wireless sync compatible with all major standard-compliant meters (Accu-Chek Instant/Guide, Contour Next/Plus ONE, Beurer GL49/GL50 evo, Rossmax, and generic GLS devices) via `flutter_blue_plus`.
  * **Record Access Control Point (RACP 0x2A52):** Reliable multi-record retrieval with opcode commands, sequence numbers, and graceful timeout handling.
  * **Measurement Context (0x2A34):** Ingestion of carbohydrate tags, meal markers, and rapid/short-acting insulin dosages automatically mapped to Glucosa's clinical `MealContext` and detailed reading notes.
  * **Incremental Synchronization:** Automatic sequence tracking (`lastSequenceNumber + 1`) to fetch only new measurements since the last sync, speeding up transfers.
  * **Intelligent Deduplication:** Time-window ($\pm 60\,\text{s}$) and value matching prevents duplicate entries when re-syncing meter memory.
  * **Battery Service (0x180F):** Real-time glucometer battery level monitoring (0x2A19) with dedicated badge and status indicators.
  * **Remembered Meter Persistence:** Automatic device memory with 1-tap quick sync card in Tools and contextual quick-sync button directly in the Add Reading form (`AddEditGlucoseReadingScreen`).
  * **Localization:** Full English and Polish strings for discovery, status notifications, battery levels, and sync shortcuts.

## [1.0.0] - 2026-10-03

### Release v1.0.0 — Initial Production Release

Initial production release of **Glucosa**, a local-first metabolic health and diabetes management platform built with Flutter, Riverpod 3.x, and Isar Community.

#### 🚀 Features

* **Multi-Metric Health Tracking:**
  * **Blood Glucose:** Log measurements in mg/dL or mmol/L with rich clinical meal context (`beforeBreakfast`, `afterBreakfast`, `beforeLunch`, `afterLunch`, `beforeDinner`, `afterDinner`, `snack`, `bedtime`, `night`, `fasting`, `recheck`, `other`).
  * **HbA1c:** Record laboratory glycated hemoglobin in NGSP (%) or IFCC (mmol/mol) with automatic bidirectional conversion.
  * **Blood Pressure:** Track systolic and diastolic readings (mmHg) with clinical status indicators (`Normal`, `Elevated`, `High`, `Crisis`).
  * **Blood Ketones:** Monitor beta-hydroxybutyrate levels (mmol/L) with clinical threshold categorization.
  * **Cholesterol Panel:** Record Total, LDL, and HDL lipid profiles (mg/dL).
  * **Body Weight:** Track body weight with automatic kg and lbs unit conversion.

* **Data Visualization & Insights:**
  * **Interactive Trend Charts:** Time-series line charts powered by `fl_chart` with Day, Week, and Month bucketing.
  * **Target Range Boundaries:** Visual upper and lower target guideline thresholds rendered directly on charts.
  * **Estimated HbA1c (eA1c):** Dynamically calculated from blood glucose averages using the validated ADAG 2008 formula.
  * **Interactive Calendar:** Full-featured monthly calendar view with day-by-day reading inspection and direct entry logging.
  * **Unified History Feed:** Chronological activity stream across all metric types with filter chips, swipe-to-delete, and instant undo actions.
  * **Habits & Milestones:** Logging streaks, milestone achievement badges, and clinical visit summary generator.

* **Platform Integrations & Utilities:**
  * **Health Platform Sync:** Bi-directional integration with Apple HealthKit (iOS) and Google Health Connect (Android) via `health` for syncing glucose, blood pressure, ketones, and weight.
  * **Home Screen Widgets:** Compact (2x1) and full-size (4x2) Android AppWidgets (`home_widget`) for fast glucose glanceability.
  * **Biometric Security:** App lock protected by Face ID, Touch ID, Fingerprint, or system PIN (`local_auth`) with background timeout auto-lock.
  * **HbA1c Calculator:** Clinical conversion tool between average glucose and estimated HbA1c.
  * **Scheduled Reminders:** Local recurring notifications (`flutter_local_notifications`) for medications, glucose checks, and lifestyle logging.
  * **Data Portability:** Full CSV export of health records with metric filtering and native share sheet integration (`share_plus`).

* **Personalization & Clinical Standards:**
  * **Clinical Target Range Presets:** Built-in standard thresholds from the American Diabetes Association (ADA: 70–180 mg/dL), American Association of Clinical Endocrinologists (AACE: 110–140 mg/dL), UK NICE (72–153 mg/dL), and fully customizable ranges.
  * **Diabetes Profiles:** Tailored tracking workflows for Type 1, Type 2, Gestational, and LADA diabetes.
  * **Theme & Display:** Seamless switching between System, Light, and Dark themes adhering to Material 3 tokens.
  * **Localization:** 10 fully supported locales: English (`en`), German (`de`), Spanish (`es`), French (`fr`), Italian (`it`), Japanese (`ja`), Korean (`ko`), Dutch (`nl`), Polish (`pl`), and Portuguese (`pt`).

#### 🏗 Architecture & Engineering

* **Clean Architecture:** Strict feature-first packaging structure (`domain/`, `data/`, `presentation/`) with inward-facing dependency rules and complete decoupling of presentation from persistence models.
* **State Management:** Riverpod 3.x with code generation (`@riverpod`), stream-driven notifiers piped from Isar watchers, and automatic provider lifecycle disposal.
* **Local Persistence:** High-performance local NoSQL database via `isar_community` with zero network overhead.
* **Production Observability:** Structured logging via `AppLogger`, global provider lifecycle tracking via `AppProviderObserver`, and rotating on-device crash logs via `AppCrashReporter`.
* **Testing:** Comprehensive test suite of 840+ unit, widget, and integration tests covering domain logic, clinical converters, and presentation widgets.
