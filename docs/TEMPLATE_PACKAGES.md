# Plantillas editoriales ZIP — 0.4.0

El ZIP completo es la unidad de instalación. El importador no depende de un catálogo de revistas ni convierte la clase editorial en `article`. Analiza el contenido local, detecta una entrada TeX activa y conserva los archivos del paquete en la plantilla. Las importaciones individuales de `.tex`, `.cls` y `.sty` mantienen el mapeo semántico anterior; para conservar una clase real se utiliza el ZIP.

## Uso

1. Abrir Configuración → Plantillas → Importar plantilla y seleccionar el ZIP, sin descomprimirlo.
2. La plantilla se instala y queda predeterminada para documentos nuevos. El catálogo muestra clase, opciones, entrada, archivos, motor y bibliografía. Si hay varias entradas, se puede seleccionar otra variante.
3. Crear un documento de prueba o un documento nuevo. Propiedades muestra los campos editoriales detectados, incluidos nombres, apellidos, correos y afiliaciones estructuradas.
4. Escribir contenido y usar PDF LaTeX. Las fuentes, márgenes, títulos y formato bibliográfico proceden de la clase del paquete. La miniatura del catálogo usa el PDF de referencia incluido; no certifica el resultado generado.
5. Si faltan dependencias en caché, la preparación con red se activa expresamente desde Configuración → Composición. El análisis no descarga paquetes.

La instalación o cambio de entrada solo afecta documentos nuevos. Cada `.nab` contiene su copia de la plantilla, los recursos y los valores editados. Desinstalar la plantilla del catálogo no rompe esos documentos.

## Detección y composición

Se ignoran las líneas comentadas al elegir `documentclass` y `begin document`. Se prioriza `main.tex`, seguido de `paper.tex`, `manuscript.tex` o `article.tex`; las demás entradas válidas siguen disponibles en el selector. Los archivos UTF-8 y los ejemplos editoriales con Windows-1252/Latin-1 se leen conservando los bytes originales. Se elimina únicamente una carpeta exterior común.

Se conserva el preámbulo y la cabecera editorial hasta la primera sección/capítulo/parte; se sustituye el cuerpo de muestra por los bloques semánticos de Naberius. Los metadatos comunes se enlazan con Propiedades. Los datos estructurados reconocidos se editan sin eliminar sus contenedores, índices de autor o afiliación. Los comandos desconocidos se conservan; el análisis no pretende interpretar todo el lenguaje TeX ni cualquier macro de metadatos personalizada.

Naberius añade paquetes para sus objetos cuando no están cargados; no impone `fontspec`, fuentes ni `geometry` sobre la clase editorial. Las citas del PDF usan los comandos y BST del paquete, con una bibliografía generada a partir de los datos del documento. La vista de escritura sigue siendo semántica; la composición final se verifica en PDF. Las tablas extensas usan `longtable` en una columna y partes flotantes de ancho completo con cabeceras repetidas en dos columnas. Una celda o parte individual excesivamente alta sigue requiriendo revisión.

La exportación contiene una entrada `main.tex` generada junto a los recursos de la entrada seleccionada, bibliografía y assets. Además conserva todos los archivos originales en `original-template/` (con sufijo si ese nombre estaba ocupado). Su README identifica la entrada y el flujo de compilación. Los documentos con paquete usan schemaVersion 2, o 3 cuando guardan columnas o márgenes por lado: versiones antiguas rechazan el documento en lugar de abrirlo y descartar sus recursos.

## Límites concretos

El motor integrado es Tectonic/XeTeX con BibTeX. Se detectan paquetes que exigen LuaLaTeX o Biber y se avisa que pueden guardarse/exportarse, pero no componerse con este motor. No se instala TeX Live ni se ejecutan herramientas del ZIP. Clases que dependen exclusivamente de primitivas pdfTeX, conversiones externas, shell-escape, entradas auxiliares inusuales o macros no reconocidas pueden necesitar adaptación y mostrar un error de composición. La detección genérica no equivale a compatibilidad universal con todo programa TeX.

