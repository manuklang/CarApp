# DriveDeck – Auto-Dashboard für iPhone & CarPlay

Eine eigene Dashboard-App mit Widgets fürs Auto: Tacho, Kompass, Höhe, Uhr, Wetter, Fahrtstatistik, Standort, Akku und Koordinaten – auf dem iPhone (Hoch- und Querformat, z. B. in der Halterung) und in **CarPlay**.

## Funktionen

**iPhone**
- Großer Tacho (GPS) mit Skala, Nadel und optionaler Tempo-Warnung (wird rot ab einer Schwelle)
- Kompass, der sich mit der Fahrtrichtung dreht (bei Fahrt GPS-Kurs, im Stand Magnetkompass)
- Höhe über dem Meer mit Genauigkeit
- Uhr & Datum, iPhone-Akku, Straße/Ort, Koordinaten
- Lokales Wetter (Open-Meteo, kein API-Schlüssel nötig): Temperatur, gefühlt, Min/Max, Wind
- Fahrtstatistik: Strecke, Fahrzeit, Ø- und Höchstgeschwindigkeit, Gesamt-km – bleibt nach Neustart erhalten
- Widgets ein-/ausblenden und sortieren, 6 Akzentfarben, km/h ↔ mph, m ↔ ft, °C ↔ °F
- Bildschirm bleibt an (abschaltbar)

**CarPlay** (Tab-Leiste mit 3 Tabs, aktualisiert sich jede Sekunde)
- **Cockpit:** Tacho-Grafik + Geschwindigkeit, Kompass-Pfeil + Richtung, Höhe, Uhrzeit/Datum, Straße/Ort
- **Wetter:** aktuelle Temperatur & Zustand, Min/Max, Wind & Luftfeuchte
- **Fahrt:** Strecke, Fahrzeit, Ø, Max, Gesamt; „Fahrt zurücksetzen“ mit Bestätigung

> Hinweis: Apple erlaubt in CarPlay keine frei gezeichneten Oberflächen für Nicht-Navi-Apps. DriveDeck nutzt deshalb die CarPlay-Kategorie **„Driving Task“** mit Apples Listen-Vorlagen und gerenderten Instrumenten-Symbolen.

## Projektaufbau

```
project.yml                 XcodeGen-Projektdefinition (die .xcodeproj wird daraus erzeugt)
Config/                     Info.plist und Entitlements (mit / ohne CarPlay)
DriveDeck/App               App-Einstieg (SwiftUI)
DriveDeck/Services          Standort, Fahrt, Wetter, Einstellungen, gemeinsames Modell
DriveDeck/Views             iPhone-Dashboard, Instrumente, Einstellungen
DriveDeck/CarPlay           CarPlay-Szene und Grafik-Renderer
.github/workflows/ios.yml   Build bei jedem Push + TestFlight-Upload per Knopfdruck
scripts/                    Icon-Generator, Xcode-Auswahl für den Runner
```

Ein Mac ist **nicht** nötig: Gebaut und hochgeladen wird auf einem macOS-Runner von GitHub Actions.

---

## Auf dein iPhone über TestFlight – Schritt für Schritt

