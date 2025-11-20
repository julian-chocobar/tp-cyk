-- ============================================================================
-- FUNCIÓN: setear_fila_base
-- Caso base del algoritmo CYK - Fila 1 (subcadenas de longitud 1)
-- ============================================================================
--
-- Esta función implementa el caso base de la programación dinámica:
-- Para cada posición i, encuentra todas las variables que derivan el terminal ai
-- 
-- Complejidad: O(n) donde n es la longitud del string
--
-- ============================================================================

CREATE OR REPLACE FUNCTION setear_fila_base()
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    rec RECORD;
    filas_actualizadas INTEGER;
BEGIN
    -- Obtener longitud del string
    n := obtener_longitud_string();
    
    IF n = 0 THEN
        RAISE NOTICE 'No hay string para procesar';
        RETURN;
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'FILA BASE - Longitud 1 (Caso Base)';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
    
    WITH tokens AS (
        SELECT 
            si.posicion AS i,
            COALESCE(
                ARRAY_AGG(DISTINCT pt.variable) FILTER (WHERE pt.variable IS NOT NULL),
                ARRAY[]::TEXT[]
            ) AS vars
        FROM string_input si
        LEFT JOIN prod_terminales pt
               ON pt.terminal = si.token
        GROUP BY si.posicion
    )
    INSERT INTO matriz_cyk (i, j, x)
    SELECT 
        t.i,
        t.i,
        t.vars
    FROM tokens t
    ON CONFLICT (i, j) DO UPDATE SET x = EXCLUDED.x;
    
    filas_actualizadas := 0;
    FOR rec IN
        SELECT 
            si.posicion AS i,
            si.token AS terminal,
            COALESCE(
                ARRAY_AGG(DISTINCT pt.variable) FILTER (WHERE pt.variable IS NOT NULL),
                ARRAY[]::TEXT[]
            ) AS vars
        FROM string_input si
        LEFT JOIN prod_terminales pt
               ON pt.terminal = si.token
        GROUP BY si.posicion, si.token
        ORDER BY si.posicion
    LOOP
        filas_actualizadas := filas_actualizadas + 1;
        IF array_length(rec.vars, 1) > 0 THEN
            RAISE NOTICE 'X[%,%] = % → terminal: "%"', 
                rec.i, rec.i, 
                array_to_string(rec.vars, ', '), 
                rec.terminal;
        ELSE
            RAISE NOTICE 'X[%,%] = {} → terminal: "%" (no hay producciones)', 
                rec.i, rec.i, rec.terminal;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✓ Fila base completada (% celdas)', filas_actualizadas;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION setear_fila_base() IS 
'Caso base del algoritmo CYK: llena la diagonal principal de la matriz.
Para cada posición i, calcula Xii = {A | A→ai está en la gramática}.
Esta es la primera fila de la matriz triangular (subcadenas de longitud 1).

Ejemplo:
  String: {"a":10}
  Posición 1: token "{" → X11 = {T_llave_izq}
  Posición 2: token """ → X22 = {T_comilla}
  Posición 3: token "a" → X33 = {K, C, S}
  etc.

Complejidad: O(n × |P|) donde n = longitud del string, |P| = producciones tipo 1';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✓ Función setear_fila_base() creada exitosamente';
END $$;