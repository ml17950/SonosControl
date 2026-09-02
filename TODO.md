# TODOg - Fehler & Verbesserungsmaßnahmen für fb-SonosControl

## Kritische Fehler & Bugs

- [x] **Thread-Safety & Race Conditions bei `SCAN` beheben (`SonosControl.bas`)**
  - `THREADS_OPEN` wird in `threadSonosScan` (Zeile 156, 165) von bis zu 254 Threads gleichzeitig ohne Mutex/Lock verändert.
  - Das kann zu ungenauen Thread-Zählern und Hängenbleiben der Schleife (`Do ... Loop Until Inkey = Chr(27)`) führen.
- [x] **Dateizugriffs-Race-Condition in INI-Datei bei `SCAN` beheben (`SonosControl.bas`)**
  - In `TSNE_Scan_NewData` (Zeilen 148-149) schreiben parallele Threads zeitgleich über `ini.setString` (`WritePrivateProfileString`) in `SonosControl.ini`.
  - Fehlende Thread-Synchronisation/Mutex kann zu Dateibeschädigungen oder Datenverlust führen.
- [x] **Fehlerhafte Parameter in Batch-Skripten korrigieren (`start-sonos.bat`, `stop-sonos.bat`)**
  - `start-sonos.bat` nutzt Subnetz `192.168.2.1` und RINCON-IDs (`RINCON_5CAAFD77B6A201400`, `RINCON_5CAAFD77B68C01400`), die nicht in `SonosControl.ini` existieren (`192.168.151.x`).
  - Skripte schlagen im aktuellen Zustand fehl.
- [x] **Fehlende Auflösung von Raumnamen (`SonosControl.bas`)**
  - Parameter 1 prüft nur `If UCase(Left(SonosIP, 6)) = "RINCON"`. 
  - Die laut Hilfetext vorgesehene Übergabe von Raumnamen (z. B. `SonosControl Partyraum PLAY`) funktioniert bisher nicht, da die Sektion `[Names]` in der INI nicht ausgewertet wird.
- [x] **Inkonsistentes `THREADS_OPEN` Handling in `SONOS_Play` korrigieren (`SonosControl.bas`)**
  - In `SONOS_Play` (Zeile 172) wird `THREADS_OPEN` inkrementiert, aber nie dekrementiert.
  - Bei `SONOS_Pause` und `SONOS_Volume` fehlt dieses Handling vollständig. Überbleibsel aus altem Refactoring entfernen.
- [x] **Eingabe-Validierung für Lautstärke hinzufügen (`SonosControl.bas`)**
  - Bei `SONOS_VOL` fehlt eine Prüfung auf Wertebereich (0–100) sowie eine Prüfung auf gültige numerische Werte.

---

## Funktionale Bugs

- [x] **Exit-Code wird nie gesetzt / Fehlerprüfung ist auskommentiert** (`SonosControl.bas:355-360`)
  Der Block, der `BV` (Rückgabewert von `TSNE_Create_Client`) auswertet und mit `End -1` beendet, ist komplett auskommentiert. Das Programm beendet sich am Ende immer mit `End` (Exit-Code 0) — auch wenn PLAY/PAUSE/VOLUME fehlgeschlagen ist (Verbindung nicht möglich, Timeout, SOAP-Fehler). Für `start-sonos.bat`/`stop-sonos.bat`, die per Scheduled Task laufen, ist ein Fehlschlag dadurch von außen nicht erkennbar.

- [x] **`SONOS_Play` erhöht `THREADS_OPEN`, ohne es je zu dekrementieren** (`SonosControl.bas:172`)
  Nur `SONOS_Play` enthält `THREADS_OPEN = THREADS_OPEN + 1`; `SONOS_Pause` und `SONOS_Volume` tun das nicht. Es gibt kein passendes Dekrement für diesen Pfad. Wirkt wie ein Copy-Paste-Rest aus `threadSonosScan` und ist funktionslos/irreführend, da `THREADS_OPEN` nur in der SCAN-Warteschleife ausgewertet wird.

- [x] **Race Condition auf `THREADS_OPEN`** (`SonosControl.bas:19, 156, 165, 337`)
  `THREADS_OPEN = THREADS_OPEN + 1` / `- 1` wird aus bis zu 254 parallelen Threads (`threadSonosScan`) ohne Mutex/Interlocked-Operation ausgeführt. Read-Modify-Write ist nicht atomar → Updates können sich gegenseitig überschreiben. Im ungünstigen Fall erreicht der Zähler nie 0 (Scan-Wartesschleife hängt, bis `Chr(27)` gedrückt wird) oder wird fälschlich 0, bevor alle Threads fertig sind.

