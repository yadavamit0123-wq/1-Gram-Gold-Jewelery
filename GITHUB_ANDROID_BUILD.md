# GitHub se APK / AAB build

## App config (already set in code)

- **Package:** `com.pt.onegramgoldjewelery`
- **API:** `https://1gramgoldjewelery.in`
- **Launcher icon source:** `assets/images/logo.png`

## Repo secrets (GitHub → Settings → Secrets)

**Path:** `https://github.com/yadavamit0123-wq/1-Gram-Gold-Jewelery/settings/secrets/actions`  
Tab: **Repository secrets** (Environment secrets par mat rakho jab tak workflow mein `environment:` na ho).

Names **exactly** (copy-paste):

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

### `signReleaseBundle` — keystore password was incorrect

Gradle tak build chal jaye aur sirf signing par fail ho, to **GitHub secrets local `android/key.properties` se match nahi kar rahe**, ya base64 **alag `.jks`** file ka hai.

1. Local pe verify (Mac):

```bash
cd "/Users/amityadav/Projects/1 Gram Gold All/1-Gram-Gold-Jewelery"
keytool -list -keystore android/upload-keystore.jks -alias upload
```

Jo **store password** aur **alias** yahan chale, wahi `ANDROID_STORE_PASSWORD` aur `ANDROID_KEY_ALIAS` secrets mein daalo. `ANDROID_KEY_PASSWORD` usually same as store password.

2. Base64 **usi** file se banao jo local signing mein use karti ho:

```bash
base64 -i android/upload-keystore.jks | tr -d '\n' | pbcopy
```

GitHub → **ANDROID_KEYSTORE_BASE64** secret **Update** (purana hata ke naya paste). Secret value ke aage–peeche space/newline mat chhodo.

3. Workflow dubara **Run workflow** — ab signing se pehle `keytool` step galat password/alias par turant fail karega.