El cuerpo original es una muestra de formato y se conserva como recurso; no se importa como manuscrito editable. No se incorporan automáticamente las referencias de ejemplo del ZIP a la biblioteca personal del usuario. Los campos que no aparecen en la cabecera detectada no se inventan como controles funcionales.

Límites de importación: ZIP 16 MB, expansión 48 MB, archivo 12 MB y 1.000 entradas. No se admiten ZIP cifrados, multidisco, ZIP64, compresiones distintas de Store/Deflate, rutas ascendentes/absolutas, nombres ambiguos ni enlaces simbólicos.

## Aislamiento

El análisis lee los miembros como datos, sin extraer rutas del ZIP ni lanzar ejecutables suministrados. Componer es una acción separada del usuario: se ejecuta Tectonic en modo no confiable dentro de `sandbox-exec`, con escritura limitada al área temporal y cachés del motor y lectura de documentos privados bloqueada fuera de esa área. Se permite red únicamente al solicitar la preparación de dependencias. No se habilita shell-escape. Este límite de macOS complementa el modo no confiable del motor; no se atribuye al último aislamiento completo del sistema de archivos.

## Ejemplo adjunto y evidencia

Se analizó el paquete Springer Nature de diciembre de 2024: entrada `sn-article.tex`, clase `sn-jnl`, opciones activas `pdflatex,sn-mathphys-num`, nueve archivos BST, recursos EPS, bibliografía y PDF/manual de referencia. Se compuso su clase real con texto nuevo, cita numérica, bibliografía, fracción y tabla; se inspeccionó la primera página renderizada, con tipografía y estructura editorial definidas por la clase. Los bytes de la clase y sus recursos no se modifican.

El paquete de terceros es un recurso local del usuario y no se incluye en el repositorio ni en el ZIP de la aplicación. Sus licencias siguen perteneciendo a sus titulares. Las pruebas ordinarias usan clases y ZIP sintéticos propios, con nombres de revistas arbitrarios. La prueba del ejemplo adjunto se activa con `NABERIUS_TEMPLATE_FIXTURE=/ruta/al/paquete.zip` y `NABERIUS_COMPOSE=1`.


## Paquetes adicionales comprobados en 0.5.0

| ZIP del usuario | Resultado local con Tectonic | Observación |
| --- | --- | --- |
| IEEE-conference-template-062824 | Compila | Clase IEEEtran original, palabras clave IEEE, autores y afiliaciones separados; financiación conservada. Se prepara T1 antes de cargar clases clásicas que seleccionan familias PostScript, evitando la sustitución de Times por Latin Modern bajo Tectonic. |
| jimis-article | Compila | Base article, A4, dos columnas y francés. Es un punto de partida; esta prueba no certifica cumplimiento oficial de JIMIS. |
| IJISA / MECS | Compila | Clase ijisa original, campos de publicación y BibTeX con el `unsrt` declarado en el documento. Se corrigió la elección errónea del BST incluido. |
| cjs-rcs-article | Incompleto | El ZIP aporta main.tex y bibliografía, pero no cjs-rcs-article.cls. Se informa el recurso ausente; puede completarse o convertirse a un diseño libre. |

Las tres composiciones incluyen cuerpo nativo nuevo, cita, bibliografía, ecuación y tabla; se comprueba texto extraíble y PDF real. No se modificaron los bytes de las clases originales. Los ZIP, clases, ejemplos y PDF del usuario permanecen locales y no se publican con el proyecto.

**Completar recursos…** admite un ZIP adicional o archivos individuales, conserva la entrada principal y vuelve a analizar la configuración. En el catálogo afecta a documentos nuevos; desde Propiedades afecta al documento actual. Completar la clase no garantiza que el motor integrado disponga de todas sus dependencias. **Crear diseño libre** conserva una variante editable con las pistas tipográficas y de columnas detectadas, sin prometer reproducción del formato editorial.

Los paquetes con clase ausente o motor no admitido se conservan en el catálogo sin reemplazar automáticamente la plantilla predeterminada.
