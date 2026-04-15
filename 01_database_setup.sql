-- ============================================================
-- UAC EVALUATIONSSTUDIE - DATENBANK SETUP
-- ============================================================
-- Diese SQL-Datei legt die Tabelle "responses" an, aktiviert
-- Row Level Security und definiert die Zugriffsrechte.
--
-- AUSFÜHRUNG:
-- 1. In Supabase einloggen → Projekt "uac-evaluation" öffnen
-- 2. Linke Seitenleiste → "SQL Editor"
-- 3. "New query" klicken
-- 4. Diesen gesamten Inhalt einfügen
-- 5. "Run" klicken (oder Cmd/Ctrl + Enter)
--
-- Nach erfolgreicher Ausführung solltest du in "Table Editor"
-- die neue Tabelle "responses" sehen.
-- ============================================================

-- Tabelle für Fragebogen-Antworten
CREATE TABLE IF NOT EXISTS public.responses (
    -- Technische Felder
    id              BIGSERIAL PRIMARY KEY,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    language        TEXT CHECK (language IN ('de', 'en')),
    duration_seconds INTEGER,

    -- Pseudonymisierter Code (Mutter-Vorname + Geburtstag + Ort)
    anonymous_code  TEXT NOT NULL,

    -- Zeitpunkt & Institution
    zeitpunkt       TEXT CHECK (zeitpunkt IN ('T1', 'T2', 'T3', NULL)),
    institution     TEXT,
    institution_name TEXT,

    -- Soziodemografie
    sozio_alter     INTEGER,
    sozio_geschlecht TEXT,
    sozio_bildung   TEXT,
    sozio_semester  INTEGER,
    sozio_vorerfahrung TEXT,
    sozio_land      TEXT,
    sozio_muttersprache TEXT,
    sozio_sonstiges TEXT,

    -- Skala A: Selbstwirksamkeit (Schwarzer & Jerusalem, 1995)
    a1 SMALLINT, a2 SMALLINT, a3 SMALLINT, a4 SMALLINT, a5 SMALLINT, a6 SMALLINT,

    -- Skala B: Autonomie (Deci & Ryan, 2000)
    b1 SMALLINT, b2 SMALLINT, b3 SMALLINT, b4 SMALLINT, b5 SMALLINT,

    -- Skala C: Soziale Eingebundenheit (Deci & Ryan, 2000)
    c1 SMALLINT, c2 SMALLINT, c3 SMALLINT, c4 SMALLINT, c5 SMALLINT,

    -- Skala D: Intrinsische Motivation (Ryan & Deci, 2000)
    d1 SMALLINT, d2 SMALLINT, d3 SMALLINT, d4 SMALLINT, d5 SMALLINT,

    -- Skala E: Reflexionskompetenz (Flavell, 1979)
    e1 SMALLINT, e2 SMALLINT, e3 SMALLINT, e4 SMALLINT, e5 SMALLINT,

    -- Skala F: Wohlbefinden (WHO-5, 1998)
    f1 SMALLINT, f2 SMALLINT, f3 SMALLINT, f4 SMALLINT, f5 SMALLINT,

    -- Skala G: Kooperation (Johnson & Johnson, 2009)
    g1 SMALLINT, g2 SMALLINT, g3 SMALLINT, g4 SMALLINT, g5 SMALLINT,

    -- Skala H: Psychologische Sicherheit (Edmondson, 1999)
    h1 SMALLINT, h2 SMALLINT, h3 SMALLINT, h4 SMALLINT, h5 SMALLINT, h6 SMALLINT,

    -- Skala I: Resilienz (Connor & Davidson, 2003)
    i1 SMALLINT, i2 SMALLINT, i3 SMALLINT, i4 SMALLINT, i5 SMALLINT, i6 SMALLINT,

    -- Skala J: Kompetenz (Deci & Ryan, 2000)
    j1 SMALLINT, j2 SMALLINT, j3 SMALLINT, j4 SMALLINT,

    -- Skala K: Flow-Erleben (Csikszentmihalyi, 1990)
    k1 SMALLINT, k2 SMALLINT, k3 SMALLINT, k4 SMALLINT,

    -- Skala L: Naturverbundenheit (Mayer & Frantz, 2004)
    l1 SMALLINT, l2 SMALLINT, l3 SMALLINT, l4 SMALLINT, l5 SMALLINT,

    -- Skala M: Partizipation (ICCS 2022)
    m1 SMALLINT, m2 SMALLINT, m3 SMALLINT, m4 SMALLINT, m5 SMALLINT, m6 SMALLINT,

    -- Skala N: Transformation (Mezirow, 1991)
    n1 SMALLINT, n2 SMALLINT, n3 SMALLINT, n4 SMALLINT,

    -- Skala O: Motivation vor Bildung (Kontrollvariable)
    o1 SMALLINT, o2 SMALLINT, o3 SMALLINT,

    -- Skala Q: Ungewissheitstoleranz (Dalbert, 1999)
    q1 SMALLINT, q2 SMALLINT, q3 SMALLINT, q4 SMALLINT, q5 SMALLINT, q6 SMALLINT
);

-- Index für schnellere Abfragen im Dashboard
CREATE INDEX IF NOT EXISTS idx_responses_code ON public.responses(anonymous_code);
CREATE INDEX IF NOT EXISTS idx_responses_zeitpunkt ON public.responses(zeitpunkt);
CREATE INDEX IF NOT EXISTS idx_responses_institution ON public.responses(institution);
CREATE INDEX IF NOT EXISTS idx_responses_created ON public.responses(created_at DESC);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
-- RLS aktivieren: Ohne Policy kann NIEMAND auf die Daten zugreifen.
-- Wir definieren dann gezielt, was erlaubt ist.

ALTER TABLE public.responses ENABLE ROW LEVEL SECURITY;

-- Bestehende Policies entfernen (falls das Script ein zweites Mal läuft)
DROP POLICY IF EXISTS "Anyone can submit a response" ON public.responses;
DROP POLICY IF EXISTS "Authenticated users can read all responses" ON public.responses;

-- Policy 1: Jeder darf schreiben (anonymer Fragebogen-Submit)
-- Der "anon"-Key (im Frontend) darf INSERT, aber nichts anderes.
CREATE POLICY "Anyone can submit a response"
    ON public.responses
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Policy 2: Nur authentifizierte Nutzer dürfen lesen
-- Das Dashboard loggt sich mit einem separaten Supabase-Auth-User ein
-- und darf dann alle Daten lesen.
CREATE POLICY "Authenticated users can read all responses"
    ON public.responses
    FOR SELECT
    TO authenticated
    USING (true);

-- Hinweis: UPDATE und DELETE sind bewusst NICHT erlaubt.
-- Daten sollen nach dem Einreichen nicht mehr verändert werden können.

-- ============================================================
-- FERTIG
-- ============================================================
-- Nach "Run" solltest du in der Sidebar unter "Table Editor" die
-- neue Tabelle "responses" sehen. Sie ist leer und bereit für die
-- ersten Antworten.
