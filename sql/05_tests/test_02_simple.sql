-- ============================================================================
-- TEST 2: JSON simple con un par clave-valor {"a":10}
-- ============================================================================
--
-- Este test verifica que la gramática reconoce un objeto JSON básico
-- con un único par clave-valor numérico.
--
-- Estructura: { "clave" : valor_numérico }
-- ============================================================================

SET search_path TO cyk;

-- Encabezado del test
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║            TEST 2: JSON Simple {"a":10}                        ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- Información del test
DO $$
BEGIN
    RAISE NOTICE 'Descripción: JSON con un par clave-valor numérico';
    RAISE NOTICE 'String esperado: {"a":10}';
    RAISE NOTICE 'Longitud: 9 tokens';
    RAISE NOTICE 'Resultado esperado: TRUE';
    RAISE NOTICE '';
    RAISE NOTICE 'Estructura esperada:';
    RAISE NOTICE '  { : T_llave_izq';
    RAISE NOTICE '  " : T_comilla';
    RAISE NOTICE '  a : K (clave)';
    RAISE NOTICE '  " : T_comilla';
    RAISE NOTICE '  : : T_dos_puntos';
    RAISE NOTICE '  1 : D (dígito)';
    RAISE NOTICE '  0 : D (dígito)';
    RAISE NOTICE '  } : T_llave_der';
    RAISE NOTICE '';
END $$;

-- Ejecutar el test
SELECT cyk('{"a":10}');

-- Mostrar la matriz resultante
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'MATRIZ CYK RESULTANTE:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
END $$;

SELECT * FROM mostrar_matriz();

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'MATRIZ EXPANDIDA (vista matriz_expandida):';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
END $$;

SELECT i, j, variable
FROM matriz_expandida
ORDER BY i, j, variable;

-- Análisis del resultado
DO $$
DECLARE
    resultado BOOLEAN;
    x1n TEXT[];
    simbolo_inicial TEXT;
    n INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ANÁLISIS DEL RESULTADO:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    -- Verificar resultado
    resultado := cyk('{"a":10}');
    simbolo_inicial := obtener_simbolo_inicial();
    n := obtener_longitud_string();
    x1n := get_xij(1, n);
    
    RAISE NOTICE 'String: {"a":10}';
    RAISE NOTICE 'Longitud: % tokens', n;
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE 'X[1,%] contiene: %', 
        n,
        CASE 
            WHEN array_length(x1n, 1) > 0 
            THEN '{' || array_to_string(x1n, ', ') || '}'
            ELSE '{}'
        END;
    
    IF resultado THEN
        RAISE NOTICE '';
        RAISE NOTICE '✓✓✓ TEST PASADO ✓✓✓';
        RAISE NOTICE 'El JSON simple es reconocido correctamente';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✗✗✗ TEST FALLIDO ✗✗✗';
        RAISE NOTICE 'El JSON simple debería ser aceptado';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Análisis de subcadenas importantes
DO $$
DECLARE
    x_clave TEXT[];  -- "a"
    x_valor TEXT[];  -- 10
    x_par TEXT[];    -- "a":10
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ANÁLISIS DE SUBCADENAS:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    
    -- Analizar la clave "a" (posiciones 2-4)
    x_clave := get_xij(2, 4);
    RAISE NOTICE 'Clave "a" (posiciones 2-4):';
    RAISE NOTICE '  X[2,4] = %', 
        CASE 
            WHEN array_length(x_clave, 1) > 0 
            THEN '{' || array_to_string(x_clave, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debería contener producciones relacionadas con K (clave)';
    RAISE NOTICE '';
    
    -- Analizar el valor 10 (posiciones 6-7)
    x_valor := get_xij(6, 7);
    RAISE NOTICE 'Valor 10 (posiciones 6-7):';
    RAISE NOTICE '  X[6,7] = %', 
        CASE 
            WHEN array_length(x_valor, 1) > 0 
            THEN '{' || array_to_string(x_valor, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debería contener N (número)';
    RAISE NOTICE '';
    
    -- Analizar el par completo "a":10 (posiciones 2-7)
    x_par := get_xij(2, 7);
    RAISE NOTICE 'Par "a":10 (posiciones 2-7):';
    RAISE NOTICE '  X[2,7] = %', 
        CASE 
            WHEN array_length(x_par, 1) > 0 
            THEN '{' || array_to_string(x_par, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debería contener P (par) y L (lista)';
    RAISE NOTICE '';
END $$;

-- Verificar tokens
DO $$
DECLARE
    i INTEGER;
    token TEXT;
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'TOKENS PROCESADOS:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    FOR i IN 1..obtener_longitud_string() LOOP
        token := get_token(i);
        RAISE NOTICE 'Posición %: "%"', i, token;
    END LOOP;
    
    RAISE NOTICE '';
END $$;

-- Estadísticas de la matriz
SELECT * FROM contar_celdas_no_vacias();

-- Separador final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE 'FIN DEL TEST 2';
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;