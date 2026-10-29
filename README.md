# BharatAstrology - Commercial Business Muhurtham Calculation Engine

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE)
[![GitHub Repository](https://img.shields.io/badge/GitHub-veejeay%2FbusinessmuhurthamG-181717?logo=github)](https://github.com/veejeay/businessmuhurthamG)
[![Platform](https://img.shields.io/badge/Platform-Windows_x64_%7C_Modern_Browsers-success.svg)]()
[![Build & Test](https://github.com/veejeay/businessmuhurthamG/actions/workflows/ci.yml/badge.svg)](https://github.com/veejeay/businessmuhurthamG/actions)

> **Official Source Repository:** [https://github.com/veejeay/businessmuhurthamG](https://github.com/veejeay/businessmuhurthamG)

A deterministic, commercial-grade Electional Astrology (**Muhurtham**) and Panchanga calculation suite developed in partnership with **Bharatheya Vasthu Jyothisha Padanasala** (BharatAstrology.org). 

The platform supports high-precision classical Kerala Panchangam, Ashtama Shuddhi verification, Diurnal Octants (Rahu Kalam, Gulika Kalam, Yamagandam), KP 249 Cuspal Sub-Lord analysis, Western Electional aspects, and BaZi metaphysical synthesis with 1-minute discrete election increments.

---

## 🌟 Key Features

1. **Deterministic Ephemeris Engine**:
   - **Swiss Ephemeris (GNU AGPL-3.0)** integration as primary default.
   - High-precision internal mathematical ephemeris fallback (Meeus/VSOP87 algorithms with True Chitrapaksha/Lahiri Ayanamsha).
2. **Multi-Tradition Astrological Synthesis**:
   - **Kerala Jyotish**: Kollam solar month alignments, 28-day Nakshatra matrix, Udaya/Asthamana diurnal octants.
   - **Vedic Electional**: Tarabalam (9 Tara cycles), Chandrabalam, Panchaka Dosha, Ashtama Shuddhi (purified 8th house).
   - **KP System**: 249 Cuspal Sub-Lord analysis for 10th house business success verification.
   - **Western Electional & BaZi**: Moon aspect purity, Void-of-Course detection, Day Master and Seasonality harmony.
3. **Step 4 Interactive Deep-Dive**:
   - Dynamic 3-state traffic lights (🟢 Favorable, 🟡 Moderate, 🔴 Inauspicious) with visual dimming for rules intentionally omitted in Step 2.
   - Classical D1 Rashi and D9 Navamsha kundali visualization.
4. **Zero External Dependencies / 100% Offline Standalone Executable**:
   - Compiles into a single, standalone 64-bit Windows executable (`BharatAstrologyMuhurtham.exe`, ~230 KB) with embedded assembly resources.
   - Zero installation required. High-DPI aware, isolated sandboxed data directory, single-instance mutex.
5. **Zero-innerHTML DOM Security**:
   - Rigorously enforced zero-innerHTML DOM standard to eliminate cross-site scripting (XSS) vectors.

---

## 📂 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI workflow (Build, Test, Checksum)
├── tests/
│   └── test_muhurtham_engine.js       # Headless automated regression suite (43/43 tests passing)
├── app.ico                            # High-resolution golden Surya application icon
├── app.manifest                       # Windows High-DPI & OS compatibility manifest
├── build_native_x64.ps1               # Native x64 C# compiler script (embeds HTML payload)
├── index.html                         # Full single-page interactive application
├── verify_build_pipeline.ps1          # Pre-flight CI/CD verification script (15/15 checks)
├── BharatAstrologyMuhurtham.exe       # Standalone 64-bit Windows release binary
├── BharatAstrologyMuhurtham.exe.sha256 # Cryptographic SHA-256 release checksum
├── LICENSE                            # GNU Affero General Public License v3.0
└── README.md                          # Project documentation & source reference
```

---

## 🚀 Quick Start

### 1. Web / Direct Browser
Open `index.html` directly in any modern browser (Chrome, Edge, Firefox, Safari). No web server or Node.js runtime required.

### 2. Standalone Windows x64 Application
Double-click `BharatAstrologyMuhurtham.exe` to launch the native desktop application.

---

## 🛠️ Build & Verification

### Run Automated Tests
```powershell
node tests/test_muhurtham_engine.js
```

### Compile Native Windows x64 Binary
```powershell
powershell -ExecutionPolicy Bypass -File .\build_native_x64.ps1
```

### Run CI/CD Pipeline Verification
```powershell
powershell -ExecutionPolicy Bypass -File .\verify_build_pipeline.ps1
```

---

## 📜 Source Information & Licensing

- **Source Code Repository**: [https://github.com/veejeay/businessmuhurthamG](https://github.com/veejeay/businessmuhurthamG)
- **License**: GNU Affero General Public License v3.0 ([LICENSE](LICENSE))
- **Ephemeris Attribution**: Swiss Ephemeris is published by [Astrodienst AG](https://www.astro.com/swisseph/) under GNU AGPL-3.0.
- **Institutional Partner**: Bharatheya Vasthu Jyothisha Padanasala ([BharatAstrology.org](https://bharatastrology.org/)), Thiruvananthapuram, Kerala, India.
