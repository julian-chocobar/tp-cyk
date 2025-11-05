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

CREATE OR REPLACE FUNCTION setear_matriz(fila INTEGER)
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    longitud INTEGER;
    vars_resultado TEXT[];
    xik TEXT[];
    xkj TEXT[];
    var_b TEXT;
    var_c TEXT;
    vars_encontradas TEXT[];
    combinaciones_probadas INTEGER;
    combinaciones_exitosas INTEGER;
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
    
    -- Para cada celda Xij donde j - i + 1 = longitud
    FOR i IN 1..(n - longitud + 1) LOOP
        j := i + longitud - 1;
        vars_resultado := '{}';
        combinaciones_probadas := 0;
        combinaciones_exitosas := 0;
        
        RAISE NOTICE '  ┌─ Procesando X[%,%] (subcadena posiciones % a %):', i, j, i, j;
        
        -- PROGRAMACIÓN DINÁMICA: Probar todas las particiones k
        -- Para cada k, usamos resultados YA CALCULADOS: Xik y X(k+1)j
        FOR k IN i..(j - 1) LOOP
            -- Obtener celdas ya calculadas en filas anteriores
            xik := get_xij(i, k);
            xkj := get_xij(k + 1, j);
            
            RAISE NOTICE '  │  Partición k=% : X[%,%] × X[%,%]', 
                k, i, k, k+1, j;
            RAISE NOTICE '  │    X[%,%] = %', 
                i, k, 
                CASE 
                    WHEN array_length(xik, 1) > 0 
                    THEN '{' || array_to_string(xik, ', ') || '}'
                    ELSE '{}'
                END;
            RAISE NOTICE '  │    X[%,%] = %', 
                k+1, j,
                CASE 
                    WHEN array_length(xkj, 1) > 0 
                    THEN '{' || array_to_string(xkj, ', ') || '}'
                    ELSE '{}'
                END;
            
            -- Si ambos conjuntos tienen variables, buscar producciones
            IF array_length(xik, 1) > 0 AND array_length(xkj, 1) > 0 THEN
                
                -- Para cada combinación B ∈ Xik y C ∈ X(k+1)j
                -- Usar CROSS JOIN con unnest (sugerencia del profesor)
                FOR var_b, var_c IN 
                    SELECT b.var AS var_b, c.var AS var_c
                    FROM unnest(xik) AS b(var)
                    CROSS JOIN unnest(xkj) AS c(var)
                LOOP
                    combinaciones_probadas := combinaciones_probadas + 1;
                    
                    -- Buscar producciones A → BC en la gramática
                    vars_encontradas := obtener_vars_binarias(var_b, var_c);
                    
                    IF array_length(vars_encontradas, 1) > 0 THEN
                        combinaciones_exitosas := combinaciones_exitosas + 1;
                        
                        RAISE NOTICE '  │      ✓ % → % % produce: %', 
                            array_to_string(vars_encontradas, '/'),
                            var_b, 
                            var_c,
                            array_to_string(vars_encontradas, ', ');
                        
                        -- Unir con resultado (programación dinámica: acumular)
                        vars_resultado := union_arrays(vars_resultado, vars_encontradas);
                    END IF;
                END LOOP;
            ELSE
                RAISE NOTICE '  │      (conjuntos vacíos, no hay combinaciones)';
            END IF;
        END LOOP;
        
        -- Insertar resultado final en la matriz
        PERFORM set_xij(i, j, vars_resultado);
        
        -- Log del resultado
        RAISE NOTICE '  │';
        RAISE NOTICE '  └─ RESULTADO: X[%,%] = %', 
            i, j,
            CASE 
                WHEN array_length(vars_resultado, 1) > 0 
                THEN '{' || array_to_string(vars_resultado, ', ') || '}'
                ELSE '{}'
            END;
        RAISE NOTICE '     (Probadas: % combinaciones, Exitosas: %)', 
            combinaciones_probadas, combinaciones_exitosas;
        RAISE NOTICE '';
    END LOOP;
    
    RAISE NOTICE '✓ Fila % completada (% celdas)', fila, n - longitud + 1;
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