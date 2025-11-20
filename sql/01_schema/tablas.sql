-- ============================================================================
-- DEFINICIÓN DE TABLAS
-- Tablas principales del sistema CYK
-- ============================================================================

-- ============================================================================
-- TABLA: GLC_en_FNC
-- Almacena la gramática en Forma Normal de Chomsky
-- ============================================================================

CREATE TABLE GLC_en_FNC (
    id SERIAL PRIMARY KEY,
    start BOOLEAN DEFAULT FALSE,
    parte_izq TEXT NOT NULL,
    parte_der1 TEXT NOT NULL,
    parte_der2 TEXT DEFAULT NULL,
    tipo_produccion SMALLINT NOT NULL CHECK (tipo_produccion IN (1, 2)),
    
    -- Constraint para validar consistencia entre tipo y parte_der2
    CONSTRAINT valid_tipo_produccion CHECK (
        (tipo_produccion = 1 AND parte_der2 IS NULL) OR
        (tipo_produccion = 2 AND parte_der2 IS NOT NULL)
    )
);

COMMENT ON TABLE GLC_en_FNC IS 'Gramática Libre de Contexto en Forma Normal de Chomsky';
COMMENT ON COLUMN GLC_en_FNC.id IS 'Identificador único de la producción';
COMMENT ON COLUMN GLC_en_FNC.start IS 'TRUE si la variable es el símbolo inicial';
COMMENT ON COLUMN GLC_en_FNC.parte_izq IS 'Variable del lado izquierdo de la producción (A)';
COMMENT ON COLUMN GLC_en_FNC.parte_der1 IS 'Primer símbolo del lado derecho (a o B)';
COMMENT ON COLUMN GLC_en_FNC.parte_der2 IS 'Segundo símbolo del lado derecho (C) o NULL';
COMMENT ON COLUMN GLC_en_FNC.tipo_produccion IS '1: A→a (terminal), 2: A→BC (binaria)';

-- ============================================================================
-- TABLA: matriz_cyk
-- Matriz triangular para el algoritmo CYK
-- ============================================================================

CREATE TABLE matriz_cyk (
    i SMALLINT NOT NULL,
    j SMALLINT NOT NULL,
    x TEXT[] DEFAULT '{}',
    
    PRIMARY KEY (i, j),
    
    -- Constraint: j debe ser >= i (matriz triangular superior)
    CONSTRAINT valid_triangular CHECK (j >= i)
);

COMMENT ON TABLE matriz_cyk IS 'Matriz triangular CYK: Xij contiene variables que derivan ai...aj';
COMMENT ON COLUMN matriz_cyk.i IS 'Índice inicial de la subcadena (1-indexed)';
COMMENT ON COLUMN matriz_cyk.j IS 'Índice final de la subcadena (1-indexed)';
COMMENT ON COLUMN matriz_cyk.x IS 'Array de variables que derivan la subcadena i..j';

-- ============================================================================
-- TABLA: string_input
-- Almacena el string tokenizado
-- ============================================================================

CREATE TABLE string_input (
    posicion SMALLINT NOT NULL PRIMARY KEY,
    token TEXT NOT NULL,
    
    CONSTRAINT valid_posicion CHECK (posicion > 0)
);

COMMENT ON TABLE string_input IS 'String de entrada tokenizado carácter por carácter';
COMMENT ON COLUMN string_input.posicion IS 'Posición del token en el string (1-indexed)';
COMMENT ON COLUMN string_input.token IS 'Carácter/token en esta posición';

-- ============================================================================
-- TABLA: config
-- Configuración y estado global del sistema
-- ============================================================================

CREATE TABLE config (
    clave TEXT PRIMARY KEY,
    valor TEXT
);

-- Insertar valores iniciales
INSERT INTO config (clave, valor) VALUES 
    ('string_actual', ''),
    ('longitud', '0'),
    ('ultima_ejecucion', NULL);

COMMENT ON TABLE config IS 'Configuración y estado global del parser CYK';
COMMENT ON COLUMN config.clave IS 'Nombre de la configuración';
COMMENT ON COLUMN config.valor IS 'Valor de la configuración (formato TEXT)';

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================

DO $$
DECLARE
    total_tablas INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_tablas
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE';
    
    RAISE NOTICE 'Tablas creadas exitosamente: %', total_tablas;
    RAISE NOTICE '  ✓ GLC_en_FNC';
    RAISE NOTICE '  ✓ matriz_cyk';
    RAISE NOTICE '  ✓ string_input';
    RAISE NOTICE '  ✓ config';
END $$;