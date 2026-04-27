-- ============================================================
-- UAC EVALUATIONSSTUDIE – VOLLSTÄNDIGES DATENBANK-SETUP
-- ============================================================
-- Konsolidiertes Setup-Script (kanonischer Stand der Datenbank).
-- Stand: 2026-04-27 (Skala-O-Replacement nach Häcker-Methodengespräch)
--
-- AUSFÜHRUNG:
-- 1. Supabase Dashboard → SQL Editor → "New query"
-- 2. Diesen gesamten Inhalt einfügen
-- 3. "Run" klicken (Cmd/Ctrl + Enter)
--
-- IDEMPOTENZ:
-- Diese Datei ist sicher mehrfach ausführbar. Sie nutzt durchgehend
-- "IF NOT EXISTS" / "IF EXISTS"-Klauseln. Bestehende Daten werden
-- NICHT gelöscht. Neue Spalten werden additiv ergänzt.
--
-- Enthält:
--   • Tabelle "responses" mit allen Skalen + Soziodemografie
--   • Drei TEXT-Spalten für offene Fragen F1–F3 (ersetzt Skala O)
--   • Row Level Security (RLS)
--   • Indizes
--
-- Skalenstruktur (95 Items + 3 offene Fragen):
--   A  Selbstwirksamkeit         6 Items   Bandura (1997) / Schwarzer & Jerusalem (1995)
--   B  Autonomie Inhalt+Prozess  6 Items   Deci & Ryan (2000), Reeve (2006)
--                                          (Häufigkeits-Anker statt Zustimmung, ab April 2026)
--   C  Soziale Eingebundenheit   5 Items   Deci & Ryan (2000)
--   D  Intrinsische Motivation   5 Items   Ryan & Deci (2000), Wilde et al. (2009) IMI
--   E  Selbstreguliertes Lernen  5 Items   Roth, Ogrin & Schmitz (2016)
--   F  Wohlbefinden              3 Items   WHO-5, Diener et al. (1985) — Kurzform
--   G  Kooperation (CRCG)        5 Items   León-del-Barco et al. (2018)
--   H  Psychologische Sicherheit 6 Items   Edmondson (1999, 2018)
--   I  Resilienz                 6 Items   Connor & Davidson (2003)
--   K  Flow-Erleben              4 Items   Csikszentmihalyi (1990)
--   L  Naturverbundenheit        5 Items   Mayer & Frantz (2004)
--   M  Partizipation & Demokratie 6 Items  Schulz et al. (2023)
--   N  Transformation            4 Items   Mezirow (1991)
--   O  ENTFERNT (April 2026)              ersetzt durch offene Fragen F1–F3
--   P  Wahrgenommener Stress     4 Items   Cohen et al. (1983) PSS-4
--   Q  Ungewissheitstoleranz     6 Items   Dalbert (1999) UGTS
--   R  Studienzufriedenheit      6 Items   Westermann et al. (1996) FB-SZ-K
--   S  Wahrgenommener Lernzuwachs 4 Items  Rovai et al. (2009)
--   T  Autonomieunterstützung    6 Items   Black & Deci (2000) LCQ-6
--
--   F1 Bildungs-Wertehaltung           offene Antwort   (offen_wichtigkeit)
--   F2 Lerninhalte letzter Monat       offene Antwort   (offen_letzter_monat)
--   F3 Erleben des Wichtigen           offene Antwort   (offen_erleben)
--
-- Reverse-codierte Items (Dashboard: 6 − Wert):
--   a3, b2, c3, d3, e2, g4, h3, i3, k2, l2, m3, p2, p3, q5, q6, r6
--
-- Deprecated, aber Spalten bleiben für Altdaten:
--   j1–j4 (Skala J Kompetenzerleben, entfernt vor April 2026)
--   f4, f5 (Wohlbefinden Langform, jetzt Kurzform)
--   o1–o3 (Skala O Vor-Motivation, ersetzt durch F1–F3 ab April 2026)
-- ============================================================

