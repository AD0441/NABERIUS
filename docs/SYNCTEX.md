# Navegar entre escritura y PDF

Desde Naberius 0.7.0, SyncTeX conecta los párrafos del editor con la composición real de LaTeX.

1. Abre **Editor + PDF** y compón el documento.
2. Coloca el cursor en un párrafo y pulsa **⌥⌘J**, el botón de localización del visor o **Documento → Localizar selección en el PDF**. El PDF muestra y resalta su posición.
3. Mantén **⌘** al hacer clic sobre texto del PDF para seleccionar el párrafo correspondiente en el editor. Desde el modo PDF se abre la vista combinada.
4. Después de editar, actualiza el PDF. Mientras esté desactualizado, se avisa y se bloquean los saltos. La composición siguiente crea un mapa nuevo.

El desplazamiento ordinario, la selección de texto y los enlaces del PDF conservan sus acciones habituales sin el modificador. Los saltos no modifican el contenido ni añaden acciones de deshacer. Se conserva la página y posición del visor al sustituir una composición del mismo documento; si la maquetación cambia, esa posición geométrica puede corresponder a contenido distinto. La localización explícita vuelve a resolver el párrafo con el mapa nuevo.

## Alcance

La unidad de navegación es el **bloque o párrafo**, no un carácter concreto. Hay ida y vuelta comprobada con artículo, informe, carta, dos columnas y una clase editorial dentro de un paquete ZIP anidado. Esto no acredita todas las clases ni macros de revistas.

Los encabezados, portadas, bibliografía e índices que genera una clase pueden no tener un párrafo editable asociado. En ese caso se informa y no se selecciona un destino inventado. Los bloques vacíos y saltos de página pueden no tener salida visible. No es edición directa del PDF ni seguimiento automático del cursor. El ajuste geométrico con páginas rotadas no está certificado.

La sincronización se genera al componer y es temporal. Abrir un `.nab` vuelve a generar el mapa con su PDF; el formato del archivo y sus UUID no cambian. Exportar el proyecto LaTeX mantiene la fuente ordinaria autocontenida del flujo anterior. Guardar PDF exporta el PDF, no el mapa temporal.

## Integración

Tectonic se invoca con `--synctex`, además de su modo no confiable y el aislamiento existente para paquetes. Durante la composición interna cada bloque se emite en un archivo TeX temporal identificado por su UUID, dentro de una carpeta de nombre nuevo. La terminación de párrafo se ejecuta dentro de ese archivo para conservar su identidad en SyncTeX. Las listas mantienen sus entornos en la entrada principal. No se alteran los recursos originales de las plantillas.

Cada `Compilation` conserva un `PDFSynchronization` inmutable: UUID de documento, URL del PDF y lista permitida de fuentes generadas. Las consultas del lector oficial se ejecutan fuera del actor principal, con un scanner independiente que se libera al terminar. La configuración local desactiva `setlocale` global; el puente usa un locale numérico C por hilo durante el análisis. Se limita a 64 MB el archivo comprimido y a 64 los resultados de una consulta directa. Las rutas devueltas se aceptan solo si coinciden con la fuente permitida del UUID; nunca se abren en el editor clases o rutas arbitrarias del mapa.

La sesión valida documento, revisión de edición, URL del PDF y token de consulta antes de aplicar un resultado. Editar, cambiar de documento o sustituir la composición cancela la navegación pendiente. No hay consultas ni composiciones nuevas por cada movimiento del cursor. Se conserva el límite de dos composiciones temporales retenidas y su limpieza.

## Procedencia

Lector oficial [Jérôme Laurens / SyncTeX](https://github.com/jlaurens/synctex), versión declarada **1.31**, revisión fija **04cf8e3e8665ff203248d7af78ee1129afbc1b64**. Se incorporan sin modificar `synctex_parser.c`, `synctex_parser_utils.c` y sus cuatro cabeceras a `Sources/CSyncTeX/`. El puente, cabecera de módulo y configuración local son de Naberius. No se incluye ni se ejecuta el programa de línea de comandos de SyncTeX. Se enlaza zlib del sistema.

Se conserva la [licencia MIT y autoría](licenses/SyncTeX-MIT.txt), también dentro de la aplicación. Documentación de la [API de consultas y coordenadas](https://github.com/jlaurens/synctex/blob/04cf8e3e8665ff203248d7af78ee1129afbc1b64/synctex_parser.h) y de la [interfaz de Tectonic](https://github.com/tectonic-typesetting/tectonic/blob/master/docs/src/ref/v2cli.md). No se han incorporado las demás bibliotecas candidatas de la revisión de requisitos.
