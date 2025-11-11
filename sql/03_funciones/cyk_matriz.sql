-- ============================================================================
-- FUNCIÓN: setear_matriz
-- Caso general del algoritmo CYK - Programación Dinámica
-- ============================================================================
--
-- Esta función implementa el CORAZÓN del algoritmo CYK usando programación
-- dinámica. Para calcular Xij (subcadena de longitud > 2), usa los resultados
-- ya calculados en filas anteriores.
--
-- PROGRAMACIÓN DINÁMICA:
--   Xij = ⋃ {A | A→BC, B∈Xik, C∈X(k+1)j} para k = i hasta j-1
--         k
--
-- Los valores Xik y X(k+1)j ya fueron calculados en iteraciones previas.
--
-- Complejidad: O(n³ × |V|² × |P|) para toda la matriz
--
-- ============================================================================

SET search_path TO cyk;

CREATE OR REPLACE FUNCTION cyk.setear_matriz(fila INTEGER)
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    longitud INTEGER;
    filas_afectadas INTEGER;
    rec RECORD;
    vars_actuales TEXT[];
BEGIN
    -- Obtener longitud del string
    n := obtener_longitud_string();
    
    -- Validar que la fila está en rango
    IF fila < 1 OR fila > n THEN
        RAISE EXCEPTION 'Fila % fuera de rango (1..%)', fila, n;
    END IF;
    
    -- ========================================================================
    -- CASO ESPECIAL 1: Fila 1 (caso base)
    -- ========================================================================
    IF fila = 1 THEN
        PERFORM setear_fila_base();
        RETURN;
    END IF;
    
    -- ========================================================================
    -- CASO ESPECIAL 2: Fila 2 (optimización)
    -- ========================================================================
    IF fila = 2 THEN
        PERFORM setear_segunda_fila();
        RETURN;
    END IF;
    
    -- ========================================================================
    -- CASO GENERAL: Fila > 2 (PROGRAMACIÓN DINÁMICA)
    -- ========================================================================
    
    longitud := fila;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'FILA % - Longitud % (Programación Dinámica)', fila, longitud;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    WITH spans AS (
        SELECT 
            gs AS i,
            gs + longitud - 1 AS j
        FROM generate_series(1, n - longitud + 1) AS gs
    ),
    particiones AS (
        SELECT
            s.i,
            s.j,
            generate_series(s.i, s.j - 1) AS k
        FROM spans s
    ),
    combinaciones AS (
        SELECT
            p.i,
            p.j,
            COALESCE(
                ARRAY_AGG(DISTINCT pb.variable) FILTER (WHERE pb.variable IS NOT NULL),
                ARRAY[]::TEXT[]
            ) AS vars
        FROM particiones p
        LEFT JOIN matriz_expandida b
               ON b.i = p.i
              AND b.j = p.k
        LEFT JOIN matriz_expandida c
               ON c.i = p.k + 1
              AND c.j = p.j
        LEFT JOIN prod_binarias pb
               ON pb.var_b = b.variable
              AND pb.var_c = c.variable
        GROUP BY p.i, p.j
    )
    INSERT INTO matriz_cyk (i, j, x)
    SELECT i, j, vars
    FROM combinaciones
    ON CONFLICT (i, j) DO UPDATE SET x = EXCLUDED.x;
    
    filas_afectadas := n - longitud + 1;
    
    FOR rec IN
        SELECT 
            gs AS i,
            gs + longitud - 1 AS j,
            get_xij(gs, gs + longitud - 1) AS vars
        FROM generate_series(1, n - longitud + 1) AS gs
    LOOP
        vars_actuales := rec.vars;
        IF array_length(vars_actuales, 1) > 0 THEN
            RAISE NOTICE '  ✓ X[%,%] = {%}', rec.i, rec.j, array_to_string(vars_actuales, ', ');
        ELSE
            RAISE NOTICE '  ✓ X[%,%] = {}', rec.i, rec.j;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✓ Fila % completada (% celdas)', fila, filas_afectadas;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION setear_matriz(INTEGER) IS 
'Función principal del algoritmo CYK que implementa programación dinámica.

Parámetro:
  fila: Nivel de la matriz a calcular (1 = base, 2 = segunda, 3+ = general)

Comportamiento:
  - Si fila = 1: Delega a setear_fila_base() [O(n)]
  - Si fila = 2: Delega a setear_segunda_fila() [O(n × |V|²)]
  - Si fila > 2: Caso general con programación dinámica [O(n × |V|² × |P|)]

Programación Dinámica:
  Para calcular Xij (subcadena ai...aj), prueba todas las particiones k:
    Xij = ⋃ {A | A→BC donde B∈Xik y C∈X(k+1)j}
          k=i..j-1
  
  Los valores Xik y X(k+1)j ya fueron calculados en filas anteriores,
  por lo que se reutilizan (característica clave de DP).

Ejemplo para fila=3, string "abc":
  X[1,3] combina:
    k=1: X[1,1] × X[2,3]  (ya calculados)
    k=2: X[1,2] × X[3,3]  (ya calculados)

Complejidad total: O(n³ × |V|² × |P|)
  n = longitud del string
  |V| = número promedio de variables por celda
  |P| = número de producciones binarias';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✓ Función setear_matriz(fila) creada exitosamente';
    RAISE NOTICE '  • Maneja caso base (fila 1)';
    RAISE NOTICE '  • Maneja optimización (fila 2)';
    RAISE NOTICE '  • Implementa programación dinámica (fila > 2)';
END $$;