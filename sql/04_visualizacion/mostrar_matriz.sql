-- ============================================================================
-- VISUALIZACIÓN DE MATRIZ CYK
-- Función para mostrar la matriz triangular de forma visual
-- ============================================================================

SET search_path TO cyk;

-- ============================================================================
-- FUNCIÓN: mostrar_matriz
-- Muestra la matriz CYK en formato triangular visual
-- ============================================================================

CREATE OR REPLACE FUNCTION mostrar_matriz()
RETURNS TABLE (
    fila TEXT
) AS $$
DECLARE
    n INTEGER;
    i_idx INTEGER;
    j_idx INTEGER;
    linea TEXT;
    celda TEXT;
    vars TEXT[];
    max_width INTEGER := 12;  -- Ancho máximo de cada celda
    str_actual TEXT;
    tokens_str TEXT;
    celdas_llenas INTEGER;
    offset_idx INTEGER;
BEGIN
    -- Obtener longitud
    n := obtener_longitud_string();
    str_actual := obtener_string_actual();
    
    IF n = 0 THEN
        RETURN QUERY SELECT 'Matriz vacía (no hay string procesado)'::TEXT;
        RETURN;
    END IF;
    
    -- ========================================================================
    -- ENCABEZADO
    -- ========================================================================
    RETURN QUERY SELECT ''::TEXT;
    RETURN QUERY SELECT '╔════════════════════════════════════════════════════════════════╗'::TEXT;
    RETURN QUERY SELECT '║                    MATRIZ CYK TRIANGULAR                       ║'::TEXT;
    RETURN QUERY SELECT '╚════════════════════════════════════════════════════════════════╝'::TEXT;
    RETURN QUERY SELECT ''::TEXT;
    
    -- Mostrar string original
    RETURN QUERY SELECT ('String: "' || str_actual || '"')::TEXT;
    RETURN QUERY SELECT ('Longitud: ' || n || ' tokens')::TEXT;
    RETURN QUERY SELECT ''::TEXT;
    
    -- ========================================================================
    -- MOSTRAR TOKENS
    -- ========================================================================
    tokens_str := 'Tokens: ';
    FOR i IN 1..n LOOP
        SELECT token INTO celda FROM string_input WHERE posicion = i;
        tokens_str := tokens_str || '[' || COALESCE(celda, '?') || '] ';
    END LOOP;
    RETURN QUERY SELECT tokens_str::TEXT;
    RETURN QUERY SELECT REPEAT('─', 64)::TEXT;
    RETURN QUERY SELECT ''::TEXT;
    
    -- ========================================================================
    -- MOSTRAR MATRIZ (de abajo hacia arriba, como en clase)
    -- ========================================================================
    
    -- Fila por fila, de abajo (i=n) hacia arriba (i=1)
    FOR offset_idx IN 0..(n - 1) LOOP
        i_idx := n - offset_idx;
        linea := '';
        
        -- Agregar espacios iniciales para formar el triángulo
        FOR j_idx IN 1..(i_idx - 1) LOOP
            linea := linea || REPEAT(' ', max_width + 2);
        END LOOP;
        
        -- Agregar celdas de esta fila (desde j=i hasta j=n)
        FOR j_idx IN i_idx..n LOOP
            -- Obtener variables de la celda actual
            SELECT x INTO vars FROM matriz_cyk WHERE matriz_cyk.i = i_idx AND matriz_cyk.j = j_idx;
            
            -- Formatear contenido de la celda
            IF vars IS NULL OR array_length(vars, 1) IS NULL THEN
                celda := '{}';
            ELSE
                celda := array_to_string(vars, ',');
                -- Truncar si es muy largo
                IF length(celda) > max_width THEN
                    celda := substring(celda FROM 1 FOR max_width - 2) || '..';
                END IF;
            END IF;
            
            -- Agregar celda formateada
            linea := linea || '[' || RPAD(celda, max_width) || '] ';
        END LOOP;
        
        -- Agregar etiqueta de fila al final
        linea := linea || '  ← fila ' || i_idx;
        
        RETURN QUERY SELECT linea::TEXT;
    END LOOP;
    
    RETURN QUERY SELECT ''::TEXT;
    
    -- ========================================================================
    -- ETIQUETAS DE COLUMNAS
    -- ========================================================================
    linea := '';
    FOR j_idx IN 1..n LOOP
        linea := linea || REPEAT(' ', (j_idx-1) * (max_width + 3));
        linea := linea || '    col ' || j_idx;
        EXIT; -- Solo mostrar para la primera columna (como referencia)
    END LOOP;
    RETURN QUERY SELECT linea::TEXT;
    RETURN QUERY SELECT ''::TEXT;
    
    -- ========================================================================
    -- INFORMACIÓN ADICIONAL
    -- ========================================================================
    RETURN QUERY SELECT REPEAT('─', 64)::TEXT;
    RETURN QUERY SELECT 'Información:'::TEXT;
    RETURN QUERY SELECT ('  • Total de celdas: ' || (n * (n + 1) / 2))::TEXT;
    
    -- Contar celdas no vacías
    SELECT COUNT(*) INTO celdas_llenas
    FROM matriz_cyk
    WHERE x IS NOT NULL AND array_length(x, 1) > 0;
    
    RETURN QUERY SELECT ('  • Celdas con variables: ' || celdas_llenas)::TEXT;
    
    -- Mostrar celda final (resultado)
    SELECT x INTO vars FROM matriz_cyk WHERE matriz_cyk.i = 1 AND matriz_cyk.j = n;
    IF vars IS NOT NULL AND array_length(vars, 1) > 0 THEN
        RETURN QUERY SELECT ('  • X[1,' || n || '] = {' || array_to_string(vars, ', ') || '}')::TEXT;
    ELSE
        RETURN QUERY SELECT ('  • X[1,' || n || '] = {}')::TEXT;
    END IF;
    
    RETURN QUERY SELECT ''::TEXT;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mostrar_matriz() IS 
