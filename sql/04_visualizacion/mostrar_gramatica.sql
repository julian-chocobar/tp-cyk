-- ============================================================================
-- VISUALIZACIÓN DE GRAMÁTICA
-- Queries y views para mostrar la gramática de forma legible
-- ============================================================================

-- ============================================================================
-- VIEW: ver_gramatica
-- Vista principal para visualizar la gramática
-- ============================================================================

CREATE OR REPLACE VIEW ver_gramatica AS
SELECT 
    id,
    CASE WHEN start THEN '→' ELSE ' ' END AS inicial,
    parte_izq AS variable,
    CASE 
        WHEN tipo_produccion = 1 THEN parte_izq || ' → ' || parte_der1
        WHEN tipo_produccion = 2 THEN parte_izq || ' → ' || parte_der1 || ' ' || parte_der2
    END AS produccion,
    CASE 
        WHEN tipo_produccion = 1 THEN 'Terminal'
        WHEN tipo_produccion = 2 THEN 'Binaria'
    END AS tipo,
    CASE 
        WHEN tipo_produccion = 1 THEN parte_der1
        WHEN tipo_produccion = 2 THEN parte_der1 || ', ' || parte_der2
    END AS lado_derecho
FROM GLC_en_FNC
ORDER BY 
    start DESC,
    tipo_produccion,
    parte_izq,
    parte_der1;

COMMENT ON VIEW ver_gramatica IS 
'Vista formateada de la gramática cargada en el sistema.
Muestra cada producción de forma legible con su tipo.

Uso:
  SELECT * FROM ver_gramatica;
  SELECT * FROM ver_gramatica WHERE variable = ''J'';
  SELECT * FROM ver_gramatica WHERE tipo = ''Terminal'';';

-- ============================================================================
-- FUNCIÓN: mostrar_gramatica_agrupada
-- Muestra la gramática agrupada por variable
-- ============================================================================

CREATE OR REPLACE FUNCTION mostrar_gramatica_agrupada()
RETURNS TABLE (
    variable TEXT,
    es_inicial BOOLEAN,
    producciones TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        parte_izq AS variable,
        BOOL_OR(start) AS es_inicial,
        STRING_AGG(
            CASE 
                WHEN tipo_produccion = 1 THEN parte_der1
                WHEN tipo_produccion = 2 THEN parte_der1 || ' ' || parte_der2
            END,
            ' | '
            ORDER BY tipo_produccion DESC, parte_der1, parte_der2
        ) AS producciones
    FROM GLC_en_FNC
    GROUP BY parte_izq
    ORDER BY 
        BOOL_OR(start) DESC,
        parte_izq;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mostrar_gramatica_agrupada() IS 
'Muestra la gramática con todas las producciones de cada variable agrupadas.
Formato: Variable → opción1 | opción2 | opción3

Uso:
  SELECT * FROM mostrar_gramatica_agrupada();';

-- ============================================================================
-- FUNCIÓN: mostrar_estadisticas_detalladas
-- Muestra estadísticas detalladas por variable
-- ============================================================================

CREATE OR REPLACE FUNCTION mostrar_estadisticas_detalladas()
RETURNS TABLE (
    variable TEXT,
    total_prods INTEGER,
    prod_terminales INTEGER,
    prod_binarias INTEGER,
    es_inicial TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        parte_izq AS variable,
        COUNT(*)::INTEGER AS total_prods,
        COUNT(*) FILTER (WHERE tipo_produccion = 1)::INTEGER AS prod_terminales,
        COUNT(*) FILTER (WHERE tipo_produccion = 2)::INTEGER AS prod_binarias,
        CASE WHEN BOOL_OR(start) THEN '✓' ELSE '' END AS es_inicial
    FROM GLC_en_FNC
    GROUP BY parte_izq
    ORDER BY 
        BOOL_OR(start) DESC,
        COUNT(*) DESC,
        parte_izq;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION mostrar_estadisticas_detalladas() IS 
'Muestra estadísticas detalladas de cada variable de la gramática.

Uso:
  SELECT * FROM mostrar_estadisticas_detalladas();';

-- ============================================================================
-- FUNCIÓN: buscar_produccion
-- Busca producciones que contengan cierto símbolo
-- ============================================================================

CREATE OR REPLACE FUNCTION buscar_produccion(simbolo TEXT)
RETURNS TABLE (
    produccion TEXT,
    tipo TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN tipo_produccion = 1 THEN parte_izq || ' → ' || parte_der1
            WHEN tipo_produccion = 2 THEN parte_izq || ' → ' || parte_der1 || ' ' || parte_der2
        END AS produccion,
        CASE 
            WHEN tipo_produccion = 1 THEN 'Terminal'
            WHEN tipo_produccion = 2 THEN 'Binaria'
        END AS tipo
    FROM GLC_en_FNC
    WHERE parte_izq = buscar_produccion.simbolo
       OR parte_der1 = buscar_produccion.simbolo
       OR parte_der2 = buscar_produccion.simbolo
    ORDER BY parte_izq, tipo_produccion;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION buscar_produccion(TEXT) IS 
'Busca todas las producciones que contengan un símbolo específico
(ya sea en el lado izquierdo o derecho).

Uso:
  SELECT * FROM buscar_produccion(''J'');
  SELECT * FROM buscar_produccion(''{'');';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Funciones de visualización de gramática creadas:';
    RAISE NOTICE '  ✓ VIEW ver_gramatica';
    RAISE NOTICE '  ✓ mostrar_gramatica_agrupada()';
    RAISE NOTICE '  ✓ mostrar_estadisticas_detalladas()';
    RAISE NOTICE '  ✓ buscar_produccion(simbolo)';
END $$;