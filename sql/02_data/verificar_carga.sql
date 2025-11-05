-- ============================================================================
-- VERIFICACIÓN DE CARGA DE GRAMÁTICA
-- Valida que la gramática se haya cargado correctamente
-- ============================================================================

SET search_path TO cyk;

-- ============================================================================
-- CHECK 1: Existe exactamente un símbolo inicial
-- ============================================================================

DO $$
DECLARE
    count_inicial INTEGER;
    simbolo TEXT;
BEGIN
    SELECT COUNT(*), MAX(parte_izq) INTO count_inicial, simbolo
    FROM GLC_en_FNC
    WHERE start = TRUE;
    
    IF count_inicial = 0 THEN
        RAISE EXCEPTION '✗ ERROR: No se encontró símbolo inicial';
    ELSIF count_inicial > 1 THEN
        RAISE EXCEPTION '✗ ERROR: Hay múltiples símbolos iniciales';
    ELSE
        RAISE NOTICE '✓ Símbolo inicial: %', simbolo;
    END IF;
END $$;

-- ============================================================================
-- CHECK 2: Todas las producciones tipo 1 son correctas (A→a)
-- ============================================================================

DO $$
DECLARE
    errores INTEGER;
BEGIN
    SELECT COUNT(*) INTO errores
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1 AND parte_der2 IS NOT NULL;
    
    IF errores > 0 THEN
        RAISE EXCEPTION '✗ ERROR: % producciones tipo 1 con parte_der2 no NULL', errores;
    ELSE
        RAISE NOTICE '✓ Todas las producciones tipo 1 son válidas';
    END IF;
END $$;

-- ============================================================================
-- CHECK 3: Todas las producciones tipo 2 son correctas (A→BC)
-- ============================================================================

DO $$
DECLARE
    errores INTEGER;
BEGIN
    SELECT COUNT(*) INTO errores
    FROM GLC_en_FNC
    WHERE tipo_produccion = 2 AND parte_der2 IS NULL;
    
    IF errores > 0 THEN
        RAISE EXCEPTION '✗ ERROR: % producciones tipo 2 con parte_der2 NULL', errores;
    ELSE
        RAISE NOTICE '✓ Todas las producciones tipo 2 son válidas';
    END IF;
END $$;

-- ============================================================================
-- CHECK 4: Mostrar estadísticas por variable
-- ============================================================================

DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'ESTADÍSTICAS POR VARIABLE';
    RAISE NOTICE '════════════════════════════════════════';
    
    FOR rec IN 
        SELECT 
            parte_izq,
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE tipo_produccion = 1) AS terminales,
            COUNT(*) FILTER (WHERE tipo_produccion = 2) AS binarias
        FROM GLC_en_FNC
        GROUP BY parte_izq, start
        ORDER BY 
            CASE WHEN start THEN 0 ELSE 1 END,
            parte_izq
    LOOP
        RAISE NOTICE '% : % producciones (% term, % bin)', 
            RPAD(rec.parte_izq, 15), 
            rec.total, 
            rec.terminales, 
            rec.binarias;
    END LOOP;
    
    RAISE NOTICE '════════════════════════════════════════';
END $$;

-- ============================================================================
-- CHECK 5: Verificar variables principales del JSON
-- ============================================================================

DO $$
DECLARE
    vars_esperadas TEXT[] := ARRAY['J', 'L', 'P', 'K', 'V', 'S', 'N', 'D', 'C'];
    var TEXT;
    count_var INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'VERIFICACIÓN DE VARIABLES PRINCIPALES';
    RAISE NOTICE '════════════════════════════════════════';
    
    FOREACH var IN ARRAY vars_esperadas LOOP
        SELECT COUNT(*) INTO count_var
        FROM GLC_en_FNC
        WHERE parte_izq = var;
        
        IF count_var > 0 THEN
            RAISE NOTICE '✓ Variable % : % producciones', var, count_var;
        ELSE
            RAISE WARNING '✗ Variable % no encontrada', var;
        END IF;
    END LOOP;
    
    RAISE NOTICE '════════════════════════════════════════';
END $$;

-- ============================================================================
-- CHECK 6: Verificar terminales especiales del JSON
-- ============================================================================

DO $$
DECLARE
    terminales_especiales TEXT[] := ARRAY['{', '}', '"', '''', ':', ',', ' '];
    term TEXT;
    count_term INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE 'VERIFICACIÓN DE TERMINALES ESPECIALES';
    RAISE NOTICE '════════════════════════════════════════';
    
    FOREACH term IN ARRAY terminales_especiales LOOP
        SELECT COUNT(*) INTO count_term
        FROM GLC_en_FNC
        WHERE tipo_produccion = 1 AND parte_der1 = term;
        
        IF count_term > 0 THEN
            RAISE NOTICE '✓ Terminal "%" : % producciones', term, count_term;
        ELSE
            RAISE WARNING '✗ Terminal "%" no encontrado', term;
        END IF;
    END LOOP;
    
    RAISE NOTICE '════════════════════════════════════════';
END $$;

-- ============================================================================
-- CHECK 7: Verificar que hay producciones para todos los dígitos
-- ============================================================================

DO $$
DECLARE
    count_digitos INTEGER;
BEGIN
    SELECT COUNT(DISTINCT parte_der1) INTO count_digitos
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1 
      AND parte_der1 IN ('0','1','2','3','4','5','6','7','8','9');
    
    RAISE NOTICE '';
    IF count_digitos = 10 THEN
        RAISE NOTICE '✓ Todos los dígitos (0-9) están cubiertos';
    ELSE
        RAISE WARNING '✗ Solo % dígitos encontrados (se esperan 10)', count_digitos;
    END IF;
END $$;

-- ============================================================================
-- CHECK 8: Verificar que hay producciones para letras
-- ============================================================================

DO $$
DECLARE
    count_letras INTEGER;
BEGIN
    SELECT COUNT(DISTINCT parte_der1) INTO count_letras
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1 
      AND parte_der1 ~ '^[a-z]$';
    
    RAISE NOTICE '';
    IF count_letras = 26 THEN
        RAISE NOTICE '✓ Todas las letras (a-z) están cubiertas';
    ELSE
        RAISE WARNING '✗ Solo % letras encontradas (se esperan 26)', count_letras;
    END IF;
END $$;

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE '✓ VERIFICACIÓN COMPLETADA';
    RAISE NOTICE '════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- Mostrar vista de estadísticas
SELECT * FROM estadisticas_gramatica;