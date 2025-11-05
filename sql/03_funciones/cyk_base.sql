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

SET search_path TO cyk;

CREATE OR REPLACE FUNCTION setear_fila_base()
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    i INTEGER;
    terminal TEXT;
    vars_array TEXT[];
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
    
    -- Para cada posición i del string, calcular Xii
    FOR i IN 1..n LOOP
        -- Obtener el terminal en la posición i
        terminal := get_token(i);
        
        -- Buscar todas las variables A tales que A→terminal
        vars_array := obtener_vars_terminal(terminal);
        
        -- Insertar en la matriz
        PERFORM set_xij(i, i, vars_array);
        
        -- Log para debugging
        IF array_length(vars_array, 1) IS NOT NULL AND array_length(vars_array, 1) > 0 THEN
            RAISE NOTICE 'X[%,%] = % → terminal: "%"', 
                i, i, 
                array_to_string(vars_array, ', '), 
                terminal;
        ELSE
            RAISE NOTICE 'X[%,%] = {} → terminal: "%" (no hay producciones)', 
                i, i, terminal;
        END IF;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✓ Fila base completada (%  celdas)', n;
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