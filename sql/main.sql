-- ============================================================================
-- TRABAJO PRÁCTICO CYK - SCRIPT PRINCIPAL
-- Teoría de la Computación - 2do Cuatrimestre 2025
-- ============================================================================
-- 
-- Este script ejecuta todos los componentes del TP en el orden correcto.
-- 
-- IMPORTANTE: Ejecutar desde la carpeta raíz del proyecto:
--   psql -d tp_cyk -f sql/main.sql
--
-- ============================================================================

\echo ''
\echo '╔════════════════════════════════════════════════════════════════╗'
\echo '║                                                                ║'
\echo '║              TRABAJO PRÁCTICO CYK - INSTALACIÓN                ║'
\echo '║                                                                ║'
\echo '║           Algoritmo CYK para Parser de JSON en FNC             ║'
\echo '║                                                                ║'
\echo '╚════════════════════════════════════════════════════════════════╝'
\echo ''


-- ============================================================================
-- PASO 1: CONFIGURACIÓN INICIAL
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 1/7: Configuración inicial'
\echo '═══════════════════════════════════════════════════════════════'
\i sql/00_setup.sql
\echo ''

-- ============================================================================
-- PASO 2: CREAR SCHEMA DE DATOS
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 2/7: Creando tablas del sistema'
\echo '═══════════════════════════════════════════════════════════════'
\i sql/01_schema/tablas.sql
\echo ''

\echo '>>> Creando índices de optimización...'
\i sql/01_schema/indices.sql
\echo ''

\echo '>>> Creando vistas auxiliares...'
\i sql/01_schema/views.sql
\echo ''

-- ============================================================================
-- PASO 3: CARGAR GRAMÁTICA
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 3/7: Cargando gramática JSON en FNC'
\echo '═══════════════════════════════════════════════════════════════'
\i sql/02_data/carga_gramatica_json.sql
\echo ''

\echo '>>> Verificando carga de gramática...'
\i sql/02_data/verificar_carga.sql
\echo ''

-- ============================================================================
-- PASO 4: CREAR FUNCIONES AUXILIARES
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 4/7: Creando funciones auxiliares'
\echo '═══════════════════════════════════════════════════════════════'
\i sql/03_funciones/auxiliares.sql
\echo ''

-- ============================================================================
-- PASO 5: CREAR FUNCIONES CYK (ALGORITMO PRINCIPAL)
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 5/7: Creando funciones del algoritmo CYK'
\echo '═══════════════════════════════════════════════════════════════'

\echo '>>> Función: setear_fila_base() [Caso base - O(n)]'
\i sql/03_funciones/cyk_base.sql

\echo '>>> Función: setear_segunda_fila() [Optimización - O(n)]'
\i sql/03_funciones/cyk_segunda.sql

\echo '>>> Función: setear_matriz(fila) [Programación dinámica - O(n³)]'
\i sql/03_funciones/cyk_matriz.sql

\echo '>>> Función: cyk(string) [Función principal]'
\i sql/03_funciones/cyk_principal.sql

\echo '>>> Funciones de utilidad'
\i sql/03_funciones/utilidades.sql
\echo ''

-- ============================================================================
-- PASO 6: CREAR FUNCIONES DE VISUALIZACIÓN
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 6/7: Creando funciones de visualización'
\echo '═══════════════════════════════════════════════════════════════'
\i sql/04_visualizacion/mostrar_gramatica.sql
\i sql/04_visualizacion/mostrar_matriz.sql
\echo ''

-- ============================================================================
-- PASO 7: EJECUTAR TESTS UNITARIOS
-- ============================================================================

\echo '═══════════════════════════════════════════════════════════════'
\echo 'PASO 7/7: Tests unitarios (ejecutar manualmente si se desea)'
\echo '═══════════════════════════════════════════════════════════════'
\echo ''
\echo 'Para correr todos los tests luego de la instalación:'
\echo '  \i sql/05_tests/run_all_tests.sql'
\echo ''
\echo 'Para correr un test individual, consultar README.md'
\echo ''

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================

\echo ''
\echo '╔════════════════════════════════════════════════════════════════╗'
\echo '║                                                                ║'
\echo '║                   INSTALACIÓN COMPLETADA                       ║'
\echo '║                                                                ║'
\echo '╚════════════════════════════════════════════════════════════════╝'
\echo ''
\echo '>>> Sistema CYK instalado correctamente'
\echo ''
\echo '═══════════════════════════════════════════════════════════════'