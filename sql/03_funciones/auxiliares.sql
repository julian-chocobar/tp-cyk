-- ============================================================================
-- FUNCIONES AUXILIARES
-- Funciones helper utilizadas por el algoritmo CYK
-- ============================================================================

SET search_path TO cyk;

-- ============================================================================
-- FUNCIÓN: limpiar_datos
-- Limpia todas las tablas de trabajo para una nueva ejecución
-- ============================================================================

CREATE OR REPLACE FUNCTION limpiar_datos()
RETURNS VOID AS $$
BEGIN
    DELETE FROM matriz_cyk;
    DELETE FROM string_input;
    UPDATE config SET valor = '' WHERE clave = 'string_actual';
    UPDATE config SET valor = '0' WHERE clave = 'longitud';
    
    RAISE NOTICE 'Datos de trabajo limpiados';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION limpiar_datos() IS 
'Limpia la matriz CYK, el string de entrada y resetea la configuración.
Debe ejecutarse antes de procesar un nuevo string.';

-- ============================================================================
-- FUNCIÓN: tokenizar
-- Convierte el string de entrada en tokens (carácter por carácter)
-- ============================================================================

CREATE OR REPLACE FUNCTION tokenizar(input_string TEXT)
RETURNS INTEGER AS $$
DECLARE
    pos INTEGER := 1;
    char TEXT;
    token_pos INTEGER := 1;
    len INTEGER;
BEGIN
    -- Limpiar datos previos
    PERFORM limpiar_datos();
    
    len := length(input_string);
    
    -- Si el string está vacío
    IF len = 0 THEN
        RAISE NOTICE 'String vacío recibido';
        RETURN 0;
    END IF;
    
    -- Recorrer cada carácter y crear un token
    WHILE pos <= len LOOP
        char := substring(input_string FROM pos FOR 1);
        
        INSERT INTO string_input (posicion, token) 
        VALUES (token_pos, char);
        
        token_pos := token_pos + 1;
        pos := pos + 1;
    END LOOP;
    
    -- Guardar configuración
    UPDATE config SET valor = input_string WHERE clave = 'string_actual';
    UPDATE config SET valor = (token_pos - 1)::TEXT WHERE clave = 'longitud';
    
    RAISE NOTICE 'String tokenizado: % tokens', token_pos - 1;
    
    RETURN token_pos - 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION tokenizar(TEXT) IS 
'Tokeniza el string de entrada carácter por carácter y lo almacena en string_input.
Retorna: Longitud del string (número de tokens)';

-- ============================================================================
-- FUNCIÓN: obtener_simbolo_inicial
-- Obtiene el símbolo inicial de la gramática
-- ============================================================================

CREATE OR REPLACE FUNCTION obtener_simbolo_inicial()
RETURNS TEXT AS $$
DECLARE
    simbolo TEXT;
BEGIN
    SELECT parte_izq INTO simbolo
    FROM GLC_en_FNC
    WHERE start = TRUE
    LIMIT 1;
    
    IF simbolo IS NULL THEN
        RAISE EXCEPTION 'No se encontró símbolo inicial en la gramática';
    END IF;
    
    RETURN simbolo;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_simbolo_inicial() IS 
'Retorna el símbolo inicial de la gramática cargada.
Lanza excepción si no existe.';

-- ============================================================================
-- FUNCIÓN: get_token
-- Obtiene el token en una posición específica
-- ============================================================================

CREATE OR REPLACE FUNCTION get_token(posicion_i INTEGER)
RETURNS TEXT AS $$
DECLARE
    result TEXT;
BEGIN
    SELECT token INTO result 
    FROM string_input 
    WHERE posicion = posicion_i;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_token(INTEGER) IS 
'Retorna el token (carácter) en la posición i del string de entrada.
Retorna NULL si la posición no existe.';

-- ============================================================================
-- FUNCIÓN: obtener_vars_terminal
-- Obtiene todas las variables que producen un terminal específico (A→a)
-- ============================================================================

CREATE OR REPLACE FUNCTION obtener_vars_terminal(terminal TEXT)
RETURNS TEXT[] AS $$
DECLARE
    resultado TEXT[];
BEGIN
    -- CORRECCIÓN: usar 'variable' en lugar de 'parte_izq'
    SELECT ARRAY_AGG(DISTINCT variable) INTO resultado
    FROM prod_terminales
    WHERE prod_terminales.terminal = obtener_vars_terminal.terminal;
    
    RETURN COALESCE(resultado, '{}');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_vars_terminal(TEXT) IS 
'Retorna un array con todas las variables A tales que A→a está en la gramática.
Usa la vista prod_terminales para optimización.
Retorna array vacío si no hay producciones para ese terminal.';

-- ============================================================================
-- FUNCIÓN: obtener_vars_binarias
-- Obtiene todas las variables que producen A→BC
-- ============================================================================

CREATE OR REPLACE FUNCTION obtener_vars_binarias(var_b TEXT, var_c TEXT)
RETURNS TEXT[] AS $$
DECLARE
    resultado TEXT[];
BEGIN
    SELECT ARRAY_AGG(DISTINCT variable) INTO resultado
    FROM prod_binarias
    WHERE prod_binarias.var_b = obtener_vars_binarias.var_b 
      AND prod_binarias.var_c = obtener_vars_binarias.var_c;
    
    RETURN COALESCE(resultado, '{}');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_vars_binarias(TEXT, TEXT) IS 
