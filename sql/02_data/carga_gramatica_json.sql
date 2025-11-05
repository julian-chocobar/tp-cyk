-- ============================================================================
-- CARGA DE GRAMÁTICA JSON EN FNC
-- Gramática resultado de la transformación de la Parte 2
-- ============================================================================

SET search_path TO cyk;

-- Limpiar gramática existente (si hay)
DELETE FROM GLC_en_FNC;

-- Reiniciar secuencia del ID
ALTER SEQUENCE GLC_en_FNC_id_seq RESTART WITH 1;

-- ============================================================================
-- PRODUCCIONES BINARIAS (tipo 2: A → BC)
-- ============================================================================

-- Símbolo inicial: J (JSON)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(TRUE, 'J', 'T_llave_izq', 'T_llave_der', 2),    -- J → { }
(FALSE, 'J', 'T_llave_izq', 'Z1', 2);             -- J → { Z1

-- Variables auxiliares para J
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'Z1', 'L', 'T_llave_der', 2);             -- Z1 → L }

-- Lista de pares: L
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'L', 'T_comilla', 'Z2', 2),               -- L → " Z2
(FALSE, 'L', 'P', 'Z5', 2);                       -- L → P Z5

-- Variables auxiliares para L
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'Z2', 'K', 'Z3', 2),                      -- Z2 → K Z3
(FALSE, 'Z3', 'T_comilla', 'Z4', 2),              -- Z3 → " Z4
(FALSE, 'Z4', 'T_dos_puntos', 'V', 2),            -- Z4 → : V
(FALSE, 'Z5', 'T_coma', 'L', 2);                  -- Z5 → , L

-- Par clave:valor: P
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'P', 'T_comilla', 'Z6', 2);               -- P → " Z6

-- Variables auxiliares para P
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'Z6', 'K', 'Z7', 2),                      -- Z6 → K Z7
(FALSE, 'Z7', 'T_comilla', 'Z8', 2),              -- Z7 → " Z8
(FALSE, 'Z8', 'T_dos_puntos', 'V', 2);            -- Z8 → : V

-- Clave: K (recursiva)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'K', 'C', 'K', 2);                        -- K → C K

-- Valor: V (puede ser número, string u objeto)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'V', 'T_apostrofe', 'Z9', 2),             -- V → ' Z9
(FALSE, 'V', 'T_apostrofe', 'T_apostrofe', 2),    -- V → ' '  (string vacío)
(FALSE, 'V', 'T_llave_izq', 'T_llave_der', 2),    -- V → { }  (objeto vacío)
(FALSE, 'V', 'T_llave_izq', 'Z10', 2),            -- V → { Z10 (objeto con contenido)
(FALSE, 'V', 'D', 'N', 2);                        -- V → D N  (número)

-- Variables auxiliares para V
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'Z9', 'S', 'T_apostrofe', 2),             -- Z9 → S '
(FALSE, 'Z10', 'L', 'T_llave_der', 2);            -- Z10 → L }

-- String: S (contenido de strings)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'S', 'C', 'S', 2),                        -- S → C S
(FALSE, 'S', 'T_espacio', 'S', 2);                -- S → espacio S

-- Número: N (recursivo para múltiples dígitos)
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'N', 'D', 'N', 2);                        -- N → D N

