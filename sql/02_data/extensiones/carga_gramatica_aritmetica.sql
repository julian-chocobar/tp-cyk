-- ============================================================================
-- CARGA DE GRAMÁTICA PARA OPERACIONES ARITMÉTICAS EN FNC
-- ============================================================================
--
-- Esta gramática permite parsear expresiones aritméticas simples con:
-- - Suma (+), resta (-), multiplicación (*), división (/)
-- - Paréntesis para agrupar expresiones
-- - Negación unaria (-)
-- - Números enteros (múltiples dígitos)
--
-- Símbolo inicial: S
-- ============================================================================

-- Limpiar gramática anterior
DELETE FROM GLC_en_FNC;

-- ============================================================================
-- S (símbolo inicial)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(true,'S','E','Z1',2),
(false,'Z1','T_suma','T',2),

(false,'S','E','Z2',2),
(false,'Z2','T_resta','T',2),

(false,'S','T','Z3',2),
(false,'Z3','T_mul','P',2),

(false,'S','T','Z4',2),
(false,'Z4','T_div','P',2),

(false,'S','T_lp','Z5',2),
(false,'Z5','E','T_rp',2),

(false,'S','T_resta','P',2),
(false,'S','N','D',2),

-- S → 0, 1, ..., 9 (terminales directos)
(false,'S','0',NULL,1),
(false,'S','1',NULL,1),
(false,'S','2',NULL,1),
(false,'S','3',NULL,1),
(false,'S','4',NULL,1),
(false,'S','5',NULL,1),
(false,'S','6',NULL,1),
(false,'S','7',NULL,1),
(false,'S','8',NULL,1),
(false,'S','9',NULL,1);

-- ============================================================================
-- E (Expresión)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false,'E','E','Z6',2),
(false,'Z6','T_suma','T',2),

(false,'E','E','Z7',2),
(false,'Z7','T_resta','T',2),

(false,'E','T','Z8',2),
(false,'Z8','T_mul','P',2),

(false,'E','T','Z9',2),
(false,'Z9','T_div','P',2),

(false,'E','T_lp','Z10',2),
(false,'Z10','E','T_rp',2),

(false,'E','T_resta','P',2),
(false,'E','N','D',2),

-- E → 0, 1, ..., 9 (terminales directos)
(false,'E','0',NULL,1),
(false,'E','1',NULL,1),
(false,'E','2',NULL,1),
(false,'E','3',NULL,1),
(false,'E','4',NULL,1),
(false,'E','5',NULL,1),
(false,'E','6',NULL,1),
(false,'E','7',NULL,1),
(false,'E','8',NULL,1),
(false,'E','9',NULL,1);

-- ============================================================================
-- T (Término)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false,'T','T','Z11',2),
(false,'Z11','T_mul','P',2),

(false,'T','T','Z12',2),
(false,'Z12','T_div','P',2),

(false,'T','T_lp','Z13',2),
(false,'Z13','E','T_rp',2),

(false,'T','T_resta','P',2),
(false,'T','N','D',2),

-- T → 0, 1, ..., 9 (terminales directos)
(false,'T','0',NULL,1),
(false,'T','1',NULL,1),
(false,'T','2',NULL,1),
(false,'T','3',NULL,1),
(false,'T','4',NULL,1),
(false,'T','5',NULL,1),
(false,'T','6',NULL,1),
(false,'T','7',NULL,1),
(false,'T','8',NULL,1),
(false,'T','9',NULL,1);

-- ============================================================================
-- P (Primario)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false,'P','T_lp','Z14',2),
(false,'Z14','E','T_rp',2),

(false,'P','T_resta','P',2),
(false,'P','N','D',2),

-- P → 0, 1, ..., 9 (terminales directos)
(false,'P','0',NULL,1),
(false,'P','1',NULL,1),
(false,'P','2',NULL,1),
(false,'P','3',NULL,1),
(false,'P','4',NULL,1),
(false,'P','5',NULL,1),
(false,'P','6',NULL,1),
(false,'P','7',NULL,1),
(false,'P','8',NULL,1),
(false,'P','9',NULL,1);

-- ============================================================================
-- N (Número)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(false,'N','N','D',2),

-- N → 0, 1, ..., 9 (terminales directos)
(false,'N','0',NULL,1),
(false,'N','1',NULL,1),
(false,'N','2',NULL,1),
(false,'N','3',NULL,1),
(false,'N','4',NULL,1),
(false,'N','5',NULL,1),
(false,'N','6',NULL,1),
(false,'N','7',NULL,1),
(false,'N','8',NULL,1),
(false,'N','9',NULL,1);

-- ============================================================================
-- D (Dígito)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
-- D → 0, 1, ..., 9 (terminales directos)
(false,'D','0',NULL,1),
(false,'D','1',NULL,1),
(false,'D','2',NULL,1),
(false,'D','3',NULL,1),
(false,'D','4',NULL,1),
(false,'D','5',NULL,1),
(false,'D','6',NULL,1),
(false,'D','7',NULL,1),
(false,'D','8',NULL,1),
(false,'D','9',NULL,1);

-- ============================================================================
-- TERMINALES (Variables terminales)
-- ============================================================================
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
-- Operadores
(false,'T_suma','+',NULL,1),
(false,'T_resta','-',NULL,1),
(false,'T_mul','*',NULL,1),
(false,'T_div','/',NULL,1),
(false,'T_lp','(',NULL,1),
(false,'T_rp',')',NULL,1),

-- Dígitos
(false,'T_0','0',NULL,1),
(false,'T_1','1',NULL,1),
(false,'T_2','2',NULL,1),
(false,'T_3','3',NULL,1),
(false,'T_4','4',NULL,1),
(false,'T_5','5',NULL,1),
(false,'T_6','6',NULL,1),
(false,'T_7','7',NULL,1), 
(false,'T_8','8',NULL,1),
(false,'T_9','9',NULL,1);

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
    RAISE NOTICE '║     ✓ GRAMÁTICA ARITMÉTICA CARGADA EXITOSAMENTE                ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'Total de producciones: %', total_prods;
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE '';
    RAISE NOTICE 'Ejemplos de uso:';
    RAISE NOTICE '  SELECT cyk(''1+2'');';
    RAISE NOTICE '  SELECT cyk(''9*(4-1)'');';
    RAISE NOTICE '  SELECT cyk(''-5+3'');';
    RAISE NOTICE '';
END $$;

