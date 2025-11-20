-- ============================================================================
-- FUNCIONES DE UTILIDAD
-- Funciones adicionales para mantenimiento y debugging
-- ============================================================================

-- ============================================================================
-- FUNCIÓN: verificar_gramatica
-- Verifica la integridad de la gramática cargada
-- ============================================================================

CREATE OR REPLACE FUNCTION verificar_gramatica()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check 1: Existe exactamente un símbolo inicial
    RETURN QUERY
    SELECT 
        'Símbolo inicial'::TEXT AS check_name,
        CASE 
            WHEN COUNT(*) = 1 THEN '✓ OK'
            WHEN COUNT(*) = 0 THEN '✗ ERROR'
            ELSE '⚠ WARNING'
        END::TEXT AS status,
        CASE 
            WHEN COUNT(*) = 1 THEN 'Símbolo: ' || MAX(parte_izq)
            WHEN COUNT(*) = 0 THEN 'No se encontró símbolo inicial'
            ELSE 'Múltiples símbolos iniciales: ' || COUNT(*)::TEXT
        END::TEXT AS details
    FROM GLC_en_FNC
    WHERE start = TRUE;
    
    -- Check 2: Producciones tipo 1 bien formadas (A→a, parte_der2 debe ser NULL)
    RETURN QUERY
    SELECT 
        'Producciones tipo 1'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN '✓ OK' ELSE '✗ ERROR' END::TEXT,
        CASE 
            WHEN COUNT(*) = 0 THEN 'Todas correctas'
            ELSE 'Producciones con parte_der2 no NULL: ' || COUNT(*)::TEXT
        END::TEXT
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1 AND parte_der2 IS NOT NULL;
    
    -- Check 3: Producciones tipo 2 bien formadas (A→BC, parte_der2 NO debe ser NULL)
    RETURN QUERY
    SELECT 
        'Producciones tipo 2'::TEXT,
        CASE WHEN COUNT(*) = 0 THEN '✓ OK' ELSE '✗ ERROR' END::TEXT,
        CASE 
            WHEN COUNT(*) = 0 THEN 'Todas correctas'
            ELSE 'Producciones con parte_der2 NULL: ' || COUNT(*)::TEXT
        END::TEXT
    FROM GLC_en_FNC
    WHERE tipo_produccion = 2 AND parte_der2 IS NULL;
    
    -- Check 4: Total de producciones
    RETURN QUERY
    SELECT 
        'Total producciones'::TEXT,
        '✓ INFO'::TEXT,
        COUNT(*)::TEXT || ' producciones'
    FROM GLC_en_FNC;
    
    -- Check 5: Producciones terminales
    RETURN QUERY
    SELECT 
        'Producciones terminales'::TEXT,
        '✓ INFO'::TEXT,
        COUNT(*)::TEXT || ' producciones (A→a)'
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1;
    
    -- Check 6: Producciones binarias
    RETURN QUERY
    SELECT 
        'Producciones binarias'::TEXT,
        '✓ INFO'::TEXT,
        COUNT(*)::TEXT || ' producciones (A→BC)'
    FROM GLC_en_FNC
    WHERE tipo_produccion = 2;
    
    -- Check 7: Variables únicas
    RETURN QUERY
    SELECT 
        'Variables únicas'::TEXT,
        '✓ INFO'::TEXT,
        COUNT(DISTINCT parte_izq)::TEXT || ' variables'
    FROM GLC_en_FNC;
    
    -- Check 8: Terminales únicos
    RETURN QUERY
    SELECT 
        'Terminales únicos'::TEXT,
        '✓ INFO'::TEXT,
        COUNT(DISTINCT parte_der1)::TEXT || ' terminales'
    FROM GLC_en_FNC
    WHERE tipo_produccion = 1;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION verificar_gramatica() IS 
'Verifica la integridad y estructura de la gramática cargada.
Retorna una tabla con el resultado de múltiples validaciones.

Uso:
  SELECT * FROM verificar_gramatica();';