-- ============================================================================
-- PRODUCCIONES TERMINALES (tipo 1: A → a)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Símbolos especiales del JSON
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'T_llave_izq', '{', NULL, 1),
(FALSE, 'T_llave_der', '}', NULL, 1),
(FALSE, 'T_comilla', '"', NULL, 1),
(FALSE, 'T_apostrofe', '''', NULL, 1),
(FALSE, 'T_dos_puntos', ':', NULL, 1),
(FALSE, 'T_coma', ',', NULL, 1),
(FALSE, 'T_espacio', ' ', NULL, 1);

-- ----------------------------------------------------------------------------
-- Dígitos: D → 0|1|2|...|9
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'D', '0', NULL, 1),
(FALSE, 'D', '1', NULL, 1),
(FALSE, 'D', '2', NULL, 1),
(FALSE, 'D', '3', NULL, 1),
(FALSE, 'D', '4', NULL, 1),
(FALSE, 'D', '5', NULL, 1),
(FALSE, 'D', '6', NULL, 1),
(FALSE, 'D', '7', NULL, 1),
(FALSE, 'D', '8', NULL, 1),
(FALSE, 'D', '9', NULL, 1);

-- ----------------------------------------------------------------------------
-- N también puede derivar dígitos directamente (caso base)
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'N', '0', NULL, 1),
(FALSE, 'N', '1', NULL, 1),
(FALSE, 'N', '2', NULL, 1),
(FALSE, 'N', '3', NULL, 1),
(FALSE, 'N', '4', NULL, 1),
(FALSE, 'N', '5', NULL, 1),
(FALSE, 'N', '6', NULL, 1),
(FALSE, 'N', '7', NULL, 1),
(FALSE, 'N', '8', NULL, 1),
(FALSE, 'N', '9', NULL, 1);

-- ----------------------------------------------------------------------------
-- Caracteres/Letras: C → a|b|c|...|z
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'C', 'a', NULL, 1),
(FALSE, 'C', 'b', NULL, 1),
(FALSE, 'C', 'c', NULL, 1),
(FALSE, 'C', 'd', NULL, 1),
(FALSE, 'C', 'e', NULL, 1),
(FALSE, 'C', 'f', NULL, 1),
(FALSE, 'C', 'g', NULL, 1),
(FALSE, 'C', 'h', NULL, 1),
(FALSE, 'C', 'i', NULL, 1),
(FALSE, 'C', 'j', NULL, 1),
(FALSE, 'C', 'k', NULL, 1),
(FALSE, 'C', 'l', NULL, 1),
(FALSE, 'C', 'm', NULL, 1),
(FALSE, 'C', 'n', NULL, 1),
(FALSE, 'C', 'o', NULL, 1),
(FALSE, 'C', 'p', NULL, 1),
(FALSE, 'C', 'q', NULL, 1),
(FALSE, 'C', 'r', NULL, 1),
(FALSE, 'C', 's', NULL, 1),
(FALSE, 'C', 't', NULL, 1),
(FALSE, 'C', 'u', NULL, 1),
(FALSE, 'C', 'v', NULL, 1),
(FALSE, 'C', 'w', NULL, 1),
(FALSE, 'C', 'x', NULL, 1),
(FALSE, 'C', 'y', NULL, 1),
(FALSE, 'C', 'z', NULL, 1);

-- ----------------------------------------------------------------------------
-- K también puede derivar caracteres directamente (caso base)
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'K', 'a', NULL, 1),
(FALSE, 'K', 'b', NULL, 1),
(FALSE, 'K', 'c', NULL, 1),
(FALSE, 'K', 'd', NULL, 1),
(FALSE, 'K', 'e', NULL, 1),
(FALSE, 'K', 'f', NULL, 1),
(FALSE, 'K', 'g', NULL, 1),
(FALSE, 'K', 'h', NULL, 1),
(FALSE, 'K', 'i', NULL, 1),
(FALSE, 'K', 'j', NULL, 1),
(FALSE, 'K', 'k', NULL, 1),
(FALSE, 'K', 'l', NULL, 1),
(FALSE, 'K', 'm', NULL, 1),
(FALSE, 'K', 'n', NULL, 1),
(FALSE, 'K', 'o', NULL, 1),
(FALSE, 'K', 'p', NULL, 1),
(FALSE, 'K', 'q', NULL, 1),
(FALSE, 'K', 'r', NULL, 1),
(FALSE, 'K', 's', NULL, 1),
(FALSE, 'K', 't', NULL, 1),
(FALSE, 'K', 'u', NULL, 1),
(FALSE, 'K', 'v', NULL, 1),
(FALSE, 'K', 'w', NULL, 1),
(FALSE, 'K', 'x', NULL, 1),
(FALSE, 'K', 'y', NULL, 1),
(FALSE, 'K', 'z', NULL, 1);

-- ----------------------------------------------------------------------------
-- S también puede derivar caracteres y espacio directamente (caso base)
-- ----------------------------------------------------------------------------

INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(FALSE, 'S', 'a', NULL, 1),
(FALSE, 'S', 'b', NULL, 1),
(FALSE, 'S', 'c', NULL, 1),
(FALSE, 'S', 'd', NULL, 1),
(FALSE, 'S', 'e', NULL, 1),
(FALSE, 'S', 'f', NULL, 1),
(FALSE, 'S', 'g', NULL, 1),
(FALSE, 'S', 'h', NULL, 1),
(FALSE, 'S', 'i', NULL, 1),
(FALSE, 'S', 'j', NULL, 1),
(FALSE, 'S', 'k', NULL, 1),
(FALSE, 'S', 'l', NULL, 1),
(FALSE, 'S', 'm', NULL, 1),
(FALSE, 'S', 'n', NULL, 1),
(FALSE, 'S', 'o', NULL, 1),
(FALSE, 'S', 'p', NULL, 1),
(FALSE, 'S', 'q', NULL, 1),
(FALSE, 'S', 'r', NULL, 1),
(FALSE, 'S', 's', NULL, 1),
(FALSE, 'S', 't', NULL, 1),
(FALSE, 'S', 'u', NULL, 1),
(FALSE, 'S', 'v', NULL, 1),
(FALSE, 'S', 'w', NULL, 1),
(FALSE, 'S', 'x', NULL, 1),
(FALSE, 'S', 'y', NULL, 1),
(FALSE, 'S', 'z', NULL, 1),
(FALSE, 'S', ' ', NULL, 1);

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
DECLARE
    total_producciones INTEGER;
    prod_binarias INTEGER;
    prod_terminales INTEGER;
    simbolo_inicial TEXT;
BEGIN
    SELECT COUNT(*) INTO total_producciones FROM GLC_en_FNC;
    SELECT COUNT(*) INTO prod_binarias FROM GLC_en_FNC WHERE tipo_produccion = 2;
    SELECT COUNT(*) INTO prod_terminales FROM GLC_en_FNC WHERE tipo_produccion = 1;
    SELECT parte_izq INTO simbolo_inicial FROM GLC_en_FNC WHERE start = TRUE;
    
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'GRAMÁTICA CARGADA EXITOSAMENTE';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE 'Total de producciones: %', total_producciones;
    RAISE NOTICE '  • Producciones binarias (A→BC): %', prod_binarias;
    RAISE NOTICE '  • Producciones terminales (A→a): %', prod_terminales;
    RAISE NOTICE '════════════════════════════════════════';
END $$;