'Retorna un array con todas las variables A tales que A→BC está en la gramática.
Usa la vista prod_binarias para optimización.
Retorna array vacío si no hay producciones para ese par.';

-- ============================================================================
-- FUNCIÓN: get_xij
-- Obtiene el contenido de la celda (i,j) de la matriz
-- ============================================================================

CREATE OR REPLACE FUNCTION get_xij(i INTEGER, j INTEGER)
RETURNS TEXT[] AS $$
DECLARE
    resultado TEXT[];
BEGIN
    SELECT x INTO resultado 
    FROM matriz_cyk 
    WHERE matriz_cyk.i = get_xij.i 
      AND matriz_cyk.j = get_xij.j;
    
    RETURN COALESCE(resultado, '{}');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_xij(INTEGER, INTEGER) IS 
'Retorna el array de variables en la celda Xij de la matriz CYK.
Retorna array vacío si la celda no existe o está vacía.';

-- ============================================================================
-- FUNCIÓN: set_xij
-- Establece el contenido de la celda (i,j) de la matriz
-- ============================================================================

CREATE OR REPLACE FUNCTION set_xij(param_i INTEGER, param_j INTEGER, variables TEXT[])
RETURNS VOID AS $$
BEGIN
    INSERT INTO matriz_cyk (i, j, x) 
    VALUES (param_i, param_j, variables)
    ON CONFLICT (i, j) 
    DO UPDATE SET x = EXCLUDED.x;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_xij(INTEGER, INTEGER, TEXT[]) IS 
'Establece el contenido de la celda Xij en la matriz CYK.
Si la celda ya existe, actualiza su contenido.';

-- ============================================================================
-- FUNCIÓN: union_arrays
-- Une dos arrays eliminando duplicados
-- ============================================================================

CREATE OR REPLACE FUNCTION union_arrays(arr1 TEXT[], arr2 TEXT[])
RETURNS TEXT[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT unnest
        FROM unnest(arr1 || arr2) AS unnest
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION union_arrays(TEXT[], TEXT[]) IS 
'Une dos arrays de TEXT eliminando duplicados.
Útil para combinar conjuntos de variables en CYK.';

-- ============================================================================
-- FUNCIÓN: array_contiene
-- Verifica si un elemento está en un array
-- ============================================================================

CREATE OR REPLACE FUNCTION array_contiene(arr TEXT[], elemento TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN elemento = ANY(arr);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION array_contiene(TEXT[], TEXT) IS 
'Retorna TRUE si el elemento está en el array, FALSE en caso contrario.';

-- ============================================================================
-- FUNCIÓN: obtener_longitud_string
-- Obtiene la longitud del string actual desde config
-- ============================================================================

CREATE OR REPLACE FUNCTION obtener_longitud_string()
RETURNS INTEGER AS $$
DECLARE
    n INTEGER;
BEGIN
    SELECT valor::INTEGER INTO n 
    FROM config 
    WHERE clave = 'longitud';
    
    RETURN COALESCE(n, 0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_longitud_string() IS 
'Retorna la longitud del string actualmente en proceso.';

-- ============================================================================
-- FUNCIÓN: obtener_string_actual
-- Obtiene el string actual desde config
-- ============================================================================

CREATE OR REPLACE FUNCTION obtener_string_actual()
RETURNS TEXT AS $$
DECLARE
    str TEXT;
BEGIN
    SELECT valor INTO str 
    FROM config 
    WHERE clave = 'string_actual';
    
    RETURN COALESCE(str, '');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_string_actual() IS 
'Retorna el string actualmente en proceso.';

-- ============================================================================
-- FUNCIÓN: registrar_ejecucion
-- Registra la fecha/hora de la última ejecución
-- ============================================================================

CREATE OR REPLACE FUNCTION registrar_ejecucion()
RETURNS VOID AS $$
BEGIN
    UPDATE config 
    SET valor = NOW()::TEXT 
    WHERE clave = 'ultima_ejecucion';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION registrar_ejecucion() IS 
'Registra el timestamp de la última ejecución del algoritmo CYK.';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Funciones auxiliares creadas exitosamente:';
    RAISE NOTICE '  ✓ limpiar_datos()';
    RAISE NOTICE '  ✓ tokenizar(text)';
    RAISE NOTICE '  ✓ obtener_simbolo_inicial()';
    RAISE NOTICE '  ✓ get_token(integer)';
    RAISE NOTICE '  ✓ obtener_vars_terminal(text)';
    RAISE NOTICE '  ✓ obtener_vars_binarias(text, text)';
    RAISE NOTICE '  ✓ get_xij(integer, integer)';
    RAISE NOTICE '  ✓ set_xij(integer, integer, text[])';
    RAISE NOTICE '  ✓ union_arrays(text[], text[])';
    RAISE NOTICE '  ✓ array_contiene(text[], text)';
    RAISE NOTICE '  ✓ obtener_longitud_string()';
    RAISE NOTICE '  ✓ obtener_string_actual()';
    RAISE NOTICE '  ✓ registrar_ejecucion()';
END $$;