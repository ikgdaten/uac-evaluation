# UAC Evaluation – Setup-Anleitung

Dieses Paket enthält alles, was für die Online-Erhebung der UAC-Evaluationsstudie nötig ist.

## Inhalt

| Datei | Zweck |
|-------|-------|
| `index.html` | Der zweisprachige Fragebogen (DE/EN). Wird auf GitHub Pages gehostet und an die Teilnehmenden verschickt. |
| `dashboard.html` | Passwortgeschütztes Dashboard mit Live-Zahlen, Charts und CSV-Export (Rohwerte, Reverse-kodierte `*_R` Spalten, Skalenmittelwerte). |
| `00_complete_setup.sql` | Einmaliges, konsolidiertes SQL-Skript, das die Tabelle `responses` samt RLS-Policies in Supabase anlegt (inkl. aller Spalten für die 95 Items + deprecated Spalten j1–j4, f4, f5 für Abwärtskompatibilität). |
| `.github/workflows/supabase-keepalive.yml` | GitHub Action, die alle 4 Tage einen HTTP-Ping an Supabase sendet, damit das Free-Tier-Projekt nicht nach 7 Tagen Inaktivität pausiert wird. |
| `README.md` | Diese Anleitung. |

## Architektur in einem Satz

Statische HTML-Dateien auf GitHub Pages schreiben und lesen über die Supabase-JS-Library direkt in eine Postgres-Datenbank (EU-Region Frankfurt, DSGVO-konform). Kein eigener Server, keine laufenden Kosten.

## Einmal-Setup

### 1. Datenbank anlegen (Supabase)

Bereits erledigt. Die Tabelle `responses` existiert und RLS-Policies sind aktiv:

- `INSERT` für `anon` und `authenticated` → Fragebogen kann Antworten speichern
- `SELECT` nur für `authenticated` → Dashboard sieht Daten, Fragebogen nicht
- `UPDATE` / `DELETE` sind bewusst **nicht** erlaubt

Falls die Tabelle neu aufgesetzt werden muss, `00_complete_setup.sql` im Supabase SQL-Editor ausführen.

### 2. Dashboard-User anlegen (Supabase)

Bereits erledigt. In Supabase → Authentication → Users ist ein User angelegt:

- E-Mail: `dashboard@uac-eval.local`
- Passwort: wird separat kommuniziert, nicht im Repository

### 3. GitHub Pages aktivieren

1. Im Repository `ikgdaten/uac-evaluation`: **Settings → Pages**
2. Source: **Deploy from a branch**
3. Branch: **main**, Folder: **/ (root)**
4. Speichern. Nach 1–2 Minuten ist die Seite unter `https://ikgdaten.github.io/uac-evaluation/` erreichbar.

## Deployment (bei Änderungen)