-- Tabelle für Fragebogen-Antworten
CREATE TABLE IF NOT EXISTS public.responses (
    -- Technische Felder
    id                  BIGSERIAL PRIMARY KEY,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    language            TEXT CHECK (language IN ('de', 'en')),
    duration_seconds    INTEGER,

    -- Pseudonymisierter Code (Mutter-Vorname + Geburtstag + Ort)
    anonymous_code      TEXT NOT NULL,

    -- Zeitpunkt & Institution
    zeitpunkt           TEXT CHECK (zeitpunkt IN ('T1', 'T2', 'T3')),
    institution         TEXT,
    institution_name    TEXT,

    -- Soziodemografie
    sozio_alter                 INTEGER,
    sozio_geschlecht            TEXT,
    sozio_semester              INTEGER,
    sozio_bildung_vater         TEXT,
    sozio_bildung_mutter        TEXT,
    sozio_studienfach           TEXT,
    sozio_migration             TEXT,
    sozio_finanziell            TEXT,
    sozio_finanziell_objektiv   TEXT,

    -- ============================================================
    -- SKALEN-ITEMS (alle SMALLINT, Likert 1–5)
    -- ============================================================

    -- Skala A: Selbstwirksamkeit (6 Items) — R: a3
    a1 SMALLINT CHECK (a1 BETWEEN 1 AND 5),
    a2 SMALLINT CHECK (a2 BETWEEN 1 AND 5),
    a3 SMALLINT CHECK (a3 BETWEEN 1 AND 5),  -- REVERSE
    a4 SMALLINT CHECK (a4 BETWEEN 1 AND 5),
    a5 SMALLINT CHECK (a5 BETWEEN 1 AND 5),
    a6 SMALLINT CHECK (a6 BETWEEN 1 AND 5),

    -- Skala B: Autonomie – Inhalt (b1–b3) & Prozess (b4–b6) — R: b2
    b1 SMALLINT CHECK (b1 BETWEEN 1 AND 5),
    b2 SMALLINT CHECK (b2 BETWEEN 1 AND 5),  -- REVERSE
    b3 SMALLINT CHECK (b3 BETWEEN 1 AND 5),
    b4 SMALLINT CHECK (b4 BETWEEN 1 AND 5),
    b5 SMALLINT CHECK (b5 BETWEEN 1 AND 5),
    b6 SMALLINT CHECK (b6 BETWEEN 1 AND 5),

    -- Skala C: Soziale Eingebundenheit (5 Items) — R: c3
    c1 SMALLINT CHECK (c1 BETWEEN 1 AND 5),
    c2 SMALLINT CHECK (c2 BETWEEN 1 AND 5),
    c3 SMALLINT CHECK (c3 BETWEEN 1 AND 5),  -- REVERSE
    c4 SMALLINT CHECK (c4 BETWEEN 1 AND 5),
    c5 SMALLINT CHECK (c5 BETWEEN 1 AND 5),

    -- Skala D: Intrinsische Motivation (5 Items) — R: d3
    d1 SMALLINT CHECK (d1 BETWEEN 1 AND 5),
    d2 SMALLINT CHECK (d2 BETWEEN 1 AND 5),
    d3 SMALLINT CHECK (d3 BETWEEN 1 AND 5),  -- REVERSE
    d4 SMALLINT CHECK (d4 BETWEEN 1 AND 5),
    d5 SMALLINT CHECK (d5 BETWEEN 1 AND 5),

    -- Skala E: Selbstreguliertes Lernen (5 Items) — R: e2
    e1 SMALLINT CHECK (e1 BETWEEN 1 AND 5),
    e2 SMALLINT CHECK (e2 BETWEEN 1 AND 5),  -- REVERSE
    e3 SMALLINT CHECK (e3 BETWEEN 1 AND 5),
    e4 SMALLINT CHECK (e4 BETWEEN 1 AND 5),
    e5 SMALLINT CHECK (e5 BETWEEN 1 AND 5),

    -- Skala F: Wohlbefinden, Kurzform (3 Items) — keine Reverse
    -- f4, f5 bleiben für Rückwärtskompatibilität
    f1 SMALLINT CHECK (f1 BETWEEN 1 AND 5),
    f2 SMALLINT CHECK (f2 BETWEEN 1 AND 5),
    f3 SMALLINT CHECK (f3 BETWEEN 1 AND 5),
    f4 SMALLINT CHECK (f4 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    f5 SMALLINT CHECK (f5 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT

    -- Skala G: Kooperation CRCG (5 Items) — R: g4
    g1 SMALLINT CHECK (g1 BETWEEN 1 AND 5),
    g2 SMALLINT CHECK (g2 BETWEEN 1 AND 5),
    g3 SMALLINT CHECK (g3 BETWEEN 1 AND 5),
    g4 SMALLINT CHECK (g4 BETWEEN 1 AND 5),  -- REVERSE
    g5 SMALLINT CHECK (g5 BETWEEN 1 AND 5),

    -- Skala H: Psychologische Sicherheit (6 Items) — R: h3
    h1 SMALLINT CHECK (h1 BETWEEN 1 AND 5),
    h2 SMALLINT CHECK (h2 BETWEEN 1 AND 5),
    h3 SMALLINT CHECK (h3 BETWEEN 1 AND 5),  -- REVERSE
    h4 SMALLINT CHECK (h4 BETWEEN 1 AND 5),
    h5 SMALLINT CHECK (h5 BETWEEN 1 AND 5),
    h6 SMALLINT CHECK (h6 BETWEEN 1 AND 5),

    -- Skala I: Resilienz (6 Items) — R: i3
    i1 SMALLINT CHECK (i1 BETWEEN 1 AND 5),
    i2 SMALLINT CHECK (i2 BETWEEN 1 AND 5),
    i3 SMALLINT CHECK (i3 BETWEEN 1 AND 5),  -- REVERSE
    i4 SMALLINT CHECK (i4 BETWEEN 1 AND 5),
    i5 SMALLINT CHECK (i5 BETWEEN 1 AND 5),
    i6 SMALLINT CHECK (i6 BETWEEN 1 AND 5),

    -- Skala J: ENTFERNT — Spalten bleiben für Altdaten
    j1 SMALLINT CHECK (j1 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    j2 SMALLINT CHECK (j2 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    j3 SMALLINT CHECK (j3 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    j4 SMALLINT CHECK (j4 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT

    -- Skala K: Flow-Erleben (4 Items) — R: k2
    k1 SMALLINT CHECK (k1 BETWEEN 1 AND 5),
    k2 SMALLINT CHECK (k2 BETWEEN 1 AND 5),  -- REVERSE
    k3 SMALLINT CHECK (k3 BETWEEN 1 AND 5),
    k4 SMALLINT CHECK (k4 BETWEEN 1 AND 5),

    -- Skala L: Naturverbundenheit (5 Items) — R: l2
    l1 SMALLINT CHECK (l1 BETWEEN 1 AND 5),
    l2 SMALLINT CHECK (l2 BETWEEN 1 AND 5),  -- REVERSE
    l3 SMALLINT CHECK (l3 BETWEEN 1 AND 5),
    l4 SMALLINT CHECK (l4 BETWEEN 1 AND 5),
    l5 SMALLINT CHECK (l5 BETWEEN 1 AND 5),

    -- Skala M: Partizipation & Demokratie (6 Items) — R: m3
    m1 SMALLINT CHECK (m1 BETWEEN 1 AND 5),
    m2 SMALLINT CHECK (m2 BETWEEN 1 AND 5),
    m3 SMALLINT CHECK (m3 BETWEEN 1 AND 5),  -- REVERSE
    m4 SMALLINT CHECK (m4 BETWEEN 1 AND 5),
    m5 SMALLINT CHECK (m5 BETWEEN 1 AND 5),
    m6 SMALLINT CHECK (m6 BETWEEN 1 AND 5),

    -- Skala N: Transformation & Irritation (4 Items) — keine Reverse
    n1 SMALLINT CHECK (n1 BETWEEN 1 AND 5),
    n2 SMALLINT CHECK (n2 BETWEEN 1 AND 5),
    n3 SMALLINT CHECK (n3 BETWEEN 1 AND 5),
    n4 SMALLINT CHECK (n4 BETWEEN 1 AND 5),

    -- Skala O: ENTFERNT ab April 2026 — Spalten bleiben für Altdaten
    -- Ersetzt durch offene Fragen F1–F3 (siehe TEXT-Spalten am Ende dieses Blocks)
    o1 SMALLINT CHECK (o1 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    o2 SMALLINT CHECK (o2 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT
    o3 SMALLINT CHECK (o3 BETWEEN 1 AND 5),  -- NICHT MEHR BEFÜLLT

    -- Skala P: Wahrgenommener Stress PSS-4 (4 Items) — R: p2, p3
    p1 SMALLINT CHECK (p1 BETWEEN 1 AND 5),
    p2 SMALLINT CHECK (p2 BETWEEN 1 AND 5),  -- REVERSE
    p3 SMALLINT CHECK (p3 BETWEEN 1 AND 5),  -- REVERSE
    p4 SMALLINT CHECK (p4 BETWEEN 1 AND 5),

    -- Skala Q: Ungewissheitstoleranz UGTS (6 Items) — R: q5, q6
    q1 SMALLINT CHECK (q1 BETWEEN 1 AND 5),
    q2 SMALLINT CHECK (q2 BETWEEN 1 AND 5),
    q3 SMALLINT CHECK (q3 BETWEEN 1 AND 5),
    q4 SMALLINT CHECK (q4 BETWEEN 1 AND 5),
    q5 SMALLINT CHECK (q5 BETWEEN 1 AND 5),  -- REVERSE
    q6 SMALLINT CHECK (q6 BETWEEN 1 AND 5),  -- REVERSE

    -- Skala R: Studienzufriedenheit FB-SZ-K (6 Items) — R: r6
    r1 SMALLINT CHECK (r1 BETWEEN 1 AND 5),
    r2 SMALLINT CHECK (r2 BETWEEN 1 AND 5),
    r3 SMALLINT CHECK (r3 BETWEEN 1 AND 5),
    r4 SMALLINT CHECK (r4 BETWEEN 1 AND 5),
    r5 SMALLINT CHECK (r5 BETWEEN 1 AND 5),
    r6 SMALLINT CHECK (r6 BETWEEN 1 AND 5),  -- REVERSE

    -- Skala S: Wahrgenommener Lernzuwachs Rovai (4 Items) — keine Reverse
    s1 SMALLINT CHECK (s1 BETWEEN 1 AND 5),
    s2 SMALLINT CHECK (s2 BETWEEN 1 AND 5),
    s3 SMALLINT CHECK (s3 BETWEEN 1 AND 5),
    s4 SMALLINT CHECK (s4 BETWEEN 1 AND 5),

    -- Skala T: Autonomieunterstützung LCQ-6 (6 Items) — keine Reverse
    -- t1–t4: Lehrende & Begleitende, t5–t6: Peers
    t1 SMALLINT CHECK (t1 BETWEEN 1 AND 5),
    t2 SMALLINT CHECK (t2 BETWEEN 1 AND 5),
    t3 SMALLINT CHECK (t3 BETWEEN 1 AND 5),
    t4 SMALLINT CHECK (t4 BETWEEN 1 AND 5),
    t5 SMALLINT CHECK (t5 BETWEEN 1 AND 5),
    t6 SMALLINT CHECK (t6 BETWEEN 1 AND 5),

    -- ============================================================
    -- OFFENE FRAGEN F1–F3 (ersetzen Skala O ab April 2026)
    -- Auf Empfehlung von Prof. Dr. Thomas Häcker im Methodengespräch
    -- ============================================================
    offen_wichtigkeit   TEXT,  -- F1: Was ist Ihnen für Ihre eigene Bildung wichtig?
    offen_letzter_monat TEXT,  -- F2: Was haben Sie im letzten Monat ... gelernt? (Wortlaut institutionsspezifisch)
    offen_erleben       TEXT   -- F3: Inwieweit erleben Sie ... das, was Ihnen wichtig ist? (Wortlaut institutionsspezifisch)
);

-- ============================================================
-- ZUSÄTZLICHE SPALTEN-MIGRATION
-- ============================================================
-- Falls die Tabelle bereits aus einer früheren Version existiert (vor
-- April 2026), werden hier die drei neuen TEXT-Spalten additiv ergänzt.
-- Auf einer frischen DB sind sie schon im CREATE TABLE oben enthalten —
-- die ALTER-Statements sind dann No-Ops dank "IF NOT EXISTS".
-- ============================================================
ALTER TABLE public.responses
    ADD COLUMN IF NOT EXISTS offen_wichtigkeit   TEXT,
    ADD COLUMN IF NOT EXISTS offen_letzter_monat TEXT,
    ADD COLUMN IF NOT EXISTS offen_erleben       TEXT;

COMMENT ON COLUMN public.responses.offen_wichtigkeit IS
    'F1: Was ist Ihnen für Ihre eigene Bildung wichtig? (offene Antwort, optional)';
COMMENT ON COLUMN public.responses.offen_letzter_monat IS
    'F2: Was haben Sie im letzten Monat in Ihrer aktuellen Bildungserfahrung gelernt? (offene Antwort, optional, Wortlaut institutionsspezifisch)';
COMMENT ON COLUMN public.responses.offen_erleben IS
    'F3: Inwieweit erleben Sie das, was Ihnen für Ihre Bildung wichtig ist? (offene Antwort, optional, Wortlaut institutionsspezifisch)';

-- ============================================================
-- INDIZES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_responses_code        ON public.responses(anonymous_code);
CREATE INDEX IF NOT EXISTS idx_responses_zeitpunkt   ON public.responses(zeitpunkt);
CREATE INDEX IF NOT EXISTS idx_responses_institution ON public.responses(institution);
CREATE INDEX IF NOT EXISTS idx_responses_created     ON public.responses(created_at DESC);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE public.responses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can submit a response" ON public.responses;
DROP POLICY IF EXISTS "Authenticated users can read all responses" ON public.responses;

-- Jeder darf schreiben (anonymer Fragebogen-Submit via anon-Key)
CREATE POLICY "Anyone can submit a response"
    ON public.responses
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- Nur authentifizierte Nutzer dürfen lesen (Dashboard-Login)
CREATE POLICY "Authenticated users can read all responses"
    ON public.responses
    FOR SELECT
    TO authenticated
    USING (true);

-- UPDATE und DELETE sind bewusst NICHT erlaubt.

-- ============================================================
-- FERTIG – Tabelle "responses" ist bereit.
--
-- Diese Datei ist die einzige kanonische Datenbank-Definition für
-- das Projekt. Bei Schema-Änderungen wird sie aktualisiert und ist
-- nach jedem Run auf einer Supabase-Instanz wieder im Soll-Zustand.
-- ============================================================