-- ============================================================================
-- FUNCIÓN: exportar_gramatica
-- Exporta la gramática en formato legible
-- ============================================================================

-- Función: Exportar gramática a formato legible
CREATE OR REPLACE FUNCTION exportar_gramatica()
RETURNS TABLE (
    linea TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH gramatica_lines AS (
        SELECT '-- GRAMÁTICA EN FNC PARA JSON'::TEXT AS linea
        UNION ALL
        SELECT '-- Generada automáticamente'::TEXT
        UNION ALL
        SELECT ''::TEXT
        UNION ALL
        SELECT '-- Símbolo inicial: ' || parte_izq
        FROM GLC_en_FNC
        WHERE start = TRUE
        UNION ALL
        SELECT ''::TEXT
        UNION ALL
        SELECT '-- Producciones Binarias (A → BC):'::TEXT
        UNION ALL
        SELECT parte_izq || ' → ' || parte_der1 || ' ' || parte_der2
        FROM GLC_en_FNC
        WHERE tipo_produccion = 2
        UNION ALL
        SELECT ''::TEXT
        UNION ALL
        SELECT '-- Producciones Terminales (A → a):'::TEXT
        UNION ALL
        SELECT parte_izq || ' → ' || parte_der1
        FROM GLC_en_FNC
        WHERE tipo_produccion = 1
    )
    SELECT linea
    FROM gramatica_lines
    ORDER BY 
        CASE 
            WHEN linea LIKE '-- GRAMÁTICA%' THEN 1
            WHEN linea LIKE '-- Generada%' THEN 2
            WHEN linea LIKE '-- Símbolo inicial%' THEN 3
            WHEN linea = '' THEN 4
            WHEN linea LIKE '-- Producciones Binarias%' THEN 5
            WHEN linea LIKE '%→% %' THEN 6  -- Producciones binarias
            WHEN linea LIKE '-- Producciones Terminales%' THEN 7
            WHEN linea LIKE '%→%' AND linea NOT LIKE '% % %' THEN 8  -- Producciones terminales
            ELSE 9
        END,
        linea;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION exportar_gramatica() IS 
'Exporta la gramática en formato de texto legible.

Uso:
  SELECT * FROM exportar_gramatica();
  
Para guardar en archivo:
  \o gramatica_export.txt
  SELECT * FROM exportar_gramatica();
  \o';

-- ============================================================================
-- FUNCIÓN: reiniciar_sistema
-- Limpia los datos de trabajo manteniendo la gramática
-- ============================================================================

CREATE OR REPLACE FUNCTION reiniciar_sistema()
RETURNS VOID AS $$
BEGIN
    PERFORM limpiar_datos();
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'Sistema reiniciado correctamente';
    RAISE NOTICE '  ✓ Matriz CYK limpiada';
    RAISE NOTICE '  ✓ String de entrada limpiado';
    RAISE NOTICE '  ✓ Configuración reseteada';
    RAISE NOTICE '  • Gramática preservada';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reiniciar_sistema() IS 
'Reinicia el sistema limpiando los datos de trabajo pero preservando la gramática.
Útil para ejecutar múltiples tests sin recargar la gramática.

Uso:
  SELECT reiniciar_sistema();';

-- ============================================================================
-- FUNCIÓN: contar_celdas_no_vacias
-- Cuenta cuántas celdas de la matriz tienen variables
-- ============================================================================

CREATE OR REPLACE FUNCTION contar_celdas_no_vacias()
RETURNS TABLE (
    total_celdas INTEGER,
    celdas_vacias INTEGER,
    celdas_no_vacias INTEGER,
    porcentaje_lleno NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER AS total_celdas,
        COUNT(*) FILTER (WHERE x = '{}' OR array_length(x, 1) IS NULL)::INTEGER AS celdas_vacias,
        COUNT(*) FILTER (WHERE x != '{}' AND array_length(x, 1) > 0)::INTEGER AS celdas_no_vacias,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE x != '{}' AND array_length(x, 1) > 0)::NUMERIC / 
            NULLIF(COUNT(*), 0)::NUMERIC,
            2
        ) AS porcentaje_lleno
    FROM matriz_cyk;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION contar_celdas_no_vacias() IS 
