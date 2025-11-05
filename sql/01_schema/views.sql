-- ============================================================================
-- VIEWS AUXILIARES
-- Facilitan consultas y uso de unnest (sugerencia del profesor)
-- ============================================================================

SET search_path TO cyk;

-- ============================================================================
-- VIEW: matriz_expandida
-- Expande los arrays de variables usando unnest
-- ============================================================================

CREATE OR REPLACE VIEW matriz_expandida AS
SELECT 
    i,
    j,
    unnest(x) AS variable
FROM matriz_cyk
WHERE x IS NOT NULL 
  AND array_length(x, 1) > 0;

COMMENT ON VIEW matriz_expandida IS 
'Expande cada celda Xij en filas individuales (i, j, variable) usando unnest. 
Útil para JOINs y búsquedas de variables específicas en la matriz.';

-- ============================================================================
-- VIEW: prod_terminales
-- Simplifica acceso a producciones A→a
-- ============================================================================

CREATE OR REPLACE VIEW prod_terminales AS
SELECT 
    id,
    parte_izq AS variable,
    parte_der1 AS terminal
FROM GLC_en_FNC
WHERE tipo_produccion = 1;

COMMENT ON VIEW prod_terminales IS 
'Vista simplificada de producciones terminales (A→a).
Útil para búsquedas rápidas en la fila base del CYK.';

-- ============================================================================
-- VIEW: prod_binarias
-- Simplifica acceso a producciones A→BC
-- ============================================================================

CREATE OR REPLACE VIEW prod_binarias AS
SELECT 
    id,
    parte_izq AS variable,
    parte_der1 AS var_b,
    parte_der2 AS var_c
FROM GLC_en_FNC
WHERE tipo_produccion = 2;

COMMENT ON VIEW prod_binarias IS 
'Vista simplificada de producciones binarias (A→BC).
Útil para búsquedas en el caso inductivo del CYK.';

-- ============================================================================
-- VIEW: estadisticas_gramatica
-- Muestra estadísticas de la gramática cargada
-- ============================================================================

CREATE OR REPLACE VIEW estadisticas_gramatica AS
SELECT 
    COUNT(*) AS total_producciones,
    COUNT(*) FILTER (WHERE tipo_produccion = 1) AS prod_terminales,
    COUNT(*) FILTER (WHERE tipo_produccion = 2) AS prod_binarias,
    COUNT(DISTINCT parte_izq) AS total_variables,
    COUNT(DISTINCT parte_der1) FILTER (WHERE tipo_produccion = 1) AS total_terminales,
    (SELECT parte_izq FROM GLC_en_FNC WHERE start = TRUE LIMIT 1) AS simbolo_inicial
FROM GLC_en_FNC;

COMMENT ON VIEW estadisticas_gramatica IS 
'Muestra estadísticas generales de la gramática cargada en el sistema.';

-- ============================================================================
-- VIEW: estado_sistema
-- Muestra el estado actual del sistema
-- ============================================================================

CREATE OR REPLACE VIEW estado_sistema AS
SELECT 
    'String actual' AS concepto,
    valor AS valor
FROM config WHERE clave = 'string_actual'
UNION ALL
SELECT 
    'Longitud',
    valor
FROM config WHERE clave = 'longitud'
UNION ALL
SELECT 
    'Última ejecución',
    COALESCE(valor, 'Nunca')
FROM config WHERE clave = 'ultima_ejecucion'
UNION ALL
SELECT 
    'Celdas en matriz',
    COUNT(*)::TEXT
FROM matriz_cyk
UNION ALL
SELECT 
    'Tokens en input',
    COUNT(*)::TEXT
FROM string_input;

COMMENT ON VIEW estado_sistema IS 
'Muestra el estado actual del parser: string en proceso, matriz, etc.';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
DECLARE
    total_views INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_views
    FROM information_schema.views
    WHERE table_schema = 'cyk';
    
    RAISE NOTICE 'Views creadas exitosamente: %', total_views;
    RAISE NOTICE '  ✓ matriz_expandida (con unnest)';
    RAISE NOTICE '  ✓ prod_terminales';
    RAISE NOTICE '  ✓ prod_binarias';
    RAISE NOTICE '  ✓ estadisticas_gramatica';
    RAISE NOTICE '  ✓ estado_sistema';
END $$;