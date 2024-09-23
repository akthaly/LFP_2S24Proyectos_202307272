# Manual Técnico del Analizador Léxico

Este documento describe la lógica utilizada para el analizador léxico implementado en el módulo `analizador`. Este analizador tiene como objetivo procesar un texto de entrada, identificar los distintos tipos de tokens y manejar errores léxicos.

## Estructura del Código

### Módulo `analizador`

El módulo se define con las siguientes características:

- **Parámetros**:
  - `max_length`: Longitud máxima del contenido del archivo (90000 caracteres).
  - `max_tokens`: Número máximo de tokens a almacenar (90000 tokens).

- **Tipo de Datos**:
  - `Token`: Tipo de dato que almacena un lexema y su tipo correspondiente.

### Subrutina `analyze`

Esta subrutina es el corazón del analizador léxico y realiza el análisis del contenido del archivo. Sus parámetros son:
- `file_content`: Contenido del archivo a analizar (entrada).
- `resultado`: Cadena que almacenará el resultado del análisis (salida).

#### Variables Clave

- `tokens`: Array de tipo `Token` para almacenar los tokens encontrados.
- `errores`: Array para almacenar errores léxicos.
- `current_lexema`: Cadena que contiene el lexema actual.
- `state`: Variable que representa el estado del autómata que analiza el texto.
- `error_detected`: Indicador de si se encontró un error léxico durante el análisis.

### Lógica del Análisis

El análisis se realiza mediante un bucle que recorre cada carácter del contenido del archivo. Dependiendo del estado del autómata, se procesan los caracteres de diferentes maneras:

1. **Estado 0**: Estado inicial. Dependiendo del carácter, se transita a otro estado:
   - Letras [a-z]: Se transita al Estado 1 (identificadores).
   - Comillas (`"`): Se transita al Estado 2 (inicio de cadena).
   - Números [0-9]: Se transita al Estado 5 (números).
   - Llaves (`{`, `}`), porcentajes (`%`), punto y coma (`;`), dos puntos (`:`): Se transita a los estados correspondientes.
   - Espacios, tabulaciones y saltos de línea son ignorados.

2. **Estado 1**: Procesa identificadores. Si se encuentra una letra, se acumula en `current_lexema`. Al finalizar, se verifica si es una palabra reservada y se almacenan los tokens.

3. **Estado 2-4**: Procesa cadenas. Se acumulan caracteres hasta encontrar otra comilla que marque el final.

4. **Estado 5**: Procesa números. Se acumulan caracteres numéricos y se verifica si se encuentran dentro de los rangos esperados.

5. **Estados 6-9**: Procesan caracteres especiales como llaves, porcentajes, punto y coma, y dos puntos, respectivamente.

### Manejo de Errores

Si se encuentra un carácter inesperado, se registra un error léxico. Los errores se almacenan en el array `errores`, y se genera un reporte si se detectan errores durante el análisis.

### Resultados Finales

Al final del análisis, se generan dos reportes:
- Un reporte de tokens encontrados.
- Un reporte de errores léxicos encontrados, si los hay.

Los resultados se almacenan en formato HTML para su visualización.

### Funciones Auxiliares

- **`itoa`**: Convierte un entero a una cadena de caracteres.
- **`reporteErroresHTML`**: Genera un archivo HTML que muestra los errores léxicos encontrados.
- **`reporteTokensHTML`**: Genera un archivo HTML que muestra los tokens identificados.


