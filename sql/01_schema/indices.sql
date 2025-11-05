-- ============================================================================
-- ÍNDICES DE OPTIMIZACIÓN
-- Mejoran el rendimiento de las búsquedas frecuentes
-- ============================================================================

SET search_path TO cyk;

-- ============================================================================
-- ÍNDICES EN GLC_en_FNC
-- ============================================================================

-- Índice para encontrar rápidamente el símbolo inicial
CREATE INDEX idx_glc_start 
ON GLC_en_FNC(start) 
WHERE start = TRUE;

COMMENT ON INDEX idx_glc_start IS 'Búsqueda rápida del símbolo inicial';

-- Índice por tipo de producción
CREATE INDEX idx_glc_tipo 
ON GLC_en_FNC(tipo_produccion);

COMMENT ON INDEX idx_glc_tipo IS 'Filtrar por tipo de producción (1=terminal, 2=binaria)';

-- Índice para producciones terminales (búsqueda por terminal)
CREATE INDEX idx_glc_terminal 
ON GLC_en_FNC(parte_der1) 
WHERE tipo_produccion = 1;

COMMENT ON INDEX idx_glc_terminal IS 'Búsqueda rápida de A→a dado terminal a';

-- Índice para producciones binarias (búsqueda por par de variables)
CREATE INDEX idx_glc_binaria 
ON GLC_en_FNC(parte_der1, parte_der2) 
WHERE tipo_produccion = 2;

COMMENT ON INDEX idx_glc_binaria IS 'Búsqueda rápida de A→BC dado B y C';

-- Índice por variable del lado izquierdo
CREATE INDEX idx_glc_parte_izq 
ON GLC_en_FNC(parte_izq);

COMMENT ON INDEX idx_glc_parte_izq IS 'Búsqueda de producciones por variable';

-- ============================================================================
-- ÍNDICES EN matriz_cyk
-- ============================================================================

-- Índice por fila (i)
CREATE INDEX idx_matriz_i 
ON matriz_cyk(i);

COMMENT ON INDEX idx_matriz_i IS 'Búsqueda por índice inicial';

-- Índice por columna (j)
CREATE INDEX idx_matriz_j 
ON matriz_cyk(j);

COMMENT ON INDEX idx_matriz_j IS 'Búsqueda por índice final';

-- Índice compuesto para búsquedas de rango
CREATE INDEX idx_matriz_rango 
ON matriz_cyk(i, j);

COMMENT ON INDEX idx_matriz_rango IS 'Búsqueda eficiente de rangos i..j';

-- ============================================================================
-- ÍNDICES EN string_input
-- ============================================================================

-- Índice por posición (ya es PK, pero explícito para claridad)
CREATE INDEX idx_string_posicion 
ON string_input(posicion);

COMMENT ON INDEX idx_string_posicion IS 'Acceso rápido por posición del token';

-- ============================================================================
-- ESTADÍSTICAS Y ANÁLISIS
-- ============================================================================

-- Recolectar estadísticas para el optimizador de PostgreSQL
ANALYZE GLC_en_FNC;
ANALYZE matriz_cyk;
ANALYZE string_input;
ANALYZE config;

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
DECLARE
    total_indices INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_indices
    FROM pg_indexes
    WHERE schemaname = 'cyk';
    
    RAISE NOTICE 'Índices creados exitosamente: %', total_indices;
END $$;