- [x] **Kein Fehler-Feedback bei unbekanntem Gerätenamen** (`SonosControl.bas:291-293`)
  Wird eine `RINCON_...`-ID übergeben, die nicht in der `.ini` steht, liefert `ini.getString` `""` zurück. Das Programm zeigt daraufhin nur den generischen Usage-Text, nicht aber eine klare Meldung wie "Gerät nicht gefunden". Für den Nutzer nicht von "keine Argumente übergeben" zu unterscheiden.

- [x] **SCAN ohne gültige IP führt zu sinnlosen Verbindungsversuchen** (`SonosControl.bas:325-333`)
  `i = InStrRev(SonosIP, ".")`; wird kein `.` gefunden (z. B. Tippfehler oder Gerätename statt IP ohne `.`), ist `i = 0` und `Left(SonosIP, 0) = ""`. Anschließend werden 254 Threads gestartet, die auf `"1"`, `"2"`, … `"254"` (ohne Host-Teil) zu verbinden versuchen, statt vorher zu validieren und abzubrechen.

---

## Robustheit / Validierung

- [x] **Keine Validierung des Volume-Werts** (`SonosControl.bas:315-317, 254`)
  `SONOS_VOL` wird ungeprüft in den SOAP-Body eingesetzt. Werte außerhalb 0–100 oder nicht-numerische Eingaben werden nicht abgefangen, sondern 1:1 an den Sonos-Lautsprecher gesendet.

- [x] **Volume ohne Wertangabe mutet stumm statt zu warnen** (`SonosControl.bas:315-316`)
  Wird `VOLUME`/`VOL` ohne dritten Parameter aufgerufen, wird stillschweigend `SONOS_VOL = "0"` gesetzt (Lautsprecher wird stummgeschaltet). Ein vergessener Parameter sollte eher eine Fehlermeldung/Usage-Hinweis auslösen als eine stille Nebenwirkung zu haben.

- [x] **Führende Null bei einstelligen Lautstärkewerten unmotiviert** (`SonosControl.bas:317`)
  `If Len(SONOS_VOL) = 1 Then SONOS_VOL = "0" & SONOS_VOL` — UPnP `DesiredVolume` benötigt kein zweistelliges Format; Zweck unklar, evtl. Überbleibsel. Sollte entweder dokumentiert oder entfernt werden.

---

## Code-Qualität & Cleanup

- [x] **Totcode und Testcode entfernen (`SonosControl.bas`, `inc/ini.bi`)**
  - Unbenutzte Test-Sub `TSNE_Connected` (Google.de HTTP-Test, Zeilen 24–44) entfernen.
  - Auskommentierten Debug-/Testcode in `SonosControl.bas` bereinigen (Zeilen 88–96, 108–117, 203, 319, 355–360, 371–373).
  - Auskommentierte Altlasten in `inc/ini.bi` (Zeilen 119–171 `getValue`) entfernen.
- [x] **Variablen-Shadowing beheben (`SonosControl.bas`)**
  - `Dim G_Client As UInteger` ist sowohl global (Zeile 14) als auch lokal in `threadSonosScan` (Zeile 161) deklariert.
- [x] **Zeichenkodierung (Encoding) korrigieren**
  - Quellcode-Dateien von ANSI/CP1252 (mit beschädigten Umlauten wie `Empfnger`, `Statusrckgabe`) sauber nach UTF-8 konvertieren.

- [x] **Totes Testcode-Fragment aus der TSNE-Beispielanwendung** (`SonosControl.bas:1-49`)
  `TSNE_Connected` (Verbindungsaufbau zu `www.google.de`) ist ein Rest aus dem ursprünglichen TSNE_V3-Testclient (siehe Kommentar Zeile 5 „TEST-CLIENT für TSNE_V3“) und wird nirgends als Callback registriert (die einzige Verwendung ist in Zeile 319 auskommentiert). Kann entfernt werden.

- [x] **Variablen-Shadowing von `G_Client`** (`SonosControl.bas:14, 161`)
  Globales `Dim G_Client As UInteger` (Zeile 14) wird in `threadSonosScan` durch eine lokale Variable gleichen Namens verdeckt (Zeile 161). Funktioniert, ist aber verwirrend — besserer eigener Name für die Thread-lokale Variable (z. B. `T_Client`) würde Missverständnisse vermeiden.

