# GitHub se APK / AAB build

## App config (already set in code)

- **Package:** `com.pt.onegramgoldjewelery`
- **API:** `https://1gramgoldjewelery.in`
- **Launcher icon source:** `assets/images/logo.png`

## Repo secrets (GitHub → Settings → Secrets)

| Secret | Example |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of your `.jks` file |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | e.g. `upload` |

## CI step (before `flutter build`)

```bash
echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/upload-keystore.jks
cat > android/key.properties <<EOF
storePassword=$ANDROID_STORE_PASSWORD
keyPassword=$ANDROID_KEY_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
storeFile=upload-keystore.jks
EOF
flutter pub get
dart run flutter_launcher_icons
flutter build appbundle --release
flutter build apk --release
```

`android/key.properties` and `*.jks` are gitignored — commit mat karna.

## GitHub Actions

Workflow: `.github/workflows/android-release.yml`

- **Trigger:** push to `main`, ya **Actions → Android APK & AAB → Run workflow**
- **Output:** Artifacts `release-aab` aur `release-apk` (30 din)

Pehle repo mein ye file commit + push karo; secrets set hone ke baad build auto chalegi.
