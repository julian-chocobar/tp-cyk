# Trabajo Práctico CYK

## Índice

- [Parte 1: Gramática para JSON](#parte-1-gramática-para-json)
- [Parte 2: Transformación a FNC](#parte-2-transformación-a-fnc)
- [Parte 3: Implementación en PostgreSQL](#parte-3-implementación-en-postgresql)
  - [Instalación](#instalación)
  - [Uso del Sistema](#uso-del-sistema)
  - [Estructura de Archivos](#estructura-de-archivos)
  - [Tests](#tests)
  - [Visualización de Resultados](#visualización-de-resultados)
- [Parte 4: Consultas de Visualización](#parte-4-consultas-de-visualización)
- [Parte 5: Extensiones y Mejoras](#parte-5-extensiones-y-mejoras)

## Parte 1: Gramática para JSON

### Símbolo inicial: J

#### Producciones:

```
(1)  J  → { }                          // objeto vacío
(2)  J  → { L }                        // objeto con contenido

(3)  L  → P                            // lista con un par
(4)  L  → P , L                        // lista con múltiples pares

(5)  P  → " K " : V                    // par clave:valor

(6)  K  → C                            // clave de un caracter
(7)  K  → C K                          // clave de múltiples caratcteres

(8)  V  → N                            // valor numérico
(9)  V  → ' S '                        // valor string
(10) V  → J                            // valor objeto (recursión)

(11) S  → ε                            // string vacío
(12) S  → C                            // string de un caracter
(13) S  → C S                      // string de múltiples caracteres
(14) S  → espacio                      // espacio en string
(15) S  → espacio S                    // espacios en string

(16) N  → D                   // número de un dígito
(17) N  → D N            // número de múltiples dígitos

(18) D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
(19) C → a | b | c | d | e | f | g | h | ... | z
```

<!--  -->

#### Símbolos:

- Variables: J, L, P, K, V, S, N, D, C
- Terminales: {, }, [, ], ", ', :, ,, espacio, 0-9, a-z

## Ejemplo 1: `{"a":10}`

### Derivación más a la izquierda:

```
J ⇒ { L }
  ⇒ { P }
  ⇒ { " K " : V }
  ⇒ { " C " : V }
  ⇒ { " a " : V }
  ⇒ { " a " : N }
  ⇒ { " a " : D N }
  ⇒ { " a " : 1 N }
  ⇒ { " a " : 1 D }
  ⇒ { " a " : 1 0 }
```

### Árbol de Parsing:

```
                        J
                        |
                   ┌────┴────┐
                   {    L    }
                        |
                        P
                        |
              ┌─────────┼─────────┐
              "    K    "    :    V
                   |              |
                   C              N
                   |              |
                   a         ┌────┴────┐
                             D         N
                             |         |
                             1         D
                                       |
                                       0
```

## Ejemplo 2: `{"a":10,"b":'hola'}`

### Derivación más a la izquierda:

```
J ⇒ { L }
  ⇒ { P , L }
  ⇒ { " K " : V , L }
  ⇒ { " a " : N , L }
  ⇒ { " a " : 1 0 , L }
  ⇒ { " a " : 1 0 , P }
  ⇒ { " a " : 1 0 , " K " : V }
  ⇒ { " a " : 1 0 , " b " : ' S ' }
  ⇒ { " a " : 1 0 , " b " : ' C S ' }
  ⇒ { " a " : 1 0 , " b " : ' h S ' }
  ⇒ { " a " : 1 0 , " b " : ' h o S ' }
  ⇒ { " a " : 1 0 , " b " : ' h o l S ' }
  ⇒ { " a " : 1 0 , " b " : ' h o l a ' }
```

### Árbol de Parsing (simplificado):

```
                              J
                              |
                         ┌────┴────┐
                         {    L    }
                              |
                         ┌────┼────┐
                         P    ,    L
                         |         |
                   ┌─────┼──────┐  P
                   "  K  "  :   V  |
                      |         |   ...
                      a         N
                                |
                               10
```

## Ejemplo 3 (con anidamiento): `{"a":10,"c":{"d":99}}`

### Derivación parcial:

```
J ⇒ { L }
  ⇒ { P , L }
  ⇒ { " a " : 1 0 , P }
  ⇒ { " a " : 1 0 , " c " : V }
  ⇒ { " a " : 1 0 , " c " : J }
  ⇒ { " a " : 1 0 , " c " : { L } }
  ⇒ { " a " : 1 0 , " c " : { P } }
  ⇒ { " a " : 1 0 , " c " : { " d " : 9 9 } }
```

### Árbol de Parsing (estructura):

```
                              J
                              |
                         ┌────┴────┐
                         {    L    }
                              |
                         ┌────┼────┐
                         P    ,    L
                         |         |
                    "a":10        P
                                  |
                           ┌──────┼──────┐
                           "   K   "  :  V
                               |         |
                               c         J
                                         |
                                    ┌────┴────┐
                                    {    L    }
                                         |
                                         P
                                         |
                                     "d":99
```

## Parte 2: Transformación a FNC

### Gramática Inicial (de la Parte 1)

```
J  → { } | { L }
L  → P | P , L
P  → " K " : V
K  → C | C K
V  → N | ' S ' | J
S  → ε | C | C S | espacio | espacio S
N → D | D N
D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
C → a | b | c | ... | z
```

---

## PASO 1: Eliminar Producciones ε

### Identificar símbolos nulleables:

```
Iteración 1:
- S → ε  ⟹  S es nulleable

Iteración 2:
- (ninguna otra variable deriva ε directamente o mediante nulleables)

Símbolos nulleables: {S}
```

### Generar nuevas producciones:

Para cada producción que contiene S, generamos versiones con y sin S.

**Producción V → ' S ':**

- Original: V → ' S '
- S es nulleable, entonces:
  - V → ' S ' (S presente)
  - V → ' ' (S ausente)

**Producción S → C S:**

- Original: S → C S
- S es nulleable, entonces:
  - S → C S (S presente)
  - S → C (S ausente)

**Producción S → espacio S:**

- Original: S → espacio S
- S es nulleable, entonces:
  - S → espacio S (S presente)
  - S → espacio (S ausente)

### Gramática después de eliminar ε:

```
J  → { } | { L }
L  → P | P , L
P  → " K " : V
K  → C | C K
V  → N | ' S ' | J
S  → C | C S | espacio | espacio S
N → D | D N
D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
C → a | b | c | ... | z
```

---

## PASO 2: Eliminar Producciones Unitarias

### Identificar pares unitarios:

**Caso base:**

```
(J,J), (L,L), (P,P), (K,K), (V,V),
(S,S), (N,N), (D,D), (C,C)
```

**Caso inductivo:**

De L → P:

```
(L, P)
```

De V → J:

```
(V, J)
```

De V → N:

```
(V, N)
```

De K → C:

```
(K, C)
```

De S → C:

```
(S, C)
```

De N → D:

```
(N, D)
```

De D → 0|1|...|9:

```
(D, 0), (D, 1), ..., (D, 9)
```

**Pares unitarios completos:**

```
(L, P), (V, J), (V, N), (K, C), (S, C),
(N, D), (D, 0), (D, 1), ..., (D, 9)
```

### Aplicar eliminación de unitarias:

**Para L → P:**

- P → " K " : V (no unitaria)
- Agregar: L → " K " : V

**Para V → J:**

- J → { } (no unitaria)
- J → { L } (no unitaria)
- Agregar: V → { } | { L }

**Para V → N:**

- N → D | D N (no unitaria)
- Agregar: V → D | D N

**Para K → C:**

- C → a | b | c | ... (no unitarias)
- Agregar: K → a | b | c | ...

**Para S → C:**

- C → a | b | c | ... (no unitarias)
- Agregar: S → a | b | c | ...

**Para N → D:**

- D → 0 | 1 | ... | 9 (no unitarias)
- Agregar: N → 0 | 1 | ... | 9

### Gramática después de eliminar unitarias:

```
J  → { } | { L }

L  → " K " : V | P , L

P  → " K " : V

K  → C K | a | b | c | d | e | f | g | h | ... | z

V  → ' S ' | ' ' | { } | { L } | D N | D

S  → C S | espacio S | a | b | c | ... | z | espacio

N → D N | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

C → a | b | c | d | e | f | g | h | ... | z
```

---

## PASO 3: Eliminar Símbolos No Generadores

### Identificar símbolos generadores:

**Iteración 1 (terminales):**

```
Generadores: {, }, ", ', :, ,, espacio, 0, 1, 2, ..., 9, a, b, c, ..., z
```

**Iteración 2:**

```
- D → 0 (todos sus símbolos son generadores) ✓
- C → a (todos sus símbolos son generadores) ✓

Generadores: {..., D, C}
```

**Iteración 3:**

```
- K → a (generador) ✓
- K → C K (letra y K son generadores) ✓
- S → a (generador) ✓
- S → C S (ambos generadores) ✓
- número → 0 (generador) ✓
- número → D número (ambos generadores) ✓

Generadores: {..., K, S, número}
```

**Iteración 4:**

```
- V → ' ' (ambos terminales) ✓
- V → ' S ' (todos generadores) ✓
- V → { } (ambos terminales) ✓
- V → D N (ambos generadores) ✓
- P → " K " : V (todos generadores) ✓

Generadores: {..., V, P}
```

**Iteración 5:**

```
- L → " K " : V (todos generadores) ✓
- L → P , L (todos generadores) ✓

Generadores: {..., L}
```

**Iteración 6:**

```
- J → { } (ambos terminales) ✓
- J → { L } (todos generadores) ✓

Generadores: {..., J}
```

**Conclusión:** Todos los símbolos son generadores ✓

---

## PASO 4: Eliminar Símbolos No Alcanzables

### Identificar símbolos alcanzables desde J:

**Iteración 1:**

```
Alcanzables: {J}
```

**Iteración 2 (desde J):**

```
J → { } | { L }
Agregar: {, }, L

Alcanzables: {J, {, }, L}
```

**Iteración 3 (desde L):**

```
L → " K " : V | P , L
Agregar: ", K, :, V, P, ,

Alcanzables: {J, {, }, L, ", K, :, V, P, ,}
```

**Iteración 4 (desde K, V, P):**

```
K → C K | a | b | c | ...
V → ' S ' | ' ' | { } | { L } | D N
P → " K " : V

Agregar: C, a-z, ', S, D, N

Alcanzables: {J, L, P, K, V, S, N, D, C, {, }, ", ', :, ,, espacio, 0-9, a-z}
```

**Conclusión:** Todos los símbolos son alcanzables ✓

---

## PASO 5: Conversión a Forma Normal de Chomsky (FNC)

Necesitamos que cada producción sea:

- **A → BC** (dos variables), o
- **A → a** (un terminal)

### Gramática limpia (punto de partida):

```
J  → { } | { L }
L  → " K " : V | P , L
P  → " K " : V
K  → C K | a | b | c | ... | z
V  → ' S ' | ' ' | { } | { L } | D N
S  → C S | espacio S | a | b | ... | z | espacio
N → D N | 0 | 1 | ... | 9
D → 0 | 1 | ... | 9
C → a | b | ... | z
```

### Sub-paso 5.1: Aislar terminales

Para cada terminal que aparece en producciones de longitud ≥ 2, creamos una variable.

```
T_llave_izq → {
T_llave_der → }
T_comilla → "
T_apostrofe → '
T_dos_puntos → :
T_coma → ,
T_espacio → espacio
T_0 → 0
T_1 → 1
...
T_9 → 9
T_a → a
T_b → b
...
T_z → z
```

**Reemplazar en producciones largas:**

```
J  → T_llave_izq T_llave_der
   | T_llave_izq L T_llave_der

L  → T_comilla K T_comilla T_dos_puntos V
   | P T_coma L

P  → T_comilla K T_comilla T_dos_puntos V

K  → C K
   | a | b | c | ... | z

V  → T_apostrofe S T_apostrofe
   | T_apostrofe T_apostrofe
   | T_llave_izq T_llave_der
   | T_llave_izq L T_llave_der
   | D N

S  → C S
   | T_espacio S
   | a | b | ... | z
   | espacio

N → D N | 0 | 1 | ... | 9

D → 0 | 1 | ... | 9

C → a | b | ... | z
```

### Sub-paso 5.2: Descomponer producciones largas

Ahora todas las producciones tienen solo variables, pero algunas tienen más de 2.

**J → T_llave_izq L T_llave_der** (3 símbolos)

```
J → T_llave_izq Z1
Z1 → L T_llave_der
```

**L → T_comilla K T_comilla T_dos_puntos V** (5 símbolos)

```
L → T_comilla Z2
Z2 → K Z3
Z3 → T_comilla Z4
Z4 → T_dos_puntos V
```

**L → P T_coma L** (3 símbolos)

```
L → P Z5
Z5 → T_coma L
```

**P → T_comilla K T_comilla T_dos_puntos V** (5 símbolos)

```
P → T_comilla Z6
Z6 → K Z7
Z7 → T_comilla Z8
Z8 → T_dos_puntos V
```

**V → T_apostrofe S T_apostrofe** (3 símbolos)

```
V → T_apostrofe Z9
Z9 → S T_apostrofe
```

**V → T_llave_izq L T_llave_der** (3 símbolos)

```
V → T_llave_izq Z10
Z10 → L T_llave_der
```

**S → T_espacio S** (ya es binaria) ✓

---

## GRAMÁTICA FINAL EN FNC

### Variables:

```
  J, L, P, K, V, S, N, D, C,
  Z1, Z2, Z3, Z4, Z5, Z6, Z7, Z8, Z9, Z10,
  T_llave_izq, T_llave_der, T_comilla, T_apostrofe,
  T_dos_puntos, T_coma, T_espacio, T_0, ..., T_9, T_a, ..., T_z
```

### Terminales:

```
  {, }, ", ', :, ,, espacio, 0-9, a-z
```

### Símbolo Inicial: J

### PRODUCCIONES TIPO A → BC (dos variables):

---

```
J → T_llave_izq T_llave_der
J → T_llave_izq Z1

Z1 → L T_llave_der

L → T_comilla Z2
L → P Z5

Z2 → K Z3
Z3 → T_comilla Z4
Z4 → T_dos_puntos V
Z5 → T_coma L

P → T_comilla Z6

Z6 → K Z7
Z7 → T_comilla Z8
Z8 → T_dos_puntos V

K → C K

V → T_apostrofe Z9
V → T_apostrofe T_apostrofe
V → T_llave_izq T_llave_der
V → T_llave_izq Z10
V → D N

Z9 → S T_apostrofe
Z10 → L T_llave_der

S → C S
S → T_espacio S

N → D N
```

### PRODUCCIONES TIPO A → a (un terminal):

---

```
T_llave_izq → {
T_llave_der → }
T_comilla → "
T_apostrofe → '
T_dos_puntos → :
T_coma → ,
T_espacio → espacio

T_0 → 0
T_1 → 1
T_2 → 2
T_3 → 3
T_4 → 4
T_5 → 5
T_6 → 6
T_7 → 7
T_8 → 8
T_9 → 9

T_a → a
T_b → b
T_c → c
T_d → d
T_e → e
T_f → f
T_g → g
T_h → h
... (continuar para todas las letras)
T_z → z

K → a
K → b
... (todas las letras)
K → z

S → a
S → b
... (todas las letras)
S → z
S → espacio

N → 0
N → 1
... (todos los dígitos)
N → 9

D → 0
D → 1
... (todos los dígitos)
D → 9

C → a
C → b
... (todas las letras)
C → z
```

---

### Verificación con Ejemplos

### Ejemplo : `{"a":10}` con la gramática en FNC

**Derivación (parcial, mostrando estructura):**

```
J ⇒ T_llave_izq Z1
  ⇒ { Z1
  ⇒ { L T_llave_der
  ⇒ { T_comilla Z2 T_llave_der
  ⇒ { " Z2 }
  ⇒ { " K Z3 }
  ⇒ { " a Z3 }
  ⇒ { " a T_comilla Z4 }
  ⇒ { " a " Z4 }
  ⇒ { " a " T_dos_puntos V }
  ⇒ { " a " : V }
  ⇒ { " a " : D número }
  ⇒ { " a " : T_1 número }
  ⇒ { " a " : 1 número }
  ⇒ { " a " : 1 T_0 }
  ⇒ { " a " : 1 0 }
```

**Árbol de parsing con FNC:**

```
                    J
                   / \
                  /   \
        T_llave_izq   Z1
              |      /  \
              {     L    T_llave_der
                   /|         |
                  / |         }
          T_comilla Z2
              |    / \
              "   K   Z3
                  |  / \
                  a /   \
              T_comilla Z4
                  |    / \
                  "   /   \
              T_dos_puntos V
                  |       / \
                  :      D    N
                         |     \
                        T_1    T_0
                         |      |
                         1      0
```

## Parte 3: Implementación en PostgreSQL

### Arquitectura del Sistema

### 📊 Tablas Principales

1. **GLC_en_FNC**: Almacena la gramática en Forma Normal de Chomsky

   - `start`: Indica si es el símbolo inicial
   - `parte_izq`: Variable del lado izquierdo (A)
   - `parte_der1`: Primera parte del lado derecho (a o B)
   - `parte_der2`: Segunda parte del lado derecho (C o NULL)
   - `tipo_produccion`: 1=Terminal (A→a), 2=Binaria (A→BC)

2. **matriz_cyk**: Matriz triangular del algoritmo CYK

   - `i`, `j`: Coordenadas de la celda
   - `x`: Array de variables que derivan la subcadena i..j

3. **string_input**: String tokenizado

   - `posicion`: Posición del token (1-indexed)
   - `token`: Carácter en esa posición

4. **config**: Configuración global
   - Almacena longitud del string, string actual, etc.

### 🔄 Algoritmo CYK - Programación Dinámica

El algoritmo implementa programación dinámica en tres niveles:

```
cyk(string) → Boolean
  │
  ├─→ tokenizar(string)
  │
  ├─→ PARA fila = 1 HASTA n:
  │    │
  │    └─→ setear_matriz(fila)
  │         │
  │         ├─→ Si fila = 1: setear_fila_base()
  │         │    └─→ Xii = {A | A→ai en gramática}
  │         │
  │         ├─→ Si fila = 2: setear_segunda_fila()
  │         │    └─→ Xi(i+1) usando Xii y X(i+1)(i+1)
  │         │
  │         └─→ Si fila > 2: Caso general
  │              └─→ Xij = ⋃ {A | A→BC, B∈Xik, C∈X(k+1)j}
  │                        k=i..j-1
  │
  └─→ RETORNAR (símbolo_inicial ∈ X1n)
```

**Características:**

- ✅ **Caso base optimizado**: Función dedicada para fila 1
- ✅ **Segunda fila optimizada**: Solo 1 partición posible
- ✅ **Reutilización de resultados**: Programación dinámica pura
- ✅ **Uso de unnest**: Para iterar sobre arrays de variables
- ✅ **Consultas set-based**: Las funciones `setear_fila_base`, `setear_segunda_fila` y `setear_matriz`
  usan joins con `unnest` para combinar variables sin bucles explícitos

### 📈 Complejidad

- **Tiempo**: O(n³ × |G|)

  - n = longitud del string
  - |G| = número de producciones en la gramática

- **Espacio**: O(n²)
  - Matriz triangular de n×n celdas

### Instalación

### Requisitos

- PostgreSQL 12 o superior
- Cliente psql

### Pasos de Instalación

```bash
# 1. Crear la base de datos
createdb -U postgres tp_cyk

# 2. Navegar a la carpeta del proyecto
cd tp-cyk

# 3. Ejecutar el script principal
psql -U postgres -d tp_cyk -f sql/main.sql

# Para pruebas: Eliminar la base de datos
dropdb -U postgres tp_cyk
```

### Uso del Sistema

### Comandos Básicos

```sql
-- Configurar el search_path (ejecutar una vez por sesión)
SET search_path TO cyk;

-- Conectar a la base de datos
\c tp_cyk

-- Ver la gramática cargada
SELECT * FROM ver_gramatica();

-- Ejecutar el algoritmo CYK
SELECT cyk('{"a":10}');

-- Ver la matriz resultante
SELECT * FROM mostrar_matriz();

-- Limpiar datos para nueva ejecución
SELECT limpiar_datos();

-- Verificar integridad de la gramática
SELECT * FROM verificar_gramatica();
```

### Ejemplos de Tests

```sql
-- Test 1: Objeto vacío
SELECT cyk('{}');

-- Test 2: Un par clave-valor numérico
SELECT cyk('{"a":10}');

-- Test 3: Dos pares
SELECT cyk('{"a":10,"b":99}');

-- Test 4: Valor string
SELECT cyk('{"a":''hola''}');

-- Test 5: String con espacios
SELECT cyk('{"nombre":''Juan Perez''}');

-- Test 6: Anidamiento
SELECT cyk('{"a":{"b":1}}');
```

### Estructura de Archivos

```
tp-cyk/
├── README.md                      # Este archivo
├── sql/
│   ├── main.sql                   # Script principal (ejecuta todo)
│   ├── 00_setup.sql               # Configuración inicial
│   ├── 01_schema/                 # Definición del schema
│   │   ├── tablas.sql             # Tablas principales
│   │   ├── indices.sql            # Índices de optimización
│   │   └── views.sql              # Vistas auxiliares
│   ├── 02_data/                   # Datos de la gramática
│   │   ├── carga_gramatica_json.sql
│   │   └── verificar_carga.sql
│   ├── 03_funciones/              # Funciones del algoritmo
│   │   ├── auxiliares.sql         # Funciones helper
│   │   ├── cyk_base.sql           # Fila base (caso base)
│   │   ├── cyk_segunda.sql        # Segunda fila (optimización)
│   │   ├── cyk_matriz.sql         # Caso general (DP)
│   │   ├── cyk_principal.sql      # Función main cyk()
│   │   └── utilidades.sql         # Funciones de utilidad
│   ├── 04_visualizacion/          # Queries de visualización
│   │   ├── mostrar_gramatica.sql
│   │   └── mostrar_matriz.sql
│   └── 05_tests/                  # Tests unitarios
│       ├── test_01_vacio.sql
│       ├── test_02_simple.sql
│       ├── test_03_dos_pares.sql
│       └── test_04_string.sql
```

### Tests

```bash
# Ejecutar todos los tests
psql -U postgres -d tp_cyk -f sql/05_tests/run_all_tests.sql

# Ejecutar un test específico
psql -U postgres -d tp_cyk -f sql/05_tests/test_01_vacio.sql
psql -U postgres -d tp_cyk -f sql/05_tests/test_02_simple.sql
psql -U postgres -d tp_cyk -f sql/05_tests/test_03_dos_pares.sql
psql -U postgres -d tp_cyk -f sql/05_tests/test_04_string.sql

# Recargar solo la gramática
psql -U postgres -d tp_cyk -c "DELETE FROM cyk.GLC_en_FNC;"
psql -U postgres -d tp_cyk -f sql/02_data/carga_gramatica_json.sql
```

### Visualización de Resultados

### Ver Gramática

```sql
-- Vista formateada
SELECT * FROM ver_gramatica();

-- Estadísticas
SELECT
    COUNT(*) AS total_producciones,
    COUNT(*) FILTER (WHERE tipo_produccion = 1) AS terminales,
    COUNT(*) FILTER (WHERE tipo_produccion = 2) AS binarias
FROM GLC_en_FNC;

-- Producciones por variable
SELECT
    parte_izq,
    COUNT(*) AS cantidad
FROM GLC_en_FNC
GROUP BY parte_izq
ORDER BY cantidad DESC;
```

### Ver Matriz CYK

La función `mostrar_matriz()` devuelve una representación visual de la matriz triangular:

```
MATRIZ CYK TRIANGULAR
==================================================

Tokens: [{] ["] [a] ["] [:] [1] [0] [}]

[J  ]
[Z1 ][J  ]
[L  ][Z2 ][K,C]
[T_c][Z3 ][T_c]
[Z4 ][T_c][Z3 ][T_c]
[V  ][Z4 ][T_d][Z4 ][T_d]
[N  ][V  ][Z4 ][T_d][Z4 ][D,N]
[T_l][Z1 ][V  ][Z4 ][T_d][N  ][D,N]
```

## Parte 4: Consultas de Visualización

Para cumplir con los requerimientos de la Parte 4, podés ejecutar las siguientes consultas (recordá ejecutar `SET search_path TO cyk;` en la sesión actual):

```sql
-- Mostrar la gramática almacenada en FNC
SELECT * FROM ver_gramatica();

-- Mostrar la matriz CYK en formato triangular completo
SELECT * FROM mostrar_matriz();

-- (Opcional) Mostrar la matriz CYK en formato compacto
SELECT * FROM mostrar_matriz_compacta();
```

Estas consultas también se listan en la sección de uso del sistema.

## Parte 5: Extensiones y Mejoras

Antes de realizar estas tareas, recordá ejecutar `SET search_path TO cyk;`.

### Agregar Nueva Gramática

1. Limpiar gramática actual:

```sql
DELETE FROM GLC_en_FNC;
```

2. Insertar nueva gramática en FNC:

```sql
-- Ejemplo: Expresiones aritméticas simples
-- E → E + T | T
-- T → ( E ) | num

-- En FNC:
INSERT INTO GLC_en_FNC (start, parte_izq, parte_der1, parte_der2, tipo_produccion) VALUES
(TRUE, 'E', 'E', 'X1', 2),
(FALSE, 'X1', 'Plus', 'T', 2),
(FALSE, 'E', 'T', NULL, 1),  -- Espera, esto es unitaria!
-- ... (completar correctamente en FNC)
```

3. Probar:

```sql
SELECT cyk('1+2');
```

### Optimizaciones Aplicadas

1. **Índices estratégicos**:

   - Búsqueda rápida de producciones por terminal
   - Búsqueda rápida de producciones binarias
   - Índice en símbolo inicial

2. **Views con unnest**:

   - Facilita queries sobre arrays
   - Mejor rendimiento en JOINs

3. **Funciones especializadas**:

   - Fila base: O(n)
   - Segunda fila: O(n)
   - Resto: O(n³)

4. **RAISE NOTICE para debugging**:
   - Trace completo del algoritmo
   - Útil para entender el flujo