- [x] **Fehlende schließende Anführungszeichen bei `Print`-Anweisungen** (`SonosControl.bas:302, 304, 305, 306`)
  Mehrere `Print "..."`-Zeilen im Usage-Text sind nicht mit `"` geschlossen (FreeBASIC toleriert das am Zeilenende, ist aber inkonsistent zu den übrigen `Print`-Zeilen und fehleranfällig bei künftigen Änderungen).

- [ ] **`DEBUG`-Konstante ist hart auf `1` codiert** (`SonosControl.bas:21`)
  Ausführliche Debug-Ausgaben (kompletter SOAP-Request/-Response) sind im ausgelieferten Programm immer aktiv und lassen sich nur durch Neukompilieren abschalten. Eine Umschaltung über Kommandozeilen-Flag oder `.ini`-Eintrag wäre praktischer.

- [x] **Datei-Encoding von `SonosControl.bas` ist inkonsistent** (z. B. Zeilen 5, 24, 47, 52 — „fr“, „Empfnger`)
  Die Datei ist laut `file`-Erkennung UTF-8, enthält aber offenbar einzelne nicht-UTF-8-kodierte Umlaute (vermutlich Cp1252/Latin-1-Reste aus einem älteren Editor), die beim Lesen als `` erscheinen. Sollte einheitlich auf eine Kodierung normalisiert werden (inkl. Korrektur der betroffenen Kommentare).

- [x] **Auskommentierter Alt-Code** (`inc/ini.bi:119-171`, `SonosControl.bas:88-96, 108-117`)
  Größere auskommentierte Codeblöcke (alte `getValue`-Implementierung, alte Debug-Ausgaben) könnten entfernt werden, sofern nicht bewusst als Referenz behalten.

---

## Erweiterungen & Neue Features

- [ ] **Erweiterung des Sonos-Funktionsumfangs (`SonosControl.bas`)**
  - [ ] `NEXT` / `PREVIOUS` (Titel vor/zurück via AVTransport)
  - [ ] `MUTE` / `UNMUTE` (Stummschaltung via RenderingControl)
  - [ ] `GETVOLUME` / `GETSTATUS` / `INFO` (Abfragen des aktuellen Titels / Abspielstatus)
- [x] **Exit-Codes für Automatisierung bereitstellen**
  - Rückgabe von System-Exitcodes (`End 0` bei Erfolg, `End 1` bei Fehlern), damit Skripte und Windows Task Scheduler Fehler erkennen können.
- [ ] **Headless-/Batch-Modus optimieren**
  - Optionale Unterdrückung von `Sleep 3000` / Interaktivität bei Aufruf aus Skripten.


## Dokumentation

- [ ] **README.md ist praktisch leer** (nur Titelzeile) — enthält keine Beschreibung, Build-Anleitung oder Nutzungshinweise, obwohl `SonosControl.bas` selbst brauchbare Usage-Infos enthält (Zeilen 296-309), die sich als README-Inhalt anbieten würden.
- [ ] **SCAN mit Gerätename statt IP nicht dokumentiert**: Da `RINCON_...`-Namen bereits vor dem `Select Case` aufgelöst werden, funktioniert `SonosControl <RINCON_ID> SCAN` technisch (scannt das Subnetz der aufgelösten IP), ist aber im Usage-Text nicht erwähnt.
- [ ] Keine Build-Anleitung (`fbc32`-Aufrufparameter) im Repo dokumentiert, obwohl der volle Pfad zu `fbc32.exe` projektspezifisch ist (siehe `SonosControl.fbp`: `fbc32 -s console`).

## Projekt / Sonstiges

- [ ] **`.gitignore` schließt `*.bat`, `*.ini`, `*.exe`, `*.undo` komplett aus** (`.gitignore`) — dadurch sind `start-sonos.bat`/`stop-sonos.bat` (enthalten die produktiv genutzten RINCON-IDs und den Zeitplan) nicht versioniert. Falls das kein bewusster Datenschutz-Schritt ist, sollte zumindest eine `*.bat.example`-Vorlage ohne echte Geräte-IDs eingecheckt werden, damit der Automatisierungs-Teil des Projekts nicht nur lokal existiert.
- [ ] `SonosControl.ini` enthält reale interne IP-Adressen und Raumnamen (z. B. „Partyraum“, „Buchhaltung / Controlling“) — durch `.gitignore` zwar nicht versioniert, aber liegt unverschlüsselt im Projektverzeichnis. Unkritisch für ein privates LAN-Tool, aber erwähnenswert falls das Repo je geteilt wird.
- [ ] `SonosControl.fbp` referenziert einen fest einprogrammierten „Run“-Pfad mit realer lokaler IP (`192.168.151.1 SCAN`) — nur relevant, falls das Projekt weitergegeben wird.