'Muestra la matriz CYK en formato triangular visual, similar a como se ve en clase.
La matriz se muestra con la fila base (diagonal) abajo y la celda final arriba.

Formato:
                                    [X15]           ← Celda final (resultado)
                          [X14]     [X25]
                [X13]     [X24]     [X35]
      [X12]     [X23]     [X34]     [X45]
[X11] [X22]     [X33]     [X44]     [X55]  ← Fila base

Cada celda muestra las variables que derivan esa subcadena.

Uso:
  SELECT * FROM mostrar_matriz();
  
Para guardar en archivo:
  \o matriz_resultado.txt
  SELECT * FROM mostrar_matriz();
  \o';

-- ============================================================================
-- FUNCIÓN: mostrar_matriz_compacta
-- Versión compacta de la matriz (solo muestra cantidad de variables)
-- ============================================================================

CREATE OR REPLACE FUNCTION mostrar_matriz_compacta()
RETURNS TABLE (
    fila TEXT
) AS $$
DECLARE
    n INTEGER;
    i_idx INTEGER;
    j_idx INTEGER;
    linea TEXT;
    vars TEXT[];
    count_vars INTEGER;
    offset_idx INTEGER;
BEGIN
    n := obtener_longitud_string();
    
    IF n = 0 THEN
        RETURN QUERY SELECT 'Matriz vacía'::TEXT;
        RETURN;
    END IF;
    
    RETURN QUERY SELECT 'MATRIZ CYK (compacta - solo contadores)'::TEXT;
    RETURN QUERY SELECT REPEAT('─', 40)::TEXT;
    RETURN QUERY SELECT ''::TEXT;
    
    -- Mostrar matriz de abajo hacia arriba
    FOR offset_idx IN 0..(n - 1) LOOP
        i_idx := n - offset_idx;
        linea := '';
        
        -- Espacios para el triángulo
        FOR j_idx IN 1..(i_idx - 1) LOOP
            linea := linea || '    ';
        END LOOP;
        
        -- Celdas
        FOR j_idx IN i_idx..n LOOP
            SELECT x INTO vars FROM matriz_cyk WHERE matriz_cyk.i = i_idx AND matriz_cyk.j = j_idx;
            count_vars := COALESCE(array_length(vars, 1), 0);
            
            linea := linea || '[' || LPAD(count_vars::TEXT, 2, ' ') || '] ';
        END LOOP;
        
        RETURN QUERY SELECT linea::TEXT;
    END LOOP;
    
    RETURN QUERY SELECT ''::TEXT;
    RETURN QUERY SELECT 'Nota: Cada celda muestra la cantidad de variables'::TEXT;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mostrar_matriz_compacta() IS 
'Versión compacta de la matriz que solo muestra la cantidad de variables
en cada celda en lugar del contenido completo.

Útil para tener una vista rápida del llenado de la matriz.

Uso:
  SELECT * FROM mostrar_matriz_compacta();';

-- ============================================================================
-- FUNCIÓN: mostrar_camino_derivacion
-- Muestra el camino de derivación desde una celda (experimental)
-- ============================================================================

CREATE OR REPLACE FUNCTION mostrar_camino_derivacion(desde_i INTEGER, desde_j INTEGER)
RETURNS TABLE (
    paso INTEGER,
    celda TEXT,
    variables TEXT,
    descripcion TEXT
) AS $$
DECLARE
    vars TEXT[];
    paso_num INTEGER := 1;
BEGIN
    -- Obtener variables de la celda objetivo
    SELECT x INTO vars FROM matriz_cyk WHERE i = desde_i AND j = desde_j;
    
    IF vars IS NULL OR array_length(vars, 1) = 0 THEN
        RETURN QUERY SELECT 
            0, 
            'X[' || desde_i || ',' || desde_j || ']',
            '{}'::TEXT,
            'Celda vacía'::TEXT;
        RETURN;
    END IF;
    
    RETURN QUERY SELECT 
        paso_num,
        'X[' || desde_i || ',' || desde_j || ']',
        array_to_string(vars, ', '),
        'Celda objetivo - subcadena posiciones ' || desde_i || ' a ' || desde_j;
    
    -- TODO: Implementar reconstrucción del árbol de parsing
    -- (requiere almacenar información adicional durante CYK)
    
    RETURN QUERY SELECT 
        paso_num + 1,
        '...',
        '...',
        '(Reconstrucción de árbol no implementada)'::TEXT;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mostrar_camino_derivacion(INTEGER, INTEGER) IS 
'Función experimental para mostrar el camino de derivación desde una celda.
NOTA: La reconstrucción completa del árbol requiere información adicional
que no se almacena en la implementación actual.

Uso:
  SELECT * FROM mostrar_camino_derivacion(1, 9);';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Funciones de visualización de matriz creadas:';
    RAISE NOTICE '  ✓ mostrar_matriz()';
    RAISE NOTICE '  ✓ mostrar_matriz_compacta()';
    RAISE NOTICE '  ✓ mostrar_camino_derivacion(i, j) [experimental]';
END $$;