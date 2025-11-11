-- ============================================================================
-- FUNCIÓN: setear_segunda_fila
-- Caso optimizado para la segunda fila (subcadenas de longitud 2)
-- ============================================================================
--
-- Esta función es una optimización sugerida por el profesor.
-- Para subcadenas de longitud 2, solo hay UNA partición posible: k = i
-- Por lo tanto: Xi,i+1 se calcula usando Xii y X(i+1)(i+1)
--
-- Complejidad: O(n × |V|²) donde n = longitud, |V| = variables en fila base
--
-- ============================================================================

SET search_path TO cyk;

CREATE OR REPLACE FUNCTION cyk.setear_segunda_fila()
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    idx_i INTEGER;
    idx_j INTEGER;
    filas_afectadas INTEGER;
    vars_actuales TEXT[];
BEGIN
    -- Obtener longitud del string
    n := obtener_longitud_string();
    
    IF n < 2 THEN
        RAISE NOTICE 'String demasiado corto para segunda fila (longitud: %)', n;
        RETURN;
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'SEGUNDA FILA - Longitud 2 (Optimización)';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    WITH pares AS (
        SELECT 
            gs AS i,
            gs + 1 AS j
        FROM generate_series(1, n - 1) AS gs
    ),
    combinaciones AS (
        SELECT
            p.i,
            p.j,
            COALESCE(
                ARRAY_AGG(DISTINCT pb.variable) FILTER (WHERE pb.variable IS NOT NULL),
                ARRAY[]::TEXT[]
            ) AS vars
        FROM pares p
        LEFT JOIN cyk.matriz_expandida b
               ON b.i = p.i
              AND b.j = p.i
        LEFT JOIN cyk.matriz_expandida c
               ON c.i = p.j
              AND c.j = p.j
        LEFT JOIN prod_binarias pb
               ON pb.var_b = b.variable
              AND pb.var_c = c.variable
        GROUP BY p.i, p.j
    )
    INSERT INTO matriz_cyk (i, j, x)
    SELECT combinaciones.i, combinaciones.j, combinaciones.vars
    FROM combinaciones
    ON CONFLICT (i, j) DO UPDATE SET x = EXCLUDED.x;
    
    filas_afectadas := n - 1;
    
    FOR idx_i IN 1..(n - 1) LOOP
        idx_j := idx_i + 1;
        vars_actuales := get_xij(idx_i, idx_j);
        IF array_length(vars_actuales, 1) > 0 THEN
            RAISE NOTICE '  ✓ X[%,%] = {%}', idx_i, idx_j, array_to_string(vars_actuales, ', ');
        ELSE
            RAISE NOTICE '  ✓ X[%,%] = {}', idx_i, idx_j;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✓ Segunda fila completada (% celdas)', filas_afectadas;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION setear_segunda_fila() IS 
'Caso optimizado para subcadenas de longitud 2 en el algoritmo CYK.
Para cada Xi,i+1, solo hay una partición posible (k = i):
  Xi,i+1 = {A | A→BC, B∈Xii, C∈X(i+1)(i+1)}

Esta función es más eficiente que el caso general porque evita el bucle de k.

Ejemplo:
  String: {"a":10}
  X[1,2] combina X[1,1]={T_llave_izq} con X[2,2]={T_comilla}
  Si existe T_llave_izq T_comilla → algo, se agrega a X[1,2]

Complejidad: O(n × |V|² × |P|) 
  donde n = longitud, |V| = variables por celda, |P| = producciones binarias';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✓ Función setear_segunda_fila() creada exitosamente';
END $$;