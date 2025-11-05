-- ============================================================================
-- TEST 4: JSON con valor string {"a":'hola'}
-- ============================================================================
--
-- Este test verifica que la gramática maneja correctamente valores de tipo
-- string (entre comillas simples).
--
-- Estructura: { "clave" : 'string' }
-- ============================================================================

SET search_path TO cyk;

-- Encabezado del test
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║         TEST 4: JSON con String {"a":''hola''}                  ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
END $$;

-- Información del test
DO $$
BEGIN
    RAISE NOTICE 'Descripción: JSON con un par clave-valor de tipo string';
    RAISE NOTICE 'String esperado: {"a":''hola''}';
    RAISE NOTICE 'Longitud esperada: 13 tokens';
    RAISE NOTICE 'Resultado esperado: TRUE';
    RAISE NOTICE '';
    RAISE NOTICE 'Elementos del string:';
    RAISE NOTICE '  • Clave: "a"';
    RAISE NOTICE '  • Valor: ''hola'' (string de 4 caracteres)';
    RAISE NOTICE '';
    RAISE NOTICE 'Producciones clave:';
    RAISE NOTICE '  • V → T_apostrofe Z9  (inicio de string)';
    RAISE NOTICE '  • Z9 → S T_apostrofe  (contenido + cierre)';
    RAISE NOTICE '  • S → C S  (construcción recursiva del string)';
    RAISE NOTICE '';
END $$;

-- Ejecutar el test
SELECT cyk('{"a":''hola''}');

-- Mostrar matriz compacta
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'MATRIZ CYK (compacta):';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
END $$;

SELECT * FROM mostrar_matriz_compacta();

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
    
    resultado := cyk('{"a":''hola''}');
    simbolo_inicial := obtener_simbolo_inicial();
    n := obtener_longitud_string();
    x1n := get_xij(1, n);
    
    RAISE NOTICE 'String: {"a":''hola''}';
    RAISE NOTICE 'Longitud: % tokens', n;
    RAISE NOTICE 'Símbolo inicial: %', simbolo_inicial;
    RAISE NOTICE 'X[1,%] = %', 
        n,
        CASE 
            WHEN array_length(x1n, 1) > 0 
            THEN '{' || array_to_string(x1n, ', ') || '}'
            ELSE '{}'
        END;
    
    IF resultado THEN
        RAISE NOTICE '';
        RAISE NOTICE '✓✓✓ TEST PASADO ✓✓✓';
        RAISE NOTICE 'El JSON con string es reconocido correctamente';
        RAISE NOTICE '';
        RAISE NOTICE 'Este test valida:';
        RAISE NOTICE '  ✓ Valores de tipo string';
        RAISE NOTICE '  ✓ Construcción recursiva de strings (S → C S)';
        RAISE NOTICE '  ✓ Múltiples caracteres en un string';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✗✗✗ TEST FALLIDO ✗✗✗';
        RAISE NOTICE 'El JSON con string debería ser aceptado';
    END IF;
    
    RAISE NOTICE '';
END $$;

-- Análisis del contenido del string
DO $$
DECLARE
    x_h TEXT[];    -- 'h'
    x_ho TEXT[];   -- 'ho'
    x_hol TEXT[];  -- 'hol'
    x_hola TEXT[]; -- 'hola' (sin las comillas)
    x_string_completo TEXT[]; -- 'hola' (con comillas)
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ANÁLISIS DEL STRING "hola":';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    
    -- Analizar construcción progresiva del string
    -- Asumiendo posiciones: ' h o l a ' están en 6-11
    
    x_h := get_xij(7, 7);
    RAISE NOTICE 'Carácter ''h'' (pos 7):';
    RAISE NOTICE '  X[7,7] = %', array_to_string(x_h, ', ');
    RAISE NOTICE '  Debe contener: C, S, K';
    RAISE NOTICE '';
    
    x_ho := get_xij(7, 8);
    RAISE NOTICE 'Subcadena ''ho'' (pos 7-8):';
    RAISE NOTICE '  X[7,8] = %', 
        CASE 
            WHEN array_length(x_ho, 1) > 0 
            THEN '{' || array_to_string(x_ho, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: S (por S → C S)';
    RAISE NOTICE '';
    
    x_hola := get_xij(7, 10);
    RAISE NOTICE 'Contenido ''hola'' (pos 7-10):';
    RAISE NOTICE '  X[7,10] = %', 
        CASE 
            WHEN array_length(x_hola, 1) > 0 
            THEN '{' || array_to_string(x_hola, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: S';
    RAISE NOTICE '';
    
    x_string_completo := get_xij(6, 11);
    RAISE NOTICE 'String completo ''hola'' (pos 6-11):';
    RAISE NOTICE '  X[6,11] = %', 
        CASE 
            WHEN array_length(x_string_completo, 1) > 0 
            THEN '{' || array_to_string(x_string_completo, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '  Debe contener: V (valor)';
    RAISE NOTICE '';
END $$;

-- Mostrar tokens
DO $$
DECLARE
    i INTEGER;
    token TEXT;
    descripcion TEXT;
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'TOKENS PROCESADOS:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    FOR i IN 1..obtener_longitud_string() LOOP
        token := get_token(i);
        
        -- Agregar descripción
        descripcion := CASE token
            WHEN '{' THEN 'apertura objeto'
            WHEN '}' THEN 'cierre objeto'
            WHEN '"' THEN 'comilla doble'
            WHEN '''' THEN 'comilla simple'
            WHEN ':' THEN 'dos puntos'
            WHEN ',' THEN 'coma'
            ELSE 'carácter: ' || token
        END;
        
        RAISE NOTICE '  [%]: "%" - %', LPAD(i::TEXT, 2, '0'), token, descripcion;
    END LOOP;
    
    RAISE NOTICE '';
END $$;

-- Debug de celdas clave
DO $$
BEGIN
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'DEBUG DE CELDAS IMPORTANTES:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
END $$;

-- Debug celda del valor string
SELECT * FROM debug_celda(6, 11);

DO $$
BEGIN
    RAISE NOTICE '';
END $$;

-- Debug celda del par completo
SELECT * FROM debug_celda(2, 11);

-- Estadísticas
DO $$
DECLARE
    stats RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'ESTADÍSTICAS:';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    SELECT * INTO stats FROM contar_celdas_no_vacias();
    
    RAISE NOTICE 'Total de celdas: %', stats.total_celdas;
    RAISE NOTICE 'Celdas con variables: %', stats.celdas_no_vacias;
    RAISE NOTICE 'Porcentaje de llenado: %%%', stats.porcentaje_lleno;
    RAISE NOTICE '';
    
    RAISE NOTICE 'Nota: Porcentaje alto indica que la gramática está generando';
    RAISE NOTICE '      muchas variables intermedias (característica de FNC)';
    RAISE NOTICE '';
END $$;

-- Separador final
DO $$
BEGIN
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE 'FIN DEL TEST 4';
    RAISE NOTICE '═════════════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;