### 1. Apple Developer Program
Du brauchst eine Mitgliedschaft im [Apple Developer Program](https://developer.apple.com/programs/) (99 €/Jahr). Ohne sie gibt es weder TestFlight noch CarPlay-Freigabe.

### 2. CarPlay-Berechtigung bei Apple beantragen
CarPlay-Apps brauchen eine von Apple freigeschaltete Berechtigung (Entitlement).
1. Formular öffnen: <https://developer.apple.com/contact/carplay/>
2. Kategorie **„Driving Task“** wählen und die App kurz beschreiben, z. B.:
   *„Dashboard für Fahrer: zeigt GPS-Geschwindigkeit, Fahrtrichtung, Höhe, Wetter und Fahrtstatistik (Strecke, Fahrzeit, Ø/Max) in Listenform an.“*
3. Die Prüfung dauert meist einige Tage bis Wochen. Danach ist bei deiner App-ID unter *Certificates, Identifiers & Profiles → Identifiers → (deine App) → Additional Capabilities* **CarPlay Driving Task** verfügbar – dort aktivieren.

Bis die Freigabe da ist, kannst du die iPhone-App schon per TestFlight testen (siehe Schritt 6, Haken bei „CarPlay“ entfernen).

### 3. App-ID und App in App Store Connect anlegen
1. Unter [Identifiers](https://developer.apple.com/account/resources/identifiers/list) eine neue App-ID anlegen, z. B. `de.manuklang.drivedeck` (oder eigene).
2. In [App Store Connect](https://appstoreconnect.apple.com/apps) → **+ → Neue App**: Plattform iOS, Name z. B. „DriveDeck“ (der Name muss im App Store eindeutig sein, notfalls „DriveDeck Dashboard“ o. Ä.), Sprache Deutsch, die Bundle-ID von eben, SKU frei wählbar.

### 4. API-Schlüssel für App Store Connect erstellen
1. App Store Connect → **Benutzer und Zugriff → Integrationen → App Store Connect API → Team-Schlüssel → +**
2. Name z. B. „GitHub Actions“, Zugriff **Admin** (nötig, damit Zertifikate und Profile automatisch erstellt werden können).
3. Die `.p8`-Datei herunterladen (geht nur einmal!), **Key ID** und **Issuer ID** notieren.
4. Deine **Team ID** findest du unter <https://developer.apple.com/account> → Mitgliedschaft.

### 5. Secrets in GitHub hinterlegen
Repository → **Settings → Secrets and variables → Actions**

| Typ | Name | Wert |
|---|---|---|
| Secret | `APPLE_TEAM_ID` | Team ID (10 Zeichen) |
| Secret | `ASC_KEY_ID` | Key ID des API-Schlüssels |
| Secret | `ASC_ISSUER_ID` | Issuer ID |
| Secret | `ASC_PRIVATE_KEY` | kompletter Inhalt der `.p8`-Datei (inkl. `-----BEGIN PRIVATE KEY-----`) |
| Variable *(optional)* | `BUNDLE_ID` | deine Bundle-ID, Standard: `de.manuklang.drivedeck` |

### 6. Build hochladen
GitHub → **Actions → iOS → Run workflow**
- Haken **„CarPlay-Entitlement einbinden“** nur setzen, wenn Apple die CarPlay-Berechtigung freigegeben und du sie bei der App-ID aktiviert hast – sonst schlägt die Signierung fehl.
- Nach ca. 10 Minuten ist der Build in App Store Connect unter **TestFlight** sichtbar (Apple verarbeitet ihn danach noch 5–30 Minuten).

### 7. Auf dem iPhone installieren
1. In App Store Connect → TestFlight → **Interne Tests** eine Gruppe anlegen und dich selbst (deine Apple-ID) hinzufügen.
2. Die **TestFlight**-App aus dem App Store auf dem iPhone installieren, Einladung annehmen, DriveDeck installieren.
3. App einmal auf dem iPhone öffnen und den Standortzugriff erlauben.

### 8. Im Auto mit CarPlay
iPhone mit CarPlay verbinden – DriveDeck erscheint auf dem CarPlay-Homescreen (sonst unter *Einstellungen → Allgemein → CarPlay → dein Auto → Anpassen* hinzufügen).

---

## Lokal entwickeln (optional, mit Mac)
```bash
brew install xcodegen
xcodegen generate
open DriveDeck.xcodeproj
```
Im Simulator: *I/O → External Displays → CarPlay* zeigt die CarPlay-Oberfläche; *Features → Location → Freeway Drive* simuliert eine Fahrt. Ohne freigegebenes Entitlement in den Build-Einstellungen `CODE_SIGN_ENTITLEMENTS` auf `Config/DriveDeck-NoCarPlay.entitlements` stellen.

## Datenquellen & Hinweise
- Geschwindigkeit, Richtung und Höhe kommen vom GPS des iPhones und können leicht von der Tachoanzeige des Autos abweichen.
- Wetterdaten: [Open-Meteo](https://open-meteo.com) (CC BY 4.0).
- Bitte während der Fahrt nicht am iPhone bedienen.
