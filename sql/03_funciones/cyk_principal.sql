-- ============================================================================
-- FUNCIÓN: cyk
-- Función principal del algoritmo CYK
-- ============================================================================
--
-- Esta es la función de más alto nivel que orquesta todo el algoritmo CYK.
-- 
-- FLUJO DEL ALGORITMO:
--   1. Tokenizar el string de entrada
--   2. Obtener símbolo inicial de la gramática
--   3. Llenar la matriz fila por fila (programación dinámica)
--   4. Verificar si símbolo_inicial ∈ X[1,n]
--   5. Retornar TRUE/FALSE
--
-- Complejidad: O(n³ × |G|) donde n = longitud, |G| = tamaño gramática
--
-- ============================================================================

CREATE OR REPLACE FUNCTION cyk(input_string TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    n INTEGER;
    fila INTEGER;
    simbolo_inicial TEXT;
    x1n TEXT[];
    resultado BOOLEAN;
    tiempo_inicio TIMESTAMP;
    tiempo_fin TIMESTAMP;
    duracion INTERVAL;
BEGIN
    tiempo_inicio := clock_timestamp();
    
    -- ========================================================================
    -- ENCABEZADO
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║                    ALGORITMO CYK - INICIO                      ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'String de entrada: "%"', input_string;
    RAISE NOTICE 'Longitud: % caracteres', length(input_string);
    RAISE NOTICE '';
    
    -- ========================================================================
    -- PASO 1: TOKENIZAR EL STRING
    -- ========================================================================
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'PASO 1: Tokenización';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    n := tokenizar(input_string);
    
    -- Caso especial: string vacío
    IF n = 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
        RAISE NOTICE '║                      RESULTADO FINAL                           ║';
        RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
        RAISE NOTICE '';
        RAISE NOTICE 'String vacío recibido';
        RAISE NOTICE 'Resultado: FALSE (string vacío no pertenece al lenguaje)';
        RAISE NOTICE '';
        RETURN FALSE;
    END IF;
    
    RAISE NOTICE '';
    
    -- ========================================================================
    -- PASO 2: OBTENER SÍMBOLO INICIAL
    -- ========================================================================
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'PASO 2: Configuración';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    
    simbolo_inicial := obtener_simbolo_inicial();
    RAISE NOTICE 'Símbolo inicial de la gramática: %', simbolo_inicial;
    RAISE NOTICE 'Tamaño de la matriz CYK: %×% (triangular superior)', n, n;
    RAISE NOTICE '';
    
    -- ========================================================================
    -- PASO 3: LLENAR LA MATRIZ CYK (PROGRAMACIÓN DINÁMICA)
    -- ========================================================================
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'PASO 3: Construcción de la Matriz CYK';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    RAISE NOTICE 'Aplicando programación dinámica: filas 1 hasta %', n;
    RAISE NOTICE '';
    
    -- Llenar fila por fila, de abajo hacia arriba en la matriz triangular
    -- Cada fila representa subcadenas de longitud creciente
    FOR fila IN 1..n LOOP
        PERFORM setear_matriz(fila);
    END LOOP;
    
    -- ========================================================================
    -- PASO 4: VERIFICAR RESULTADO
    -- ========================================================================
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE 'PASO 4: Verificación del Resultado';
    RAISE NOTICE '─────────────────────────────────────────────────────────────────';
    RAISE NOTICE '';
    
    -- Obtener X[1,n] (celda superior derecha de la matriz)
    x1n := get_xij(1, n);
    
    RAISE NOTICE 'Celda final X[1,%] = %', 
        n, 
        CASE 
            WHEN array_length(x1n, 1) > 0 
            THEN '{' || array_to_string(x1n, ', ') || '}'
            ELSE '{}'
        END;
    RAISE NOTICE '';
    
    -- Verificar si el símbolo inicial está en X[1,n]
    resultado := array_contiene(x1n, simbolo_inicial);
    
    IF resultado THEN
        RAISE NOTICE '✓ Símbolo inicial "%s" ∈ X[1,%]', simbolo_inicial, n;
    ELSE
        RAISE NOTICE '✗ Símbolo inicial "%s" ∉ X[1,%]', simbolo_inicial, n;
    END IF;
    
    RAISE NOTICE '';
    
    -- ========================================================================
    -- RESULTADO FINAL
    -- ========================================================================
    tiempo_fin := clock_timestamp();
    duracion := tiempo_fin - tiempo_inicio;
    
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║                      RESULTADO FINAL                           ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    
    IF resultado THEN
        RAISE NOTICE '═══════════════════════════════════════════════════════════════';
        RAISE NOTICE '   ✓✓✓ EL STRING PERTENECE AL LENGUAJE ✓✓✓';
        RAISE NOTICE '═══════════════════════════════════════════════════════════════';
        RAISE NOTICE '';
        RAISE NOTICE 'String: "%"', input_string;
        RAISE NOTICE 'Longitud: % tokens', n;
        RAISE NOTICE 'Tiempo de ejecución: %', duracion;
    ELSE
        RAISE NOTICE '═══════════════════════════════════════════════════════════════';
        RAISE NOTICE '   ✗✗✗ EL STRING NO PERTENECE AL LENGUAJE ✗✗✗';
        RAISE NOTICE '═══════════════════════════════════════════════════════════════';
        RAISE NOTICE '';
        RAISE NOTICE 'String: "%"', input_string;
        RAISE NOTICE 'Longitud: % tokens', n;
        RAISE NOTICE 'Tiempo de ejecución: %', duracion;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Para ver la matriz completa ejecute:';
    RAISE NOTICE '  SELECT * FROM mostrar_matriz();';
    RAISE NOTICE '';
    
    -- Registrar la ejecución
    PERFORM registrar_ejecucion();
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cyk(TEXT) IS 
'Función principal del algoritmo CYK (Cocke-Younger-Kasami).

Determina si un string pertenece al lenguaje definido por la gramática en FNC.

Parámetro:
  input_string: String a verificar (ej: ''{"a":10}'')

Retorna:
  TRUE si el string pertenece al lenguaje
  FALSE en caso contrario

Algoritmo:
  1. Tokeniza el string carácter por carácter
  2. Construye la matriz CYK usando programación dinámica:
     - Fila 1: Caso base (terminales)
     - Fila 2: Optimización (longitud 2)
     - Filas 3+: Caso general (reutiliza resultados previos)
  3. Verifica si el símbolo inicial está en X[1,n]

Ejemplo de uso:
  SELECT cyk(''{"a":10}'');           → TRUE
  SELECT cyk(''{"a":10,"b":99}'');    → TRUE
  SELECT cyk(''{a:10}'');             → FALSE (sintaxis inválida)

Complejidad: O(n³ × |G|)
  n = longitud del string
  |G| = tamaño de la gramática

Nota: Para strings largos, la ejecución puede tomar tiempo considerable
debido a la complejidad cúbica del algoritmo.';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '╔════════════════════════════════════════════════════════════════╗';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '║     ✓ FUNCIÓN PRINCIPAL cyk(text) CREADA EXITOSAMENTE         ║';
    RAISE NOTICE '║                                                                ║';
    RAISE NOTICE '╚════════════════════════════════════════════════════════════════╝';
    RAISE NOTICE '';
    RAISE NOTICE 'Ejemplo de uso:';
    RAISE NOTICE '  SELECT cyk(''{"a":10}'');';
    RAISE NOTICE '';
END $$;