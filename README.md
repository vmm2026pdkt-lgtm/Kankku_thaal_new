# கணக்கு தாள் — Flutter Android App

Native Flutter rewrite of the [kanakku-thaal.netlify.app](https://kanakku-thaal.netlify.app) web app.
அதே Supabase backend-ஐ (project ref `saqwrtwdoncrqygqwdgg`) அப்படியே reuse செய்கிறது — DB மாற்றம் தேவையில்லை.

## 📁 என்ன இருக்கு

- Riverpod state management
- sqflite local DB (entries + categories) + SharedPreferences (settings/budgets/recurring) — free-tier offline
- Supabase Auth + cloud sync (paid tier, admin-approval gated) — reuses existing `profiles` + `user_data` tables
- fl_chart donut (category) + bar (monthly) charts
- PDF export (`pdf`+`printing`), Excel export (`excel`), JSON backup (`share_plus`)
- PIN lock (`flutter_secure_storage` — upgrade vs. the web app's plaintext PIN)
- Recurring transactions auto-generated on app open
- Budget alerts (SnackBar)
- WhatsApp contact button for cloud subscription
- GitHub Actions workflow — builds APK + AAB automatically on every push to `main`

## 🚀 GitHub-ல் போட்டு APK Build பண்ண படிகள்

### 1. புதிய GitHub repo உருவாக்கு
GitHub.com → New repository → பெயர் இடு (உதா: `kanakku-thaal-flutter`) → Create.

### 2. இந்த project-ஐ push பண்ணு
இந்த zip-ஐ unzip பண்ணி, அந்த folder-க்குள் போய்:

```bash
git init
git add .
git commit -m "Initial Flutter app"
git branch -M main
git remote add origin https://github.com/<உங்க-username>/kanakku-thaal-flutter.git
git push -u origin main
```

### 3. Automatic APK Build
`main` branch-க்கு push பண்ணின உடனே, **GitHub Actions** தானாகவே ஆரம்பிச்சு APK/AAB build பண்ணும்.
- Repo-ல் **Actions** tab-க்கு போங்க
- "Build APK" workflow run-ஐ கிளிக் பண்ணுங்க (சுமார் 5-8 நிமிடம் ஆகும்)
- முடிஞ்சதும் கீழே **Artifacts** section-ல் `kanakku-thaal-apk` மற்றும் `kanakku-thaal-aab` download பண்ணலாம்

APK-ஐ நேரடியா phone-ல் install பண்ணி test பண்ணலாம் (unknown sources allow பண்ண வேண்டும்). AAB Play Store submission-க்கு.

### 4. Manual local build (optional, Flutter SDK install ஆகி இருந்தா)

```bash
flutter pub get
flutter create --platforms=android .   # missing android build files fill பண்ணும்
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

## ⚠️ Build பண்றதுக்கு முன் கவனிக்க வேண்டியவை

1. **`android/` folder incomplete-ஆ இருக்கும்** — நான் `AndroidManifest.xml` மட்டும் தந்திருக்கேன் (app label + INTERNET permission உடன்). மீதி Gradle files (`build.gradle`, `gradle-wrapper` etc.) GitHub Actions workflow-ல் `flutter create --platforms=android .` command மூலம் தானாகவே fill ஆகும். Local-ல் build பண்ணனும்னா நீங்களும் இதே command run பண்ணனும் (உங்க existing `AndroidManifest.xml`-ஐ overwrite செய்யாது).
2. **App icon** — default Flutter icon தான் இப்போ இருக்கு. உங்க web app-ல் இருக்கிற `icons/icon-512.png`-ஐ Android launcher icon ஆக மாத்த `flutter_launcher_icons` package பயன்படுத்தலாம் (README-க்கு கீழே optional step).
3. **Release signing** — இப்போதைய workflow **debug-signed** APK/AAB தான் தரும் (testing-க்கு போதும்). Play Store-க்கு அனுப்ப **release keystore** உருவாக்கி, `android/key.properties` + workflow-ல் GitHub Secrets சேர்க்க வேண்டும் (இது 5-ஆவது கட்டமா பின்னாடி செய்யலாம்).
4. **Font** — `NotoSansTamil` font family theme-ல் reference பண்ணப்பட்டிருக்கு, ஆனா font file சேர்க்கப்படலை (system default Tamil font fallback ஆகும்). சேர்க்க வேண்டுமா சொல்லுங்க, `pubspec.yaml`-ல் font entry + font file உடன் தருகிறேன்.

## 🔜 இன்னும் செய்ய வேண்டியவை (உங்க தேவைப்படி)

- App icon replace (`flutter_launcher_icons`)
- Release signing keystore setup (Play Store submission-க்கு)
- Local data → Cloud migration flow (old localStorage/PWA users-க்கு)
- Push notifications for budget alerts (`flutter_local_notifications`)
- Admin panel: தற்போது web `admin.html`-ஐயே தொடர்ந்து பயன்படுத்தலாம் — Flutter-ல் rebuild தேவையில்லை

## 🗂️ Project Structure

```
lib/
 ├── core/            # theme, constants (Supabase config, categories)
 ├── models/          # Entry, Category, Budget, RecurringRule, AppSettings
 ├── services/        # db_service (sqflite), prefs_service, supabase_service,
 │                     sync_service, export_service, business_logic
 ├── providers/       # Riverpod StateNotifiers
 ├── screens/         # AppGate, HomeShell, Home/Transactions/Category/Monthly/
 │                     Settings pages, Login, SetupWizard, PinLock
 └── widgets/         # entry_form_sheet (bottom sheet for add/edit)
```
