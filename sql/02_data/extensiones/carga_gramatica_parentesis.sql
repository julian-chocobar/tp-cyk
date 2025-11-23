-- ============================================================================
-- CARGA DE GRAMÁTICA PARA PARÉNTESIS BALANCEADOS EN FNC
-- ============================================================================
--
-- Esta gramática permite parsear strings de paréntesis balanceados.
-- Ejemplos válidos: (), ()(), (()()), ((()))
-- Ejemplos inválidos: )(, ((), ())
--
-- Gramática original: S → S S | (S) | ()
-- Símbolo inicial: S
-- ============================================================================

-- Limpiar gramática anterior
DELETE FROM GLC_en_FNC;

-- ============================================================================
-- PRODUCCIONES BINARIAS (A → BC)
-- ============================================================================

-- S → S S (concatenación de dos strings balanceados)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(true, 'S', 'S', 'S', 2);

-- S → T_lp Z1 (paréntesis con contenido: (S))
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false, 'S', 'T_lp', 'Z1', 2);

-- Z1 → S T_rp (completa el paréntesis con contenido)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false, 'Z1', 'S', 'T_rp', 2);

-- S → T_lp T_rp (paréntesis vacío: ())
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false, 'S', 'T_lp', 'T_rp', 2);

-- ============================================================================
-- PRODUCCIONES TERMINALES (A → a)
-- ============================================================================

-- Variables terminales para paréntesis
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false, 'T_lp', '(', NULL, 1), 
(false, 'T_rp', ')', NULL, 1);

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
DECLARE
    total_prods INTEGER;
    simbolo_inicial TEXT;
BEGIN
    SELECT COUNT(*) INTO total_prods FROM GLC_en_FNC;
    SELECT parte_izq INTO simbolo_inicial FROM GLC_en_FNC WHERE start = TRUE LIMIT 1;
    
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║   ✓ GRAMÁTICA PARÉNTESIS BALANCEADOS CARGADA EXITOSAMENTE     ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'Total de producciones: %', total_prods;
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE '';
    RAISE NOTICE 'Ejemplos de uso:';
    RAISE NOTICE '  SELECT cyk(''()'');';
    RAISE NOTICE '  SELECT cyk(''()()'');';
    RAISE NOTICE '  SELECT cyk(''(()())'');';
    RAISE NOTICE '  SELECT cyk('')('');  -- Debe dar FALSE';
    RAISE NOTICE '';
END $$;

