# Trabajo Práctico CYK

### Teoría de la Computación

### Trabajo Práctico – 2do semestre de 2025

### Integrantes:
* Chocobar Julian 
* Crevatin Alan 
* Mendoza Leonel


## Índice

- [Parte 1: Gramática para JSON](#parte-1-gramática-para-json)
  - [Símbolo inicial y Producciones](#símbolo-inicial-j)
  - [Ejemplo 1: Objeto simple](#ejemplo-1-jsona10)
  - [Ejemplo 2: Anidamiento](#ejemplo-2-con-anidamiento-jsona10cd99)
- [Parte 2: Transformación a FNC](#parte-2-transformación-a-fnc)
  - [PASO 1: Eliminar Producciones ε](#paso-1-eliminar-producciones-ε)
  - [PASO 2: Eliminar Producciones Unitarias](#paso-2-eliminar-producciones-unitarias)
  - [PASO 3: Eliminar Símbolos No Generadores](#paso-3-eliminar-símbolos-no-generadores)
  - [PASO 4: Eliminar Símbolos No Alcanzables](#paso-4-eliminar-símbolos-no-alcanzables)
  - [PASO 5: Conversión a Forma Normal de Chomsky (FNC)](#paso-5-conversión-a-forma-normal-de-chomsky-fnc)
  - [Gramática Final en FNC](#gramática-final-en-fnc)
- [Parte 3: Implementación en PostgreSQL](#parte-3-implementación-en-postgresql)
  - [Arquitectura del Sistema](#arquitectura-del-sistema)
  - [Tablas Principales](#tablas-principales)
  - [Índices de Optimización](#índices-de-optimización)
  - [VIEWS (Vistas) - Implementación y Propósito](#views-vistas---implementación-y-propósito)
  - [Funciones del Algoritmo CYK](#funciones-del-algoritmo-cyk)
  - [Algoritmo CYK - Programación Dinámica](#algoritmo-cyk---programación-dinámica)
  - [Complejidad](#complejidad)
  - [Instalación](#instalación)
  - [Uso del Sistema](#uso-del-sistema)
  - [Estructura de Archivos](#estructura-de-archivos)
  - [Tests](#tests)
  - [Visualización de Resultados](#visualización-de-resultados)
- [Parte 4: Consultas de Visualización](#parte-4-consultas-de-visualización)
  - [Visualización de la Gramática](#visualización-de-la-gramática)
  - [Visualización de la Matriz CYK](#visualización-de-la-matriz-cyk)
  - [Ejemplos de Uso Completo](#ejemplos-de-uso-completo)
- [Parte 5: Extensiones](#parte-5-extensiones)
  - [Gramática para Operaciones Aritméticas](#gramática-para-operaciones-aritméticas-simples)
  - [Gramática para Paréntesis Balanceados](#gramática-para-paréntesis-balanceados)

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


## Ejemplo 2 (con anidamiento): `{"a":10,"c":{"d":99}}`

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

---

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

**Aplicar transitividad:**

De (V, N) y (N, D):

```
(V, D)
```

**Pares unitarios completos:**

```
(L, P), (V, J), (V, N), (V, D), (K, C), (S, C),
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

**Para V → D (transitivo):**

- D → 0 | 1 | ... | 9 (no unitarias, son terminales)
- Agregar: V → 0 | 1 | ... | 9

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

V  → ' S ' | ' ' | { } | { L } | D N | 0 | 1 | ... | 9

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
- D → 0 (todos sus símbolos son generadores)
- C → a (todos sus símbolos son generadores)

Generadores: {..., D, C}
```

**Iteración 3:**

```
- K → a (generador)
- K → C K (letra y K son generadores)
- S → a (generador)
- S → C S (ambos generadores)
- número → 0 (generador)
- número → D número (ambos generadores)

Generadores: {..., K, S, número}
```

**Iteración 4:**

```
- V → ' ' (ambos terminales)
- V → ' S ' (todos generadores)
- V → { } (ambos terminales)
- V → D N (ambos generadores)
- P → " K " : V (todos generadores)

Generadores: {..., V, P}
```

**Iteración 5:**

```
- L → " K " : V (todos generadores)
- L → P , L (todos generadores)

Generadores: {..., L}
```

**Iteración 6:**

```
- J → { } (ambos terminales)
- J → { L } (todos generadores)

Generadores: {..., J}
```

**Conclusión:** Todos los símbolos son generadores

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

**Conclusión:** Todos los símbolos son alcanzables

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

**S → T_espacio S** (ya es binaria)

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
... (continuar para todos los dígitos)
T_9 → 9

T_a → a
T_b → b
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

V → 0
V → 1
... (todos los dígitos)
V → 9

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

---

## Parte 3: Implementación en PostgreSQL

### Arquitectura del Sistema

### Tablas Principales

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

### Índices de Optimización

Para mejorar el rendimiento de las búsquedas frecuentes en el algoritmo CYK, se implementaron índices estratégicos en las tablas principales.

#### Tabla `GLC_en_FNC`

**Primary Key:** `id` (SERIAL)

**Índices adicionales:**

1. **`idx_glc_start`** (Índice parcial)
   ```sql
   CREATE INDEX idx_glc_start ON GLC_en_FNC(start) WHERE start = TRUE;
   ```
   - **Uso:** Búsqueda rápida del símbolo inicial
   - **Ventaja:** Índice parcial solo para filas donde `start = TRUE`, reduciendo tamaño
   - **Aplicación:** Al inicio del algoritmo para obtener el símbolo inicial

2. **`idx_glc_tipo`**
   ```sql
   CREATE INDEX idx_glc_tipo ON GLC_en_FNC(tipo_produccion);
   ```
   - **Uso:** Filtrar por tipo de producción (1=terminal, 2=binaria)
   - **Aplicación:** En queries que separan producciones terminales de binarias

3. **`idx_glc_terminal`** (Índice parcial)
   ```sql
   CREATE INDEX idx_glc_terminal ON GLC_en_FNC(parte_der1) WHERE tipo_produccion = 1;
   ```
   - **Uso:** Búsqueda rápida de producciones A→a dado el terminal `a`
   - **Ventaja:** Índice parcial solo para producciones terminales
   - **Aplicación:** En `setear_fila_base()` para buscar qué variables derivan cada terminal

4. **`idx_glc_binaria`** (Índice parcial compuesto)
   ```sql
   CREATE INDEX idx_glc_binaria ON GLC_en_FNC(parte_der1, parte_der2) WHERE tipo_produccion = 2;
   ```
   - **Uso:** Búsqueda rápida de A→BC dado B y C
   - **Ventaja:** Índice compuesto optimizado para búsquedas por pares de variables
   - **Aplicación:** En `setear_segunda_fila()` y `setear_matriz()` para buscar producciones binarias

5. **`idx_glc_parte_izq`**
   ```sql
   CREATE INDEX idx_glc_parte_izq ON GLC_en_FNC(parte_izq);
   ```
   - **Uso:** Búsqueda de producciones por variable del lado izquierdo
   - **Aplicación:** Queries que buscan todas las producciones de una variable específica

#### Tabla `matriz_cyk`

**Primary Key:** `(i, j)` - Clave primaria compuesta

**Índices adicionales:**

1. **`idx_matriz_i`**
   ```sql
   CREATE INDEX idx_matriz_i ON matriz_cyk(i);
   ```
   - **Uso:** Búsqueda por índice inicial `i`
   - **Aplicación:** Queries que buscan todas las celdas que empiezan en posición `i`

2. **`idx_matriz_j`**
   ```sql
   CREATE INDEX idx_matriz_j ON matriz_cyk(j);
   ```
   - **Uso:** Búsqueda por índice final `j`
   - **Aplicación:** Queries que buscan todas las celdas que terminan en posición `j`

3. **`idx_matriz_rango`** (Índice compuesto)
   ```sql
   CREATE INDEX idx_matriz_rango ON matriz_cyk(i, j);
   ```
   - **Uso:** Búsqueda eficiente de rangos `i..j`
   - **Aplicación:** 
     - En `matriz_expandida` para JOINs: `ON b.i = p.i AND b.j = p.k`
     - En `get_xij(i, j)` para obtener variables de una celda específica
   - **Nota:** Aunque redundante con la PK, se crea explícitamente para optimizaciones del planner

#### Tabla `string_input`

**Primary Key:** `posicion` (SMALLINT)

**Índices adicionales:**

1. **`idx_string_posicion`**
   ```sql
   CREATE INDEX idx_string_posicion ON string_input(posicion);
   ```
   - **Uso:** Acceso rápido por posición del token
   - **Aplicación:** En `setear_fila_base()` para iterar sobre tokens
   - **Nota:** Redundante con la PK, pero explícito para claridad

#### Resumen de Índices

| Tabla | Primary Key | Índices Adicionales | Total |
|-------|-------------|---------------------|-------|
| `GLC_en_FNC` | `id` | 5 índices (2 parciales, 1 compuesto) | 6 |
| `matriz_cyk` | `(i, j)` | 3 índices (1 compuesto) | 4 |
| `string_input` | `posicion` | 1 índice (redundante) | 2 |
| `config` | `clave` | 0 | 1 |

**Ventajas de los índices:**
- **Índices parciales:** Reducen tamaño al indexar solo subconjuntos relevantes
- **Índices compuestos:** Optimizan búsquedas por múltiples columnas simultáneamente
- **Mejora de rendimiento:** Aceleran las búsquedas más frecuentes del algoritmo
- **Optimización del planner:** PostgreSQL puede elegir mejores planes de ejecución

---

### VIEWS (Vistas) - Implementación y Propósito

Las **VIEWS** (vistas) en PostgreSQL son consultas almacenadas que se comportan como tablas virtuales. No almacenan datos físicamente, sino que ejecutan una consulta cada vez que se accede a ellas.

#### ¿Por qué implementamos VIEWS?

1. **Simplificación de consultas:** Evitan repetir JOINs complejos y filtros en múltiples lugares
2. **Abstracción:** Ocultar la complejidad de la estructura de datos subyacente
3. **Optimización con `unnest`:** Facilitar el trabajo con arrays de PostgreSQL
4. **Mantenibilidad:** Cambios en la lógica se hacen en un solo lugar

#### VIEW 1: `matriz_expandida` - Expansión de Arrays con `unnest`

**Propósito:** Convertir arrays de variables en filas individuales para facilitar JOINs.

**Implementación:**
```sql
CREATE OR REPLACE VIEW matriz_expandida AS
SELECT 
    i,
    j,
    unnest(x) AS variable
FROM matriz_cyk
WHERE x IS NOT NULL 
  AND array_length(x, 1) > 0;
```

**¿Qué hace `unnest`?**
- `unnest(x)` toma un array `TEXT[]` y lo convierte en filas individuales
- Cada elemento del array se convierte en una fila separada

**Ejemplo de transformación:**

**Tabla `matriz_cyk` (con arrays):**
```
i | j | x
--+---+------------------
1 | 1 | {T_llave_izq}
2 | 2 | {T_comilla}
3 | 3 | {K, C, S}
```

**Vista `matriz_expandida` (con unnest):**
```
i | j | variable
--+---+----------
1 | 1 | T_llave_izq
2 | 2 | T_comilla
3 | 3 | K
3 | 3 | C
3 | 3 | S
```

**Uso en el algoritmo:**
- En `setear_segunda_fila()`: Para expandir X[i,i] y X[i+1,i+1] y buscar combinaciones A→BC
- En `setear_matriz()`: Para expandir X[i,k] y X[k+1,j] para todas las particiones k

**Ventajas:**
- Permite JOINs relacionales estándar (más eficientes que operaciones sobre arrays)
- Facilita búsquedas de variables específicas
- Simplifica la lógica del algoritmo CYK
- Reutilizable en múltiples funciones

#### VIEW 2: `prod_terminales` - Producciones Terminales

**Propósito:** Simplificar acceso a producciones de tipo A→a (terminales).

**Implementación:**
```sql
CREATE OR REPLACE VIEW prod_terminales AS
SELECT 
    id,
    parte_izq AS variable,
    parte_der1 AS terminal
FROM GLC_en_FNC
WHERE tipo_produccion = 1;
```

**Uso:**
- Usada en `setear_fila_base()` para buscar qué variables derivan cada terminal
- Filtra automáticamente solo producciones terminales (tipo 1)
- Simplifica queries evitando repetir `WHERE tipo_produccion = 1`

#### VIEW 3: `prod_binarias` - Producciones Binarias

**Propósito:** Simplificar acceso a producciones de tipo A→BC (binarias).

**Implementación:**
```sql
CREATE OR REPLACE VIEW prod_binarias AS
SELECT 
    id,
    parte_izq AS variable,
    parte_der1 AS var_b,
    parte_der2 AS var_c
FROM GLC_en_FNC
WHERE tipo_produccion = 2;
```

**Uso:**
- Usada en `setear_segunda_fila()` y `setear_matriz()` para buscar producciones A→BC
- Facilita JOINs con `matriz_expandida` para encontrar combinaciones válidas
- Nombres de columnas más descriptivos (`var_b`, `var_c`)

#### VIEW 4: `estadisticas_gramatica` - Estadísticas

**Propósito:** Mostrar información resumida de la gramática cargada.

**Uso:** Para verificación y debugging, muestra resumen de la gramática.

#### VIEW 5: `estado_sistema` - Estado del Parser

**Propósito:** Mostrar el estado actual del sistema (string procesado, matriz, etc.).

**Uso:** Para debugging y monitoreo durante la ejecución.

#### Flujo de Uso de VIEWS y `unnest` en el Algoritmo

```
┌──────────────────────────────────────────────────────────┐
│ 1. setear_fila_base()                                    │
│    → Usa: prod_terminales                                │
│    → Busca: ¿Qué variables derivan el terminal en pos i? │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 2. setear_segunda_fila()                                │
│    → Usa: matriz_expandida (con unnest)                 │
│    → Usa: prod_binarias                                 │
│    → Flujo:                                             │
│      1. matriz_expandida expande X[i,i] y X[i+1,i+1]    │
│      2. prod_binarias busca A→BC donde:                 │
│         - B ∈ X[i,i] (de matriz_expandida)              │
│         - C ∈ X[i+1,i+1] (de matriz_expandida)          │
│      3. Agrega A a X[i,i+1]                             │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ 3. setear_matriz() - Caso general                       │
│    → Usa: matriz_expandida (con unnest)                 │
│    → Usa: prod_binarias                                 │
│    → Flujo para cada partición k:                       │
│      1. matriz_expandida expande X[i,k]                 │
│      2. matriz_expandida expande X[k+1,j]               │
│      3. prod_binarias busca A→BC donde:                 │
│         - B ∈ X[i,k] (de matriz_expandida)              │
│         - C ∈ X[k+1,j] (de matriz_expandida)            │
│      4. Agrega todas las A encontradas a X[i,j]         │
└─────────────────────────────────────────────────────────┘
```

**Punto clave:** `unnest` permite trabajar con arrays como si fueran tablas relacionales, facilitando los JOINs necesarios para el algoritmo CYK.

---

### Funciones del Algoritmo CYK

#### Función Principal: `cyk(string)`

**Archivo:** `sql/03_funciones/cyk_principal.sql`

**Uso:**
```sql
SELECT cyk('{"a":10}');
```

**Flujo interno:**
1. **Tokenización:** Llama a `tokenizar(input_string)` → llena `string_input`
2. **Configuración:** Obtiene símbolo inicial y longitud
3. **Construcción de matriz:** Para cada fila de 1 a n:
   - Llama a `setear_matriz(fila)`
4. **Verificación:** Chequea si `símbolo_inicial ∈ X[1,n]`
5. **Retorna:** `TRUE` o `FALSE`

**Complejidad:** O(n³ × |G|)

#### Función: `setear_matriz(fila int)`

**Archivo:** `sql/03_funciones/cyk_matriz.sql`

**Uso interno:** Llamada automáticamente por `cyk()`

**Comportamiento según la fila:**
- **Fila 1:** Llama a `setear_fila_base()` (caso base)
- **Fila 2:** Llama a `setear_segunda_fila()` (optimización)
- **Fila 3+:** Aplica programación dinámica general

**Lógica:**
```sql
-- Para fila = 1: Caso base
IF fila = 1 THEN
    PERFORM setear_fila_base();
    
-- Para fila = 2: Optimización (solo 1 partición posible)
ELSIF fila = 2 THEN
    PERFORM setear_segunda_fila();
    
-- Para fila > 2: Caso general (programación dinámica)
ELSE
    -- Para cada celda X[i,j] donde j-i+1 = fila:
    --   X[i,j] = ⋃ {A | A→BC, B∈X[i,k], C∈X[k+1,j]} para k=i..j-1
END IF;
```

#### Función: `setear_fila_base()`

**Archivo:** `sql/03_funciones/cyk_base.sql`

**Qué hace:**
- Llena la diagonal principal de la matriz (X[i,i])
- Para cada posición i, busca producciones terminales donde `parte_der1 = token[i]`
- Complejidad: O(n × |P_terminales|)

**Uso de VIEWS:**
- Usa `prod_terminales` para buscar rápidamente qué variables derivan cada terminal
- Evita repetir `WHERE tipo_produccion = 1` en múltiples lugares

**Ejemplo:**
```sql
-- Para el string "{"a":10}"
-- X[1,1] = {T_llave_izq}  (porque T_llave_izq → {)
-- X[2,2] = {T_comilla}    (porque T_comilla → ")
-- X[3,3] = {K, C, S}      (porque K → a, C → a, S → a)
-- etc.
```

#### Función: `setear_segunda_fila()`

**Archivo:** `sql/03_funciones/cyk_segunda.sql`

**Qué hace:**
- Llena la segunda diagonal (X[i,i+1])
- Solo hay 1 partición posible: k = i
- Busca producciones binarias A→BC donde B∈X[i,i] y C∈X[i+1,i+1]
- Complejidad: O(n × |V|² × |P|)

**Optimización:** Función dedicada porque solo hay 1 partición, evitando el loop interno.

**Uso de VIEWS y `unnest`:**
```sql
-- 1. Genera pares (i, i+1) para todas las posiciones
WITH pares AS (
    SELECT gs AS i, gs + 1 AS j
    FROM generate_series(1, n - 1) AS gs
),
-- 2. Usa matriz_expandida para expandir arrays en variables individuales
combinaciones AS (
    SELECT p.i, p.j, ...
    FROM pares p
    LEFT JOIN matriz_expandida b  -- ← unnest de X[i,i]
           ON b.i = p.i AND b.j = p.i
    LEFT JOIN matriz_expandida c  -- ← unnest de X[i+1,i+1]
           ON c.i = p.j AND c.j = p.j
    LEFT JOIN prod_binarias pb    -- ← busca A→BC
           ON pb.var_b = b.variable
          AND pb.var_c = c.variable
    ...
)
```

**Por qué `unnest` es crucial aquí:**
- `matriz_cyk.x` es un array: `{T_llave_izq, K, C}`
- Necesitamos hacer JOIN por cada variable individual
- `matriz_expandida` usa `unnest` para convertir:
  - `X[3,3] = {K, C, S}` → 3 filas: `(3,3,K)`, `(3,3,C)`, `(3,3,S)`
- Esto permite buscar todas las combinaciones posibles de B y C

#### Función: `setear_matriz(fila)` - Caso General

**Archivo:** `sql/03_funciones/cyk_matriz.sql`

**Qué hace:**
- Para filas 3 en adelante
- Para cada celda X[i,j] donde j-i+1 = fila:
  - Prueba todas las particiones k = i, i+1, ..., j-1
  - Para cada producción binaria A→BC:
    - Si B ∈ X[i,k] y C ∈ X[k+1,j], agrega A a X[i,j]
- Complejidad: O(n³ × |V|² × |P|)

**Uso detallado de VIEWS y `unnest`:**

```sql
WITH spans AS (
    -- Genera todas las celdas X[i,j] de longitud = fila
    SELECT gs AS i, gs + longitud - 1 AS j
    FROM generate_series(1, n - longitud + 1) AS gs
),
particiones AS (
    -- Para cada celda, genera todas las particiones k
    SELECT s.i, s.j, generate_series(s.i, s.j - 1) AS k
    FROM spans s
),
combinaciones AS (
    SELECT p.i, p.j, ARRAY_AGG(DISTINCT pb.variable) AS vars
    FROM particiones p
    -- ← CLAVE: matriz_expandida usa unnest para expandir arrays
    LEFT JOIN matriz_expandida b  -- Expande X[i,k] en filas individuales
           ON b.i = p.i AND b.j = p.k
    LEFT JOIN matriz_expandida c  -- Expande X[k+1,j] en filas individuales
           ON c.i = p.k + 1 AND c.j = p.j
    -- Busca producciones A→BC donde B y C coinciden
    LEFT JOIN prod_binarias pb
           ON pb.var_b = b.variable  -- B debe estar en X[i,k]
          AND pb.var_c = c.variable  -- C debe estar en X[k+1,j]
    GROUP BY p.i, p.j
)
INSERT INTO matriz_cyk (i, j, x)
SELECT i, j, vars FROM combinaciones;
```

**Ejemplo concreto:**

Para calcular `X[1,3]` con string `"abc"`:

1. **Particiones posibles:** k = 1, k = 2
2. **Para k = 1:**
   - `matriz_expandida` expande `X[1,1]` → filas: `(1,1,B1)`, `(1,1,B2)`, ...
   - `matriz_expandida` expande `X[2,3]` → filas: `(2,3,C1)`, `(2,3,C2)`, ...
   - `prod_binarias` busca: ¿Existe A→B1C1? ¿A→B1C2? ¿A→B2C1? ...
3. **Para k = 2:**
   - Similar, pero con `X[1,2]` y `X[3,3]`
4. **Resultado:** Todas las A encontradas se agregan a `X[1,3]`

**Por qué `unnest` es esencial:**
- Sin `unnest`: Tendríamos que iterar manualmente sobre arrays con loops PL/pgSQL (más lento)
- Con `unnest`: PostgreSQL optimiza los JOINs relacionales (más eficiente)
- Permite usar operaciones SQL estándar (JOIN, GROUP BY, ARRAY_AGG) en lugar de código imperativo

#### Función Auxiliar: `union_arrays(arr1, arr2)`

**Archivo:** `sql/03_funciones/auxiliares.sql`

**Propósito:** Unir dos arrays eliminando duplicados.

**Implementación con `unnest`:**
```sql
CREATE OR REPLACE FUNCTION union_arrays(arr1 TEXT[], arr2 TEXT[])
RETURNS TEXT[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT DISTINCT unnest
        FROM unnest(arr1 || arr2) AS unnest
    );
END;
$$ LANGUAGE plpgsql;
```

**Cómo funciona:**
1. `arr1 || arr2`: Concatena los dos arrays
2. `unnest(arr1 || arr2)`: Expande el array concatenado en filas individuales
3. `SELECT DISTINCT unnest`: Elimina duplicados
4. `ARRAY(...)`: Reconstruye el array sin duplicados

**Por qué usar `unnest` aquí:**
- PostgreSQL no tiene función nativa para unir arrays sin duplicados
- `unnest` permite usar `DISTINCT` (operación relacional) en lugar de loops
- Más eficiente que iterar manualmente sobre arrays

---

### Algoritmo CYK - Programación Dinámica

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

- **Caso base optimizado**: Función dedicada para fila 1
- **Segunda fila optimizada**: Solo 1 partición posible
- **Reutilización de resultados**: Programación dinámica pura
- **Uso de unnest**: Para iterar sobre arrays de variables
- **Consultas set-based**: Las funciones `setear_fila_base`, `setear_segunda_fila` y `setear_matriz`
  usan joins con `unnest` para combinar variables sin bucles explícitos

### Complejidad

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
-- Conectar a la base de datos
\c tp_cyk

-- Ver la gramática cargada
SELECT * FROM ver_gramatica;

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

-- Test 6: Anidamiento simple
SELECT cyk('{"a":{"b":1}}');

-- Test 6: Anidamiento
SELECT cyk('{"a":10,"b":''hola'',"c":{"d":''chau'',"e":99,"g":{"h":12}},"f":{}}');

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
│   │   ├── verificar_carga.sql
│   │   └── extensiones/       # Gramáticas adicionales
│   │       ├── carga_gramatica_aritmetica.sql
│   │       └── carga_gramatica_parentesis.sql
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
psql -U postgres -d tp_cyk -c "DELETE FROM GLC_en_FNC;"
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

---

## Parte 4: Consultas de Visualización

Para cumplir con los requerimientos de la Parte 4, el sistema proporciona múltiples funciones y vistas para visualizar la gramática y la matriz CYK.

### Visualización de la Gramática

#### 1. Vista `ver_gramatica`
Muestra todas las producciones de la gramática en formato legible:

```sql
-- Ver todas las producciones
SELECT * FROM ver_gramatica;

-- Filtrar por variable específica
SELECT * FROM ver_gramatica WHERE variable = 'J';

-- Ver solo producciones terminales
SELECT * FROM ver_gramatica WHERE tipo = 'Terminal';

-- Ver solo producciones binarias
SELECT * FROM ver_gramatica WHERE tipo = 'Binaria';
```

#### 2. Función `mostrar_gramatica_agrupada()`
Muestra la gramática agrupada por variable, con todas las producciones de cada variable en una sola línea:

```sql
SELECT * FROM mostrar_gramatica_agrupada();
```

**Ejemplo de salida:**
```
variable | es_inicial | producciones
---------+------------+------------------------------------------
J        | t          | T_llave_izq T_llave_der | T_llave_izq Z1
V        | f          | T_apostrofe Z9 | T_apostrofe T_apostrofe | ...
```

#### 3. Función `mostrar_estadisticas_detalladas()`
Muestra estadísticas detalladas por variable (total de producciones, terminales, binarias):

```sql
SELECT * FROM mostrar_estadisticas_detalladas();
```

**Ejemplo de salida:**
```
variable | total_prods | prod_terminales | prod_binarias | es_inicial
---------+-------------+-----------------+---------------+------------
J        | 2           | 0               | 2             | Sí
V        | 15          | 10              | 5             | 
```

#### 4. Función `buscar_produccion(simbolo)`
Busca todas las producciones que contengan un símbolo específico (en el lado izquierdo o derecho):

```sql
-- Buscar todas las producciones que involucren 'V'
SELECT * FROM buscar_produccion('V');

-- Buscar producciones que involucren 'J'
SELECT * FROM buscar_produccion('J');

-- Buscar producciones que involucren un terminal
SELECT * FROM buscar_produccion('{');
```

### Visualización de la Matriz CYK

#### 1. Función `mostrar_matriz()`
Muestra la matriz CYK completa en formato triangular visual:

```sql
-- Primero ejecutar el algoritmo CYK
SELECT cyk('{"a":10}');

-- Luego visualizar la matriz
SELECT * FROM mostrar_matriz();
```

**Características:**
- Muestra la matriz de forma triangular (fila base abajo, celda final arriba)
- Cada celda muestra las variables que derivan esa subcadena
- Incluye información adicional: total de celdas, celdas con variables, celda final

#### 2. Función `mostrar_matriz_compacta()`
Versión compacta que solo muestra la cantidad de variables por celda:

```sql
SELECT * FROM mostrar_matriz_compacta();
```

**Útil para:**
- Vista rápida del llenado de la matriz
- Identificar celdas con muchas variables (posibles puntos de análisis)

### Ejemplos de Uso Completo

```sql
-- 1. Ver la gramática completa
SELECT * FROM ver_gramatica;

-- 2. Ver estadísticas de la gramática
SELECT * FROM mostrar_estadisticas_detalladas();

-- 3. Ejecutar el algoritmo CYK
SELECT cyk('{"a":10,"b":99}');

-- 4. Ver la matriz resultante
SELECT * FROM mostrar_matriz();

-- 5. Ver versión compacta
SELECT * FROM mostrar_matriz_compacta();

-- 6. Buscar producciones específicas
SELECT * FROM buscar_produccion('V');
SELECT * FROM buscar_produccion('L');

-- 7. Ver gramática agrupada
SELECT * FROM mostrar_gramatica_agrupada();
```

### Guardar Resultados en Archivo

Para guardar la visualización en un archivo:

```sql
-- Guardar matriz en archivo
\o matriz_resultado.txt
SELECT * FROM mostrar_matriz();
\o

-- Guardar gramática en archivo
\o gramatica.txt
SELECT * FROM ver_gramatica;
\o
```

---

## Parte 5: Extensiones

### Gramática para operaciones aritméticas simples
```
S → E                     # Punto de inicio: una expresión completa

E → E + T                 # Suma: una expresión seguida de + y un término
   | E - T                # Resta: una expresión seguida de - y un término
   | T                    # Caso base: una expresión puede ser solo un término

T → T * P                 # Multiplicación: un término seguido de * y un primario
   | T / P                # División: un término seguido de / y un primario
   | P                    # Caso base: un término puede ser solo un primario

P → ( E )                 # Paréntesis: una expresión rodeada por paréntesis
   | - P                  # Negación unaria: signo menos delante de un primario
   | N                    # Un primario puede ser un número

N → N D                   # Número con más de un dígito: concatenar dígitos
   | D                    # Caso base: un número puede ser un único dígito

D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9   # Dígitos del 0 al 9
```
### Transformación a FNC

### PASO 1: Eliminar Producciones ε
Ninguna produción es A → ε
No hay producciones nulleables.

### PASO 2: Eliminar producciones unitarias

Caso base:
```
(S,S), (E,E), (T,T), (P,P), (N,N), (D,D)
```
Caso inductivo
S → E
```
(S,E)
```
E → T
```
(E,T)
```
T → P
```
(T,P)
```
P → N
```
(P,N)
```
N → D
```
(N,D)
```
Aplicamos transitividad:

Tenemos (S, E) y (E, T) ⇒ (S, T)

Tenemos (S, T) y (T, P) ⇒ (S, P)

Tenemos (S, P) y (P, N) ⇒ (S, N)

Tenemos (S, N) y (N, D) ⇒ (S, D)

De (E, T) y (T, P) ⇒ (E, P)

De (E, P) y (P, N) ⇒ (E, N)

De (E, N) y (N, D) ⇒ (E, D)

De (T, P) y (P, N) ⇒ (T, N)

De (T, N) y (N, D) ⇒ (T, D)

De (P, N) y (N, D) ⇒ (P, D)

### Aplicar eliminacion de unitarias
Para S → E
E → E + T
E → E - T
Agregamos:
S → E + T
S → E - T

Para S → T
T → T * P
T → T / P
Agregamos:
S → T * P
S → T / P

Para S → P
P → ( E )
P → - P
Agregamos:
S → ( E )
S → - P

Para S → N
N → N D
Agregamos:
S → N D

Para S → D
D → 0 | 1 | ... | 9
Agregamos:
S → 0 | 1 | ... | 9

Realizamos el mismo procedimiento para E, T, P

### Gramática después de eliminar producciones unitarias:
```
S → E + T | E - T | T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

E → E + T | E - T | T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

T → T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

P → ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

N → N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```
### PASO 3: Eliminar Símbolos No Generadores

Iteración 1 (terminales):
```
Generadores: '+', '-', '*', '/', '(', ')', 0,1,2,3,4,5,6,7,8,9
```
Iteración 2:
```
D → 0 | 1 | ... | 9 (tiene producción directa a terminales)

Generadores:{..., D}
```
Iteración 3:
```
N → 0 | 1 | ... | 9 (tiene producción directa a terminales)

Generadores:{..., D, N}
```
Iteración 4:
```
P tiene P → N D con N,D generadores entonces P genera.

Generadores:{..., D, N,P}
```
Iteración 5:
```
T tiene T → N D con N,D generadores entonces T genera.

Generadores:{..., D, N,P,T}
```
Iteración 6:
```
E tiene E → N D con N,D generadores entonces E genera.

Generadores:{..., D, N,P,T,E}
```
Iteración 7:
```
S tiene S → N D con N,D generadores entonces S genera.

Generadores:{..., D, N,P,T,E,S}
```
Conclusión: Todos los símbolos son generadores

### PASO 4: Eliminar Símbolos No Alcanzables

Producciones de S:

S → E + T → añade E, T, y terminal +

S → E - T → E, T, -

S → T * P → T, P, *

S → T / P → T, P, /

S → ( E ) → (, E, )

S → - P → -, P

S → N D → N, D

S → 0|1|...|9 → añade dígitos 0..9

Agregamos: E, T, P, N, D y terminales +,-,*,/,(,),0..9.

Alcanzables: { S, E, T, P, N, D, '+','-','*','/','(',')',0..9 }

Observamos que todos los no terminales S,E,T,P,N,D y todos los terminales usados son alcanzables desde S.
Por lo tanto, todos los símbolos son alcanzables

### PASO 5: Conversión a Forma Normal de Chomsky (FNC)

#### Sub-paso 5.1: Aislar terminales

**Regla importante:** Solo aislamos terminales que aparecen en producciones de longitud ≥ 2. Para producciones de longitud 1 (como `S → 0`), NO necesitamos aislar el terminal; podemos tener directamente `S → 0`.

Creamos variables terminales solo para los operadores y paréntesis (que aparecen en producciones de longitud ≥ 2):

```
T_suma → +
T_resta → -
T_mul → *
T_div → /
T_lp → (
T_rp → )
```

**Nota:** Los dígitos (0-9) NO necesitan ser aislados porque:
- Aparecen en producciones de longitud 1: `S → 0`, `D → 0`, etc.
- En FNC, las producciones terminales son `A → a` donde `a` es un terminal literal
- Por lo tanto, `S → 0` es válido en FNC (no necesitamos `S → T_0`)

#### Sub-paso 5.2: Descomponer producciones largas

Gramática limpia (después de eliminar unitarias):
```
S → E + T | E - T | T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

E → E + T | E - T | T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

T → T * P | T / P | ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

P → ( E ) | - P | N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

N → N D | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9

D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

Reemplazamos terminales en producciones de longitud ≥ 2:
```
S → E T_suma T
   | E T_resta T
   | T T_mul P
   | T T_div P
   | T_lp E T_rp
   | T_resta P
   | N D
   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos (NO T_0...T_9)

E → E T_suma T
   | E T_resta T
   | T T_mul P
   | T T_div P
   | T_lp E T_rp
   | T_resta P
   | N D
   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos

T → T T_mul P
   | T T_div P
   | T_lp E T_rp
   | T_resta P
   | N D
   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos

P → T_lp E T_rp
   | T_resta P
   | N D
   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos

N → N D
   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos

D → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9    ← Terminales directos
```
### Descomponemos producciones largas

Para S:
```
S → E Z1
Z1 → T_suma T

S → E Z2
Z2 → T_resta T

S → T Z3
Z3 → T_mul P

S → T Z4
Z4 → T_div P

S → T_lp Z5
Z5 → E T_rp
```

Para E:
```
E → E Z6
Z6 → T_suma T

E → E Z7
Z7 → T_resta T

E → T Z8
Z8 → T_mul P

E → T Z9
Z9 → T_div P

E → T_lp Z10
Z10 → E T_rp
```

Para T:
```
T → T Z11
Z11 → T_mul P

T → T Z12
Z12 → T_div P

T → T_lp Z13
Z13 → E T_rp
```

Para P:
```
P → T_lp Z14
Z14 → E T_rp
```

### GRAMÁTICA FINAL EN FNC

## Variables:
```
S, E, T, P, N, D,
Z1, Z2, Z3, Z4, Z5,
Z6, Z7, Z8, Z9, Z10,
Z11, Z12, Z13, Z14,
T_suma, T_resta, T_mul, T_div, T_lp, T_rp
```

**Nota:** Los dígitos (0-9) son terminales literales, no variables. No necesitamos `T_0...T_9` porque los dígitos solo aparecen en producciones de longitud 1 (`A → a`), que son válidas en FNC.

## Terminales:
```
+ , - , * , / , ( , ) , 0 , 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9
```
Símbolo Inicial: S

### PRODUCCIONES TIPO A → BC (dos variables):
```
S → E Z1
Z1 → T_suma T

S → E Z2
Z2 → T_resta T

S → T Z3
Z3 → T_mul P

S → T Z4
Z4 → T_div P

S → T_lp Z5
Z5 → E T_rp

S → T_resta P
S → N D

E → E Z6
Z6 → T_suma T

E → E Z7
Z7 → T_resta T

E → T Z8
Z8 → T_mul P

E → T Z9
Z9 → T_div P

E → T_lp Z10
Z10 → E T_rp

E → T_resta P
E → N D

T → T Z11
Z11 → T_mul P

T → T Z12
Z12 → T_div P

T → T_lp Z13
Z13 → E T_rp

T → T_resta P
T → N D

P → T_lp Z14
Z14 → E T_rp

P → T_resta P
P → N D

N → N D
```
### PRODUCCIONES TIPO A → a (un terminal):
```
T_suma → +
T_resta → -
T_mul → *
T_div → /
T_lp → (
T_rp → )

S → 0
S → 1
...
S → 9

E → 0
E → 1
...
E → 9

T → 0
T → 1
...
T → 9

P → 0
P → 1
...
P → 9

N → 0
N → 1
...
N → 9

D → 0
D → 1
...
D → 9
```
### Agregar Nueva Gramática

**Nota importante:** Antes de cargar una gramática de extensión, asegúrate de que el sistema base esté instalado ejecutando `sql/main.sql`.

#### Gramática de Operaciones Aritméticas

Para cargar la gramática de operaciones aritméticas:

```bash
# Limpiar y cargar gramática aritmética
psql -U postgres -d tp_cyk -f sql/02_data/extensiones/carga_gramatica_aritmetica.sql
```

O desde psql:

```sql
-- Limpiar y cargar gramática aritmética
\i sql/02_data/extensiones/carga_gramatica_aritmetica.sql
```

**Probar la gramática:**

```sql
-- Limpiar datos de ejecución anterior
SELECT limpiar_datos();

-- Ejemplos válidos
SELECT cyk('1+2');           -- TRUE
SELECT cyk('9*(4-1)');       -- TRUE
SELECT cyk('-5+3');          -- TRUE
SELECT cyk('10+20*3');       -- TRUE

-- Ejemplos inválidos
SELECT cyk('5/(4-1');        -- FALSE (falta paréntesis de cierre)
SELECT cyk('1++2');          -- FALSE (sintaxis inválida)
```

### Gramática para Paréntesis Balanceados

**Gramática original:**
```
S → S S | (S) | ()
```

**En FNC:**
```
S  → S S
S  → T_lp Z1
S  → T_lp T_rp
Z1 → S T_rp
T_lp → '('
T_rp → ')'
```

**Para cargar la gramática:**

```bash
# Limpiar y cargar gramática de paréntesis
psql -U postgres -d tp_cyk -f sql/02_data/extensiones/carga_gramatica_parentesis.sql
```

O desde psql:

```sql
-- Limpiar y cargar gramática de paréntesis
\i sql/02_data/extensiones/carga_gramatica_parentesis.sql
```

**Probar la gramática:**

```sql
-- Limpiar datos de ejecución anterior
SELECT limpiar_datos();

-- Ejemplos válidos
SELECT cyk('()');            -- TRUE
SELECT cyk('()()');          -- TRUE
SELECT cyk('(()())');         -- TRUE
SELECT cyk('((()))');         -- TRUE

-- Ejemplos inválidos
SELECT cyk(')(');            -- FALSE (desbalanceado)
SELECT cyk('(()');            -- FALSE (falta cierre)
SELECT cyk('())');            -- FALSE (desbalanceado)
```

