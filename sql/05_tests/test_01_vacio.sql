-- ============================================================================
-- TEST 1: Objeto JSON vacío {}
-- ============================================================================
--
-- Este test verifica que la gramática reconoce correctamente un objeto
-- JSON vacío, que es válido según la especificación.
--
-- Producción esperada: J → { }
-- ============================================================================

-- Encabezado del test
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║                  TEST 1: Objeto Vacío {}                       ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- Información del test
DO $$
BEGIN
    RAISE NOTICE 'Descripción: Verifica que un objeto JSON vacío es válido';
    RAISE NOTICE 'String esperado: {}';
    RAISE NOTICE 'Resultado esperado: TRUE';
    RAISE NOTICE 'Derivación esperada: J ⇒ T_llave_izq T_llave_der ⇒ { }';
    RAISE NOTICE '';
END $$;

-- Ejecutar el test
SELECT cyk('{}');

-- Mostrar la matriz resultante
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'MATRIZ CYK RESULTANTE:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
END $$;

SELECT * FROM mostrar_matriz();

-- Mostrar matriz expandida (vista basada en unnest)
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
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ANÁLISIS DEL RESULTADO:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    -- Verificar resultado
    resultado := cyk('{}');
    simbolo_inicial := obtener_simbolo_inicial();
    x1n := get_xij(1, 2);
    
    RAISE NOTICE 'String: "{}"';
    RAISE NOTICE 'Longitud: 2 tokens';
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE 'X[1,2] contiene: %', 
        CASE 
            WHEN array_length(x1n, 1) > 0 
            THEN '{' || array_to_string(x1n, ', ') || '}'
            ELSE '{}'
        END;
    
    IF resultado THEN
        RAISE NOTICE '';
        RAISE NOTICE '✓✓✓ TEST PASADO ✓✓✓';
        RAISE NOTICE 'El objeto vacío es reconocido correctamente';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✗✗✗ TEST FALLIDO ✗✗✗';
        RAISE NOTICE 'El objeto vacío debería ser aceptado';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Detalles técnicos
DO $$
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'DETALLES TÉCNICOS:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    RAISE NOTICE 'Tokens procesados:';
    RAISE NOTICE '  Posición 1: "{"';
    RAISE NOTICE '  Posición 2: "}"';
    RAISE NOTICE '';
    RAISE NOTICE 'Fila base (longitud 1):';
    RAISE NOTICE '  X[1,1] debe contener: T_llave_izq';
    RAISE NOTICE '  X[2,2] debe contener: T_llave_der';
    RAISE NOTICE '';
    RAISE NOTICE 'Segunda fila (longitud 2):';
    RAISE NOTICE '  X[1,2] debe contener: J';
    RAISE NOTICE '  (usando la producción J → T_llave_izq T_llave_der)';
    RAISE NOTICE '';
END $$;

-- Verificar celdas específicas
DO $$
DECLARE
    x11 TEXT[];
    x22 TEXT[];
    x12 TEXT[];
BEGIN
    x11 := get_xij(1, 1);
    x22 := get_xij(2, 2);
    x12 := get_xij(1, 2);
    
    RAISE NOTICE 'Verificación de celdas:';
    RAISE NOTICE '  X[1,1] = %', array_to_string(x11, ', ');
    RAISE NOTICE '  X[2,2] = %', array_to_string(x22, ', ');
    RAISE NOTICE '  X[1,2] = %', array_to_string(x12, ', ');
    RAISE NOTICE '';
END $$;

-- Separador final
DO $$
BEGIN
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE 'FIN DEL TEST 1';
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;