1. Die beiden HTML-Dateien aus diesem Paket in das Repository kopieren (z. B. per Drag & Drop in die GitHub-Weboberfläche).
2. Commit mit kurzer Nachricht (z. B. „v1: Fragebogen + Dashboard live").
3. GitHub Pages aktualisiert sich automatisch innerhalb von 1–2 Minuten.

### URLs nach dem Deployment

- Fragebogen: `https://ikgdaten.github.io/uac-evaluation/index.html`
- Dashboard:  `https://ikgdaten.github.io/uac-evaluation/dashboard.html`

## Funktionen im Fragebogen

- 95 Items in 19 Skalen (A–T, ohne J), deutsch und englisch umschaltbar (oben rechts)
- Skala J (Kompetenz) wurde entfernt, da SDT-Kompetenz indirekt über Skala A (Selbstwirksamkeit) und K (Flow) miterfasst wird
- Neu seit April 2026: Skala B überarbeitet (Inhalt/Prozess-Subdimensionen), Skala D mit IMI-Items, Skala F auf WHO-5 Kurzform gekürzt, Skala G neu (CRCG), plus 4 neue Skalen P (PSS-4 Stress), R (FB-SZ-K Studienzufriedenheit), S (Rovai Lernzuwachs), T (LCQ-6 Autonomieunterstützung)
- Soziodemografie, anonymer Teilnehmer-Code, Einwilligungserklärung
- Auto-Backup im Browser-Speicher (localStorage) alle 30 Sekunden, falls jemand mitten im Ausfüllen die Seite schließt
- Beim Absenden: vollständige Validierung, dann Insert in die Supabase-Tabelle
- Die gewählte Sprache landet als `language`-Feld mit in der Datenbank

## Funktionen im Dashboard

- Supabase-Auth-Login (E-Mail + Passwort)
- Stats-Karten: Antworten gesamt, UAC-Gruppe, Vergleichsgruppe, letzter Eingang
- Filter: Institution, Zeitpunkt (T1/T2/T3)
- Charts: Verteilung pro Institution (Balken), pro Zeitpunkt (Donut), Mittelwerte pro Skala UAC vs. konventionell (Balken), Antworten im Zeitverlauf (Linie)
- Tabelle der letzten 20 Antworten
- CSV-Export aller gefilterten Zeilen (UTF-8 BOM → öffnet direkt in Excel)

## Supabase Free Tier – wichtig!

Das kostenlose Supabase-Tier pausiert Projekte nach 7 Tagen Inaktivität. Da die Erhebung über Wochen läuft und es Wartepausen zwischen T1, T2 und T3 gibt, muss das Projekt regelmäßig „angepingt" werden.

**Lösung:** Die GitHub Action `.github/workflows/supabase-keepalive.yml` erledigt das automatisch:

- Läuft alle 4 Tage um 08:00 UTC (Cron `0 8 */4 * *`) — sicherer Abstand zur 7-Tage-Grenze
- Zusätzlich manuell auslösbar im Tab **Actions → Supabase Keep-Alive → Run workflow**
- Nutzt die Repo-Secrets `SUPABASE_URL` und `SUPABASE_KEY` (beide müssen in **Settings → Secrets and variables → Actions** gesetzt sein)
- Sendet einen authentifizierten GET an `/rest/v1/responses?select=id&limit=1`; Erfolg = HTTP 200, andernfalls schlägt die Action fehl und GitHub verschickt automatisch eine Fehler-E-Mail an den Repo-Owner

## Technischer Stack

- Frontend: Vanilla HTML/CSS/JavaScript, keine Build-Tools
- Datenbank: Supabase (PostgreSQL, EU-West, DSGVO-konform)
- Libraries via CDN: `@supabase/supabase-js@2`, `chart.js@4.4.0`
- Hosting: GitHub Pages (kostenlos)

## Datenschutz

- Alle Daten **pseudonymisiert** (selbst generierter Code aus Mutter-Vorname + Geburtstag + Geburtsort — erlaubt Verknüpfung von T1/T2/T3, aber keine Re-Identifikation)
- Speicherort: Supabase-Rechenzentrum Frankfurt (EU)
- Keine Cookies, kein Tracking, keine Drittanbieter-Analytics, keine IP-Adressen-Speicherung
- Rechtsgrundlage: Art. 6 Abs. 1 lit. a DSGVO (Einwilligung), Informationspflicht nach Art. 13 DSGVO erfüllt
- Auftragsverarbeitung (Art. 28 DSGVO) mit Supabase; Drittlandtransfer abgedeckt durch Standardvertragsklauseln (Art. 46 Abs. 2 lit. c DSGVO)
- Kein Profiling / keine automatisierte Entscheidungsfindung (Art. 22 DSGVO)
- Widerrufsrecht: über den selbstgewählten Pseudonym-Code möglich (via Kontakt zur Projektleitung), praktisch eingeschränkt durch den Pseudonymisierungsgrad — so im Einwilligungstext erklärt
