-- ============================================================================
-- EJECUTAR TODOS LOS TESTS CYK
-- ============================================================================
-- Ejecutar desde la raíz del proyecto:
--   psql -d tp_cyk -f sql/05_tests/run_all_tests.sql
-- ============================================================================

\echo ''
\echo '╔════════════════════════════════════════════════════════════════╗'
\echo '║                       EJECUTANDO TESTS CYK                     ║'
\echo '╚════════════════════════════════════════════════════════════════╝'
\echo ''

\echo '>>> Test 01: Objeto vacío'
\i sql/05_tests/test_01_vacio.sql
\echo ''

\echo '>>> Test 02: JSON simple {"a":10}'
\i sql/05_tests/test_02_simple.sql
\echo ''

\echo '>>> Test 03: JSON con dos pares {"a":10,"b":99}'
\i sql/05_tests/test_03_dos_pares.sql
\echo ''

\echo '>>> Test 04: JSON con string {"a":''hola''}'
\i sql/05_tests/test_04_string.sql
\echo ''

\echo '╔════════════════════════════════════════════════════════════════╗'
\echo '║                   TODOS LOS TESTS FINALIZADOS                  ║'
\echo '╚════════════════════════════════════════════════════════════════╝'
\echo ''

