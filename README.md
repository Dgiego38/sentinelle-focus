# SENTINELLE FOCUS — Guide de build sur Windows (sans Mac)

## Structure du projet Xcode (multi-targets)

```
SentinelleFocus/
├── SentinelleFocus/                  ← App principale
│   ├── SentinelleApp.swift
│   ├── FocusManager.swift
│   ├── DashboardView.swift
│   ├── SessionView.swift
│   └── ConfigurationView.swift
├── ShieldExtension/                  ← Shield Configuration Extension
│   └── ShieldConfiguration.swift
└── LiveActivityExtension/            ← Live Activity / Dynamic Island
    └── DynamicIslandWidget.swift
```

---

## Étape 1 — Ouvrir le projet dans VS Code (Windows)

Installe ces extensions VS Code :
- **Swift** (sswg.swift-lang)
- **iOS Simulator** (non disponible sur Windows — utilise Codemagic)

---

## Étape 2 — Créer le projet Xcode (à faire une fois sur Codemagic)

### Entitlements requis (SentinelleFocus.entitlements)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
  <key>com.apple.developer.family-controls</key>
  <true/>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.com.yourcompany.sentinellefocus</string>
  </array>
</dict>
</plist>
```

### Info.plist — Clés requises
```xml
<key>NSFamilyControlsUsageDescription</key>
<string>Sentinelle Focus utilise Screen Time pour bloquer les applications distrayantes pendant vos sessions de concentration.</string>
```

---

## Étape 3 — Build Cloud avec Codemagic (GRATUIT 500 min/mois)

### 3.1 — Créer un compte sur https://codemagic.io

### 3.2 — Push le projet sur GitHub
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/TON_USER/sentinelle-focus.git
git push -u origin main
```

### 3.3 — Fichier codemagic.yaml (à la racine du projet)

```yaml
workflows:
  ios-workflow:
    name: Sentinelle Focus iOS Build
    max_build_duration: 60
    environment:
      xcode: latest
      cocoapods: default
    scripts:
      - name: Set up code signing
        script: |
          keychain initialize
      - name: Build
        script: |
          xcodebuild \
            -project SentinelleFocus.xcodeproj \
            -scheme SentinelleFocus \
            -configuration Debug \
            -sdk iphonesimulator \
            -destination 'generic/platform=iOS Simulator' \
            build
    artifacts:
      - build/ios/outputs/**/*.ipa
```

### 3.4 — Pour tester sur un vrai iPhone (sans Mac)
- Inscris-toi sur **Apple Developer Program** (99$/an)
- Génère un profil de provisioning sur developer.apple.com
- Configure Codemagic avec ton certificat p12 + profil .mobileprovision

---

## Alternative gratuite — TestFlight via GitHub Actions

```yaml
# .github/workflows/ios-build.yml
name: Build iOS
on: [push]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          xcodebuild -scheme SentinelleFocus \
            -sdk iphonesimulator build
```

GitHub Actions offre macOS runners gratuits (2000 min/mois sur compte gratuit).

---

## Frameworks Apple requis (liés dans Xcode)

| Framework | Usage |
|-----------|-------|
| `FamilyControls` | Autorisation Screen Time |
| `ManagedSettings` | Activation des Shields |
| `DeviceActivity` | Monitoring du temps d'écran |
| `ActivityKit` | Dynamic Island + Lock Screen |
| `SwiftUI` | Interface utilisateur |

---

## Notes importantes

1. **FamilyControls** nécessite un entitlement Apple — soumets une demande sur :
   https://developer.apple.com/contact/request/family-controls-distribution

2. L'app doit être distribuée via **TestFlight ou App Store** pour que les Shields fonctionnent.

3. En mode **Simulateur**, FamilyControls est disponible mais les Shields ne bloquent pas réellement les apps.

4. Le `group.com.yourcompany.sentinellefocus` doit être **identique** dans l'app et toutes les extensions.
