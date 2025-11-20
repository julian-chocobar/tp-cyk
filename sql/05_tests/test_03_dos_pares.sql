-- ============================================================================
-- TEST 3: JSON con dos pares clave-valor {"a":10,"b":99}
-- ============================================================================
--
-- Este test verifica que la gramática maneja correctamente múltiples pares
-- separados por comas.
--
-- Estructura: { "clave1" : valor1 , "clave2" : valor2 }
-- ============================================================================

-- Encabezado del test
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║         TEST 3: JSON con Dos Pares {"a":10,"b":99}            ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- Información del test
DO $$
BEGIN
    RAISE NOTICE 'Descripción: JSON con dos pares clave-valor separados por coma';
    RAISE NOTICE 'String esperado: {"a":10,"b":99}';
    RAISE NOTICE 'Longitud: 16 tokens';
    RAISE NOTICE 'Resultado esperado: TRUE';
    RAISE NOTICE '';
    RAISE NOTICE 'Elementos clave:';
    RAISE NOTICE '  • Primer par: "a":10';
    RAISE NOTICE '  • Separador: ,';
    RAISE NOTICE '  • Segundo par: "b":99';
    RAISE NOTICE '';
    RAISE NOTICE 'Producciones importantes:';
    RAISE NOTICE '  • L → P Z5  (lista con primer par)';
    RAISE NOTICE '  • Z5 → T_coma L  (coma + resto de lista)';
    RAISE NOTICE '';
END $$;

-- Ejecutar el test
SELECT cyk('{"a":10,"b":99}');

-- Mostrar la matriz resultante (versión compacta para no saturar output)
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'MATRIZ CYK RESULTANTE (compacta):';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
END $$;

SELECT * FROM mostrar_matriz_compacta();

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
    resultado := cyk('{"a":10,"b":99}');
    simbolo_inicial := obtener_simbolo_inicial();
    n := obtener_longitud_string();
    x1n := get_xij(1, n);
    
    RAISE NOTICE 'String: {"a":10,"b":99}';
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
        RAISE NOTICE 'El JSON con dos pares es reconocido correctamente';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✗✗✗ TEST FALLIDO ✗✗✗';
        RAISE NOTICE 'El JSON con dos pares debería ser aceptado';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Análisis de componentes
DO $$
DECLARE
    x_par1 TEXT[];    -- "a":10
    x_coma TEXT[];    -- ,
    x_par2 TEXT[];    -- "b":99
    x_lista TEXT[];   -- lista completa
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ANÁLISIS DE COMPONENTES:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    
    -- Primer par "a":10 (posiciones aproximadas 2-7)
    x_par1 := get_xij(2, 7);
    RAISE NOTICE 'Primer par "a":10:';
    RAISE NOTICE '  X[2,7] = %', 
        CASE 
            WHEN array_length(x_par1, 1) > 0 
            THEN '{' || array_to_string(x_par1, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: P (par) y posiblemente L (lista de un elemento)';
    RAISE NOTICE '';
    
    -- Coma (posición 8)
    x_coma := get_xij(8, 8);
    RAISE NOTICE 'Coma separadora:';
    RAISE NOTICE '  X[8,8] = %', 
        CASE 
            WHEN array_length(x_coma, 1) > 0 
            THEN '{' || array_to_string(x_coma, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: T_coma';
    RAISE NOTICE '';
    
    -- Segundo par "b":99 (posiciones aproximadas 9-14)
    x_par2 := get_xij(9, 14);
    RAISE NOTICE 'Segundo par "b":99:';
    RAISE NOTICE '  X[9,14] = %', 
        CASE 
            WHEN array_length(x_par2, 1) > 0 
            THEN '{' || array_to_string(x_par2, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: P (par) y L (lista)';
    RAISE NOTICE '';
    
    -- Lista completa (posiciones 2-14)
    x_lista := get_xij(2, 14);
    RAISE NOTICE 'Lista completa "a":10,"b":99:';
    RAISE NOTICE '  X[2,14] = %', 
        CASE 
            WHEN array_length(x_lista, 1) > 0 
            THEN '{' || array_to_string(x_lista, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: L (lista)';
    RAISE NOTICE '';
END $$;

-- Mostrar tokens para referencia
DO $$
DECLARE
    tokens_array TEXT[];
    i INTEGER;
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'TOKENS DEL STRING:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    tokens_array := ARRAY(
        SELECT token FROM string_input ORDER BY posicion
    );
    
    RAISE NOTICE 'Tokens: %', array_to_string(tokens_array, ' | ');
    RAISE NOTICE '';
    
    IF array_length(tokens_array, 1) IS NOT NULL THEN
    FOR i IN 1..array_length(tokens_array, 1) LOOP
        RAISE NOTICE '  [%]: %', LPAD(i::TEXT, 2, '0'), tokens_array[i];
    END LOOP;

END IF;

    RAISE NOTICE '';
END $$;

-- Estadísticas
DO $$
DECLARE
    stats RECORD;
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ESTADÍSTICAS DE LA MATRIZ:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    SELECT * INTO stats FROM contar_celdas_no_vacias();
    
    RAISE NOTICE 'Total de celdas: %', stats.total_celdas;
    RAISE NOTICE 'Celdas vacías: %', stats.celdas_vacias;
    RAISE NOTICE 'Celdas con variables: %', stats.celdas_no_vacias;
    RAISE NOTICE 'Porcentaje de llenado: %%%', stats.porcentaje_lleno;
    RAISE NOTICE '';
END $$;

-- Separador final
DO $$
BEGIN
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE 'FIN DEL TEST 3';
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;