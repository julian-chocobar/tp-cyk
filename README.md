# Gramática para JSON (Versión inicial - No en FNC)

### Símbolo inicial: J

#### Producciones:
```
(1)  J  → { }                          // objeto vacío
(2)  J  → { L }                        // objeto con contenido

(3)  L  → P                            // lista con un par
(4)  L  → P , L                        // lista con múltiples pares

(5)  P  → " K " : V                    // par clave:valor

(6)  K  → letra                        // clave de un caracter
(7)  K  → letra K                      // clave de múltiples caracteres

(8)  V  → número                       // valor numérico
(9)  V  → ' S '                        // valor string
(10) V  → J                            // valor objeto (recursión)

(11) S  → ε                            // string vacío
(12) S  → letra                        // string de un caracter
(13) S  → letra S                      // string de múltiples caracteres
(14) S  → espacio                      // espacio en string
(15) S  → espacio S                    // espacios en string

(16) número → dígito                   // número de un dígito
(17) número → dígito número            // número de múltiples dígitos

(18) dígito → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
(19) letra → a | b | c | d | e | f | g | h | ... | z
```

#### Símbolos:
- Variables: J, L, P, K, V, S, número, dígito, letra
- Terminales: {, }, [, ], ", ', :, ,, espacio, 0-9, a-z


## Ejemplo 1: `{"a":10}`

### Derivación más a la izquierda:
```
J ⇒ { L }
  ⇒ { P }
  ⇒ { " K " : V }
  ⇒ { " letra " : V }
  ⇒ { " a " : V }
  ⇒ { " a " : número }
  ⇒ { " a " : dígito número }
  ⇒ { " a " : 1 número }
  ⇒ { " a " : 1 dígito }
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
                 letra        número
                   |              |
                   a         ┌────┴────┐
                          dígito   número
                             |         |
                             1      dígito
                                       |
                                       0
```

## Ejemplo 2: `{"a":10,"b":'hola'}`

### Derivación más a la izquierda:
```
J ⇒ { L }
  ⇒ { P , L }
  ⇒ { " K " : V , L }
  ⇒ { " a " : número , L }
  ⇒ { " a " : 1 0 , L }
  ⇒ { " a " : 1 0 , P }
  ⇒ { " a " : 1 0 , " K " : V }
  ⇒ { " a " : 1 0 , " b " : ' S ' }
  ⇒ { " a " : 1 0 , " b " : ' letra S ' }
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
                      a    número
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