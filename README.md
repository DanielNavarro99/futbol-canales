# Mi Fútbol DANS 🐕⚽

App Android personal de streaming de fútbol con arquitectura "Sabueso" para interceptar streams .m3u8.

## Estructura del proyecto

```
lib/
  main.dart                      ← Entrada de la app
  screens/
    home_screen.dart             ← Pantalla principal con cuadrícula
    video_screen.dart            ← Reproductor con PiP y Cast
  services/
    stream_hunter.dart           ← El Sabueso — intercepta el .m3u8

android/
  app/src/main/
    AndroidManifest.xml          ← Permisos + PiP configurado
    res/xml/
      network_security_config.xml ← Permite tráfico HTTP
    kotlin/.../MainActivity.kt   ← Canal nativo para PiP

assets/
  icon/
    icon.png                     ← Ícono de la app (agregar manualmente)
```

## Canales — JSON en GitHub

Los canales se manejan desde un archivo JSON externo:
```
https://raw.githubusercontent.com/DanielNavarro99/futbol-canales/main/canales.json
```

Formato del JSON:
```json
[
  {
    "nombre": "TyC Sports",
    "emoji": "🇦🇷",
    "hora": "24/7",
    "fuentes": [
      { "label": "Fuente 1 - FutbolLibre", "url": "https://..." },
      { "label": "Fuente 2 - LatamVidz", "url": "https://..." }
    ]
  }
]
```

## Instalación desde cero

### 1. Requisitos
- Flutter SDK en `C:\flutter`
- Android Studio (para el SDK)
- VS Code con extensiones Flutter y Dart

### 2. Setup
```bash
flutter pub get
dart run flutter_launcher_icons   # genera el ícono
```

### 3. Compilar e instalar
```bash
# Ver dispositivos conectados
flutter devices

# Instalar en el teléfono
flutter run -d <DEVICE_ID> --release

# O generar APK
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

### 4. build.gradle.kts — configuración importante
```kotlin
defaultConfig {
    minSdk = 21
    multiDexEnabled = true
}
```

## Cómo agregar canales

1. Entra a `https://github.com/DanielNavarro99/futbol-canales`
2. Edita `canales.json`
3. Agrega el canal con sus fuentes
4. Commit — la app lo toma automáticamente al refrescar

## Funcionalidades

- ✅ Sabueso intercepta .m3u8 y .ts con token
- ✅ Múltiples fuentes por canal
- ✅ Picture in Picture (PiP)
- ✅ Cast a TV (Smart View)
- ✅ Pantalla completa horizontal automática
- ✅ Máxima calidad disponible automática
- ✅ JSON remoto — sin recompilar para actualizar canales
- ✅ Fondo animado de campo de fútbol
