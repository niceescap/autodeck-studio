# Retouches Android après `flutter create`

`flutter create` régénère la plateforme Android ; applique ensuite ces deux
retouches dans `android/app/src/main/AndroidManifest.xml`.

## 1. Permission INTERNET (obligatoire pour le backend)

Juste sous `<manifest ...>` :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 2. Nom affiché + permission caméra

Dans `<application ...>` :

```xml
<application
    android:label="AutoDeck Studio"
    ...>
```

Et à côté de la permission INTERNET (pour « Prendre une photo ») :

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

## Build AAB (sur noe)

```bash
cd ~/autodeck-studio/app
flutter build appbundle --release \
  --dart-define=AUTODECK_API=https://44i.webredirect.org/autodeck
# artefact : build/app/outputs/bundle/release/app-release.aab
```

Récupération depuis Termux : `scp noe:~/autodeck-studio/app/build/app/outputs/bundle/release/app-release.aab .`
