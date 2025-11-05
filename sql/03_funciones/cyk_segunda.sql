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

CREATE OR REPLACE FUNCTION setear_segunda_fila()
RETURNS VOID AS $$
DECLARE
    n INTEGER;
    i INTEGER;
    j INTEGER;
    vars_resultado TEXT[];
    xii TEXT[];
    xii_plus_1 TEXT[];
    var_b TEXT;
    var_c TEXT;
    vars_encontradas TEXT[];
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
    
    -- Para cada subcadena de longitud 2
    FOR i IN 1..(n - 1) LOOP
        j := i + 1;
        vars_resultado := '{}';
        
        -- Obtener Xii y X(i+1)(i+1) de la fila base
        xii := get_xij(i, i);
        xii_plus_1 := get_xij(i + 1, i + 1);
        
        RAISE NOTICE '  Procesando X[%,%]:', i, j;
        RAISE NOTICE '    Xii = X[%,%] = %', i, i, array_to_string(xii, ', ');
        RAISE NOTICE '    X(i+1)(i+1) = X[%,%] = %', i+1, i+1, array_to_string(xii_plus_1, ', ');
        
        -- Para cada combinación B ∈ Xii y C ∈ X(i+1)(i+1)
        -- Usar unnest para iterar (sugerencia del profesor)
        IF array_length(xii, 1) > 0 AND array_length(xii_plus_1, 1) > 0 THEN
            FOR var_b, var_c IN 
                SELECT b.var AS var_b, c.var AS var_c
                FROM unnest(xii) AS b(var)
                CROSS JOIN unnest(xii_plus_1) AS c(var)
            LOOP
                -- Buscar producciones A → BC
                vars_encontradas := obtener_vars_binarias(var_b, var_c);
                
                IF array_length(vars_encontradas, 1) > 0 THEN
                    RAISE NOTICE '    → Encontrado: % (de % → % %)', 
                        array_to_string(vars_encontradas, ', '),
                        array_to_string(vars_encontradas, '/'),
                        var_b, 
                        var_c;
                    
                    -- Unir con resultado (eliminando duplicados)
                    vars_resultado := union_arrays(vars_resultado, vars_encontradas);
                END IF;
            END LOOP;
        END IF;
        
        -- Insertar resultado en la matriz
        PERFORM set_xij(i, j, vars_resultado);
        
        IF array_length(vars_resultado, 1) > 0 THEN
            RAISE NOTICE '  ✓ X[%,%] = %', i, j, array_to_string(vars_resultado, ', ');
        ELSE
            RAISE NOTICE '  ✓ X[%,%] = {}', i, j;
        END IF;
        RAISE NOTICE '';
    END LOOP;
    
    RAISE NOTICE '✓ Segunda fila completada (% celdas)', n - 1;
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