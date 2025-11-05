-- ============================================================================
-- SETUP INICIAL
-- Configuración del schema y limpieza
-- ============================================================================

-- Eliminar schema si existe (para reinstalación limpia)
DROP SCHEMA IF EXISTS cyk CASCADE;

-- Crear schema
CREATE SCHEMA cyk;

-- Establecer search_path
SET search_path TO cyk;

-- Comentario del schema
COMMENT ON SCHEMA cyk IS 'Schema para el Trabajo Práctico CYK - Parser JSON con Forma Normal de Chomsky';

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE 'Schema "cyk" creado exitosamente';
END $$;
