# TRABAJO PRÁCTICO

## Tema: Algoritmo CYK

### Teoría de la Computación

### Trabajo Práctico – 2do semestre de 2025

---

## Consideraciones generales

Implementar los siguientes ejercicios usando una base de datos **PostgreSQL** y programando en **PL/pgSQL**.  
La entrega debe realizarse el día martes \_\_\_ de noviembre. Debe incluir **3 tests unitarios** con los cuales mostrar la funcionalidad.  
La entrega consta de:

- Una **demo presencial** durante la clase de ese día.
- El envío por **email del código** hasta las **18 hs** de ese día.

**No se recibirán TPs luego de ese momento.**  
El trabajo práctico puede realizarse en grupos de **2, 3 o 4 personas**.  
No es necesario entregar informe, ni decisiones tomadas, ni conclusiones.  
Un **diseño adecuado del código** es parte de la evaluación.

---

## Enunciado

Programar el algoritmo de parsing **CYK** usando funciones en **PL/pgSQL** de PostgreSQL.  
Este TP se realiza con fines didácticos, para comprobar en forma práctica el ciclo completo de un parser, desde el diseño de una gramática libre de contexto hasta su implementación mediante un parser.

Los strings a reconocer son expresiones **JSON sencillas** que respondan al siguiente formato:

```text
{"a":10}
{"a":10,"b":’hola’}
{“a”:’hola’,”b”:’chau’,”c”:’’} {“a”:10,”b”:’hola’,“c”:{“d”:’chau’,”e”:99},”f”:{}}
{} 
{“a”:10,”b”:’hola’,“c”:{“d”:’chau’,”e”:99,”g”:{“h”:12}},”f”:{}}

```

Los elementos válidos dentro del JSON pueden ser:

- Números enteros.
- Strings con letras (no es necesario incluir números en los strings) y blancos.
- Elementos JSON (sin límite de anidamiento).

---

### Parte 1

Diseñar una **gramática GLC** que reconozca las expresiones JSON válidas.  
Esta parte deberá tener un **documento de texto** que incluya como mínimo **dos ejemplos de expresiones válidas** con su **árbol de parsing** asociado.

---

### Parte 2

Aplicar todos los algoritmos que cubrimos en la materia (algoritmos de **limpieza** y **pasaje a FNC**).  
Cada algoritmo debe presentarse en un **documento de texto** indicando:

- GLC de input.
- GLC de output.
- Pasos intermedios más importantes (ej: símbolos NO alcanzables, símbolos NO generadores).

No es necesario mostrar el paso a paso de cada algoritmo, solo los puntos más importantes.  
Como conclusión final, debe tenerse la **gramática en FNC generada** (la que vamos a cargar en la base de datos).  
Se valorará que con esta nueva gramática vuelvan a realizar los árboles de parsing de los mismos strings JSON de los ejemplos usados en la **Parte 1**.

> **Nota:** Hasta acá, no es necesario programar nada. Las partes 1 y 2 del TP se presentan en un documento de texto.

---

### Parte 3

Implementar en una base de datos **PostgreSQL** la lógica del algoritmo **CYK** mediante el uso de funciones en **PL/pgSQL**, tablas y SQL.  
Se deben usar las siguientes tablas (sin cambios):

#### Tabla `GLC_en_FNC`

| Columna           | Tipo     | Descripción                           |
| ----------------- | -------- | ------------------------------------- |
| `start`           | boolean  |                                       |
| `parte_izq`       | text     |                                       |
| `parte_der1`      | text     |                                       |
| `parte_der2`      | text     |                                       |
| `tipo_produccion` | smallint | 1: Var → terminal, 2: Var → Var1 Var2 |

Esta tabla deberá cargarse mediante un **script SQL** con un comando `INSERT` por cada producción en la gramática FNC generada en la **Parte 2**.

> **Atención:** Para probar la Parte 3, no es necesario usar la gramática generada en los puntos 1 y 2. Se puede probar con cualquier gramática en FNC.

#### Tabla `matriz_cyk`

| Columna | Tipo     | Descripción                   |
| ------- | -------- | ----------------------------- |
| `i`     | smallint |                               |
| `j`     | smallint |                               |
| `x[]`   | text[]   | Vector de variables de la GLC |

Los elementos de los arreglos `Xij` serán variables de la GLC.  
Setear el contenido de estos arreglos es una parte importante de esta parte del TP.

#### Función `setear_matrix(fila int)`

Será llamada de la siguiente manera por otra función de mayor nivel:

- `setear_matrix(1)`: para setear la primera fila de la matriz triangular (cargar los `Xii`).
- `setear_matrix(2)`: para setear el segundo nivel de la matriz triangular (cargar los `Xi,i+1`).
- `setear_matrix(3)`: para setear el nivel 3 de la matriz triangular (ej: `X2,4`).
- ...
- `setear_matrix(N)`: donde `N` es la longitud del string que representa la expresión JSON.

La expresión JSON debe almacenarse en alguna tabla o variable accesible por la función `setear_matrix`.

#### Función de alto nivel: `cyk(string)`

Debe retornar `true` o `false`.  
Se invocaría de la forma:

```sql
SELECT cyk('{"a":10,"b":"hola","c":{"d":"chau","e":99},"f":{}}');
```

### Parte 4

- Proveer un query en SQL para mostrar la GLC cargada en la tabla GLC_en_FNC.

- Proveer un query en SQL que muestre la matriz triangular de forma visual, similar a la usada en clase.

### Parte 5

Armar una nueva GLC en FNC que reconozca algún tipo de expresión (ej: expresión aritmética).
Luego, crear un script SQL para insertar en la tabla GLC_en_FNC la nueva GLC (borrando la anterior).
Finalmente, probar el algoritmo con algún string válido para la nueva gramática.
Cuidado: No perder los datos de la tabla GLC_en_FNC.
