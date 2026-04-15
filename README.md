# UAC Evaluation – Setup-Anleitung

Dieses Paket enthält alles, was für die Online-Erhebung der UAC-Evaluationsstudie nötig ist.

## Inhalt

| Datei | Zweck |
|-------|-------|
| `index.html` | Der zweisprachige Fragebogen (DE/EN). Wird auf GitHub Pages gehostet und an die Teilnehmenden verschickt. |
| `dashboard.html` | Passwortgeschütztes Dashboard mit Live-Zahlen, Charts und CSV-Export. |
| `01_database_setup.sql` | Einmaliges SQL-Skript, das die Tabelle `responses` samt RLS-Policies in Supabase anlegt. |
| `README.md` | Diese Anleitung. |

## Architektur in einem Satz

Statische HTML-Dateien auf GitHub Pages schreiben und lesen über die Supabase-JS-Library direkt in eine Postgres-Datenbank (EU-Region Frankfurt, DSGVO-konform). Kein eigener Server, keine laufenden Kosten.

## Einmal-Setup

### 1. Datenbank anlegen (Supabase)

Bereits erledigt. Die Tabelle `responses` existiert und RLS-Policies sind aktiv:

- `INSERT` für `anon` und `authenticated` → Fragebogen kann Antworten speichern
- `SELECT` nur für `authenticated` → Dashboard sieht Daten, Fragebogen nicht
- `UPDATE` / `DELETE` sind bewusst **nicht** erlaubt

Falls die Tabelle neu aufgesetzt werden muss, `01_database_setup.sql` im Supabase SQL-Editor ausführen.

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

- 80 Items in 16 Skalen (A–O, Q), deutsch und englisch umschaltbar (oben rechts)
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

Das kostenlose Supabase-Tier pausiert Projekte nach 7 Tagen Inaktivität. Da die Erhebung über Wochen läuft und es Wartepausen zwischen T1, T2 und T3 gibt, muss das Projekt regelmäßig „angepingt" werden. Ein cron-job.org-Trigger reicht (täglich eine beliebige GET-Anfrage an `https://fbcbtoqmyyefdmevygvv.supabase.co/rest/v1/responses?select=id&limit=1`).

## Technischer Stack

- Frontend: Vanilla HTML/CSS/JavaScript, keine Build-Tools
- Datenbank: Supabase (PostgreSQL, EU-West, DSGVO-konform)
- Libraries via CDN: `@supabase/supabase-js@2`, `chart.js@4.4.0`
- Hosting: GitHub Pages (kostenlos)

## Datenschutz

- Alle Daten pseudonymisiert (nur selbst gewählter Code, keine Namen/E-Mails)
- Speicherort: Supabase-Rechenzentrum Frankfurt (EU)
- Keine Cookies, kein Tracking, keine Drittanbieter-Analytics
- Widerrufsrecht: technisch nicht möglich, da vollständig anonym (so im Einwilligungstext erklärt)
