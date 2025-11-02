
# Trabajo Práctico CYK - Parte 1: Gramática para JSON

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
                 C        N
                   |              |
                   a         ┌────┴────┐
                          D   N
                             |         |
                             1      D
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
                   "  K  "  :  V   |
                      |        |   ...
                      a        N
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

# Trabajo Práctico CYK - Parte 2: Transformación a FNC

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
------------------------------------------
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
---------------------------------------
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

## Verificación con Ejemplos

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