'Retorna estadísticas sobre el llenado de la matriz CYK.
Útil para analizar la densidad de la matriz después de una ejecución.

Uso:
  SELECT * FROM contar_celdas_no_vacias();';

-- ============================================================================
-- FUNCIÓN: debug_celda
-- Muestra información detallada de una celda específica
-- ============================================================================

CREATE OR REPLACE FUNCTION debug_celda(celda_i INTEGER, celda_j INTEGER)
RETURNS TABLE (
    propiedad TEXT,
    valor TEXT
) AS $$
DECLARE
    vars TEXT[];
    token_i TEXT;
    token_j TEXT;
    str_completo TEXT;
    substring_val TEXT;
BEGIN
    -- Obtener variables de la celda
    vars := get_xij(celda_i, celda_j);
    
    -- Obtener tokens
    token_i := get_token(celda_i);
    token_j := get_token(celda_j);
    
    -- Obtener string completo
    str_completo := obtener_string_actual();
    
    -- Construir substring
    IF celda_i <= celda_j AND token_i IS NOT NULL AND token_j IS NOT NULL THEN
        substring_val := substring(str_completo FROM celda_i FOR (celda_j - celda_i + 1));
    ELSE
        substring_val := 'N/A';
    END IF;
    
    -- Retornar información
    RETURN QUERY VALUES 
        ('Celda', 'X[' || celda_i || ',' || celda_j || ']'),
        ('Posiciones', celda_i::TEXT || ' a ' || celda_j::TEXT),
        ('Longitud subcadena', (celda_j - celda_i + 1)::TEXT),
        ('Substring', substring_val),
        ('Token inicial', COALESCE(token_i, 'NULL')),
        ('Token final', COALESCE(token_j, 'NULL')),
        ('Variables', 
            CASE 
                WHEN array_length(vars, 1) > 0 
                THEN '{' || array_to_string(vars, ', ') || '}'
                ELSE '{}'
            END),
        ('Cantidad variables', COALESCE(array_length(vars, 1), 0)::TEXT);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION debug_celda(INTEGER, INTEGER) IS 
'Muestra información detallada de una celda específica de la matriz CYK.
Útil para debugging y entender qué subcadena representa cada celda.

Parámetros:
  celda_i: Índice inicial (fila)
  celda_j: Índice final (columna)

Uso:
  SELECT * FROM debug_celda(1, 5);';

-- ============================================================================
-- FUNCIÓN: listar_producciones_variable
-- Lista todas las producciones de una variable específica
-- ============================================================================

CREATE OR REPLACE FUNCTION listar_producciones_variable(variable TEXT)
RETURNS TABLE (
    tipo TEXT,
    produccion TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN tipo_produccion = 1 THEN 'Terminal'
            WHEN tipo_produccion = 2 THEN 'Binaria'
        END::TEXT AS tipo,
        CASE 
            WHEN tipo_produccion = 1 THEN parte_izq || ' → ' || parte_der1
            WHEN tipo_produccion = 2 THEN parte_izq || ' → ' || parte_der1 || ' ' || parte_der2
        END::TEXT AS produccion
    FROM GLC_en_FNC
    WHERE parte_izq = listar_producciones_variable.variable
    ORDER BY tipo_produccion, parte_der1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION listar_producciones_variable(TEXT) IS 
'Lista todas las producciones de una variable específica.

Uso:
  SELECT * FROM listar_producciones_variable(''V'');';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Funciones de utilidad creadas exitosamente:';
    RAISE NOTICE '  ✓ verificar_gramatica()';
    RAISE NOTICE '  ✓ exportar_gramatica()';
    RAISE NOTICE '  ✓ reiniciar_sistema()';
    RAISE NOTICE '  ✓ contar_celdas_no_vacias()';
    RAISE NOTICE '  ✓ debug_celda(i, j)';
    RAISE NOTICE '  ✓ listar_producciones_variable(variable)';
END $$;