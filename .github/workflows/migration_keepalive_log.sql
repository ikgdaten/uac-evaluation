-- ============================================================
-- KEEPALIVE-LOG-TABELLE (Mai 2026)
-- ============================================================
-- Diese kleine Tabelle wird vom GitHub Action Keep-Alive-Workflow
-- alle 2 Tage mit einem INSERT befüllt. Echte Schreib-Aktivität
-- zählt für Supabase eindeutig als "aktiv" — anders als reine
-- Lese-Pings, die seit 2026 oft nicht mehr ausreichen.
--
-- Die Tabelle berührt die "responses"-Tabelle NICHT. Sie kann
-- jederzeit ohne Folgen für die Forschungsdaten gedroppt werden.
--
-- AUSFÜHRUNG:
-- Supabase Dashboard → SQL Editor → "New query"
-- Inhalt einfügen → Run klicken.
-- Diese Datei ist idempotent — Doppelausführung ist unkritisch.
-- ============================================================

-- 1. Tabelle anlegen
CREATE TABLE IF NOT EXISTS public.keepalive_log (
    id        BIGSERIAL PRIMARY KEY,
    pinged_at TIMESTAMPTZ DEFAULT NOW(),
    source    TEXT DEFAULT 'github-action'
);

-- 2. RLS aktivieren
ALTER TABLE public.keepalive_log ENABLE ROW LEVEL SECURITY;

-- 3. Alte Policies aufräumen (falls Datei zweimal läuft)
DROP POLICY IF EXISTS "Allow anon insert on keepalive_log"   ON public.keepalive_log;
DROP POLICY IF EXISTS "Allow authenticated read keepalive"   ON public.keepalive_log;

-- 4. INSERT-Recht für anon + authenticated (Workflow nutzt anon-Key)
CREATE POLICY "Allow anon insert on keepalive_log"
    ON public.keepalive_log
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- 5. SELECT-Recht nur für authenticated (falls man die Pings später anschauen will)
CREATE POLICY "Allow authenticated read keepalive"
    ON public.keepalive_log
    FOR SELECT
    TO authenticated
    USING (true);

-- UPDATE und DELETE bewusst NICHT erlaubt — Tabelle ist append-only.

-- ============================================================
-- VERIFIKATION (optional nach dem Run):
-- SELECT COUNT(*) FROM public.keepalive_log;   -- sollte 0 sein nach Setup
-- ============================================================
