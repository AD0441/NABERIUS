# Verificación — 30 de octubre de 2026

**Versión actual 0.2.0: 40 pruebas correctas.** La sección inicial conserva las mediciones y ensayos de 0.1.0; la revisión 0.2.0 al final detalla la nueva composición y sus evidencias.

## Entorno

MacBook Pro Apple M1, 8 GB, arm64. Swift 6.4 de Xcode instalado; proyecto en modo Swift 6 con mínimo de herramientas 6.2. App nativa para macOS 14+. Compilación de desarrollo: los números no son garantías de rendimiento de una versión optimizada.

## Pruebas ejecutadas

Comando final: `NABERIUS_COMPOSE=1 NABERIUS_BUILD_DIR=/tmp/naberius-build ./script/test.sh`.

**22 pruebas Swift Testing pasaron**, incluidas variantes parametrizadas, en los targets NaberiusCoreTests y NaberiusAppTests. Resultado íntegro: `test-results.txt`. Se probaron:

- Round-trip de bloques, marcas, imágenes, bibliografía, plantilla, UUID y cursor.
- Rechazo de truncamiento, corrupción e información de tamaño insegura.
- Renumeración de figuras y detección de referencias cruzadas con destino ausente.
- Cambio de plantilla sin alterar semántica ni plantilla original.
- Guardado atómico, modificación externa, conflicto y recuperación íntegra.
- Diario: edición posterior al snapshot y transacción final interrumpida.
- Búsqueda Unicode, mayúsculas, palabra completa y reemplazo literal.
- Importación de campos representados de BibTeX, RIS y CSL-JSON.
- Citas y bibliografía reales con APA 7, IEEE, Vancouver/NLM y Chicago; narrativa, múltiples referencias y localizador.
- Análisis de plantillas seguras e incompatibles sin ejecutar código externo.
- Edición nativa: marcas, enlaces, estilos, nodos, UUID estables y Enter después de título.
- Destino exacto del esquema por UUID después de marcadores de listas.
- Proporción de figuras verticales al limitar su altura.
- Listas nativas: aplicación inmediata y salida de lista vacía, tanto viñetas como numeración.
- Composición real con Tectonic: texto, cita CSL, tabla, figura, ecuación, referencia cruzada, nota e índice. PDF producido y documento fuente intacto.

El capturador de evidencia de ventanas solo se incluye en compilaciones DEBUG. La batería final se ejecutó después de los cambios de apertura nativa y del capturador.

## PDF real

`ejemplo-composicion.pdf` tiene 3 páginas. La primera se renderizó con PDFKit sobre blanco y se inspeccionó visualmente (`ejemplo-pdf-pagina-1.png`). El texto extraído conserva títulos, tabla, fórmula, referencia, nota, índice y bibliografía (`pdf-content-verification.txt`). La figura puede flotar a otra página: es comportamiento de composición LaTeX, no pérdida del recurso.

La preparación inicial descargó paquetes del repositorio de Tectonic por acción de prueba. Una ejecución restringida sin red detectó métricas aún ausentes; se repitió la preparación con red habilitada y terminó correctamente. La última composición con caché preparada tomó aproximadamente 4,0 s en esta prueba.

## Verificación interactiva

Se abrió la app empaquetada y se inspeccionó su árbol AX y la ventana real. Se comprobó el esquema de títulos, la firma del autor, el enlace Ko-fi, el editor, los modos páginas/continuo y la configuración de apariencia.

Se alternaron 20 veces los dos modos: contenido de 129 palabras conservado. Una sustitución posterior afectó al título que estaba seleccionado antes de alternar, verificando conservación de selección. Deshacer restauró el original. El guardado nativo creó `docs/examples/El oficio de escribir.nab` y la barra indicó «Guardado».

Las capturas claro/oscuro están en `.impeccable/review/` y se copian a `editor-claro.png` y `editor-oscuro.png`. Son capturas de la app, no maquetas. El capturador nativo puede representar SF Symbols de sidebar de forma diferente al compositor en pantalla; ese alcance se entrega al revisor independiente.

Hubo fallos de la conexión de automatización después de cerrar diálogos; una muestra del proceso mostró el hilo principal esperando eventos y no un bloqueo de la app. El proceso se reabrió con el script de desarrollo para continuar la inspección. No se presenta esa herramienta como auditoría completa con VoiceOver.

## Medidas

Documento sintético de 3.000 párrafos / 150.000 palabras: compresión y reapertura verificadas en ~0,067 s en la última ejecución del test; archivo de 87.296 bytes. El tiempo excluye construcción previa del modelo y no mide latencia de tecleo. La prueba completa, con conteo y comparación, tomó ~0,23 s.

Una muestra de proceso después de guardar mostró huella física de 60,8 MB y pico de 112 MB durante esa sesión. El hilo principal estaba inactivo esperando eventos. Es un escenario corto de desarrollo, no una medición completa de batería, memoria con imágenes grandes o escritura extensa. Evidencia: `performance-sample.txt`.

## Pendiente

La cobertura crítica no certifica todos los requisitos P0. Faltan auditoría completa con VoiceOver, navegación y desbordes con todas las variantes de objetos, estrés sostenido de tecleo, revisión óptica completa de Finder/Dock y compatibilidad avanzada de plantillas. Ver STATUS.md y LIMITATIONS.md.

## Comprobación posterior a la revisión visual

El revisor independiente pidió dos correcciones: hit areas de navegación de ancho completo y selector de zoom compacto. Ambas se aplicaron en un lote y se recompiló la app. El clic de la fila Inicio pasó a abrir Inicio; desde allí «Abrir» releyó el .nab guardado y mostró sus títulos, viñeta y 129 palabras con estado Guardado. Se recapturaron las dos apariencias. Esta verificación de correcciones no sustituye la auditoría completa de accesibilidad ni implica cierre del P0.

El pase de veredicto independiente marcó ambas correcciones como resueltas (`ship` limitado a esos dos hallazgos). Informe completo: `.impeccable/review/finish-review.md`. No se interpreta como certificación de toda la superficie o del P0.

Tras añadir esas dos regresiones funcionales se ejecutó de nuevo la batería completa: 17 pruebas de core y 5 de app, todas correctas. La batería final volvió a pasar después del ajuste del selector de apertura descrito a continuación.

## Apertura y empaquetado final

Se presentó el selector de documentos con `beginSheetModal`/`begin`, sin un bucle modal anidado, manteniendo una única instancia activa. El filtro habilita directorios y archivos `.nab` aunque Launch Services esté actualizando la ubicación del bundle. Desde la instalación en `~/Applications/Naberius.app`, la selección y apertura nativas de `docs/examples/El oficio de escribir.nab` mostraron el editor con sus tres títulos de sección, viñeta, 129 palabras y estado Guardado. Esta vez la inspección AX continuó correctamente después de cerrar el selector. Se reabrió con ⌘O y se canceló: el documento conservó sus 129 palabras y el estado Guardado.

La carpeta Escritorio recibe metadatos del proveedor de archivos que invalidan la verificación estricta de un bundle suelto. El empaquetador firma en una carpeta temporal, crea `dist/Naberius.zip` y coloca la copia ejecutable en `~/Applications`; el acceso de la raíz apunta a ella. Se verificaron la firma ad-hoc de esa copia y la de una extracción nueva del ZIP con `codesign --verify --deep --strict`. No se entrega un bundle suelto en `dist`. Resultado de compilación: `build-results.txt`. No hay remotos Git configurados ni se publicó contenido.

## Revisión 0.2.0 — 30 de octubre de 2026

Se releyó la especificación completa y se corrigió la desconexión entre el editor y el motor. La batería final (`test-results-0.2.0.txt`) pasó: 29 pruebas de core y 11 de app, **40 en total**, además de variantes parametrizadas. Incluye:

- Las seis plantillas compuestas realmente por Tectonic, con sus clases article/report/book/letter, cabeceras, pies, anexos, tabla y ecuación.
- Los mismos cuatro OTF Latin Modern en el editor y en el proyecto exportado, con licencia.
- Conservación del texto original y del glifo A del logotipo; guardado de documentos antiguos sin layout.
- Fórmula recortada desde PDF real, sin modificar el documento fuente.
- Copiado de objetos, assets y citas a otro documento, reconexión de destinos y rechazo de UUID ambiguos.
- Bloqueo por propiedades y estado intacto después de un proceso de composición fallido.
- Protección de formato e inserción sobre el editor oculto durante la prueba PDF.
- Ediciones de párrafo central, inserción multilínea, final vacío, listas y UUID estables.

Evidencia tipográfica exportada en `typesetting/`: seis PDF, sus .tex, fuentes/licencias y registros. Se inspeccionaron las renderizaciones del artículo y la fracción; se extrajeron de los diccionarios internos del PDF LMRoman10-Regular/Bold y las familias matemáticas Computer Modern. Los atributos que PDFKit reconstruye para selección textual no se usaron como prueba de la fuente incrustada.

### Escritura extensa

En este M1/8GB y compilación Debug, 40 inserciones nativas sobre 1.000 párrafos / 51.000 palabras tardaron inicialmente 4,3655 s. La proyección se cambió al párrafo afectado en ediciones simples, conservando el recorrido completo para cambios estructurales. Tras corregir el caso de lista/final vacío, la medición de regresión fue 0,0522 s; en la batería final concurrente fue 0,0798 s. El contenido y los 1.000 UUID permanecieron iguales fuera del párrafo editado. Son mediciones de proyección nativa/modelo con NSTextView sin una ventana de escritura sostenida; excluyen duración del diario asíncrono, latencia de pantalla y energía. No se presentan como una garantía general.

### Ventana real

Se abrió el .nab nuevo con Latin Modern, portada de texto, tres títulos y anexo. Se compuso desde la app en ~1,7 s; el árbol AX expuso texto, tabla, raíz y número de página del PDF real. Una tecla ordinaria en la prueba no editó el documento. Al cambiar «conservan» por «mantienen» y volver a prueba se mostró que el PDF estaba desactualizado. Deshacer devolvió el original y las 138 palabras.

La selección de ecuación por teclado abrió sus propiedades; «Componer con LaTeX» mostró la raíz con griegas y trazo TeX tanto en el lienzo como en el inspector. Se inspeccionó la apariencia oscura. El revisor detectó una captura clara con el inspector sin trazo; se añadió representación de plantilla SwiftUI para teñir desde el entorno. También se separó el zoom PDF y se protegieron controles/comandos de edición durante la prueba. Confirmación visual final realizada en el binario instalado: raíz visible también en claro, zoom PDF al 125 %, toolbar de formato ausente y ⌘B/⌘I/x sin cambios de contenido ni guardado. El esquema sale de prueba antes de enfocar un título; una regresión adicional verifica esa guarda. La inspección AX y las capturas no certifican la auditoría completa con VoiceOver.

El revisor independiente cerró los tres hallazgos: contraste del inspector, protección de la selección oculta y zoom independiente. Su `ship` está limitado a ese lote. Las capturas de chrome PDF omiten sus mosaicos internos por una limitación de NSView.cacheDisplay; el contenido sí se vio mediante la captura nativa de CUA. No se interpreta una captura blanca de ese helper como fallo del PDF ni como evidencia de su contenido. Ver `typesetting/finish-review-0.2.0.md`.

## Validación 0.3.0 — 30 de octubre de 2026

La batería con `NABERIUS_COMPOSE=1` pasó 37 pruebas del núcleo y 13 de la app. Se verificaron las seis plantillas, fórmulas reales y tablas de 90 filas en artículo, informe, libro y carta, con encabezado repetido, última fila presente y sin avisos Overfull hbox en esos casos. Las cuatro salidas están en `tables/`; la primera página de article se inspeccionó renderizada.

Después de las correcciones de ventana/hojas se pasó la suite ordinaria completa: 37 pruebas del núcleo y 14 de la app, incluida la nueva selección de registros. Esa ejecución omite integraciones externas cuando no se activa NABERIUS_COMPOSE; la integración LaTeX anterior corresponde al mismo código de composición. Una ejecución adicional dirigida verificó tabla y tipografía tras el ajuste de encuadre. No hubo errores ni avisos del compilador en las ejecuciones finales.

Prueba manual sobre una copia sintética: doble clic abre la cuadrícula en el documento; Tab permite cambiar de celda, escribir y añadir una fila al final; Esc termina y guardar conserva las tres filas. Se confirmó el fondo adaptativo y el encuadre completo, incluida la ayuda inferior, en ambas apariencias. `screenshots/table-{light,dark}.png` son capturas del binario instalado. El árbol AX no expone todos los campos de la cuadrícula interna de NSTextView; la accesibilidad integral sigue pendiente por alcance.

La importación de BibLaTeX mostró dos registros, cuatro advertencias, preámbulo omitido, campos usera/howpublished y comando no interpretado; la selección de un registro importó solo ese registro. En la confirmación final el selector quedó asociado a la hoja de biblioteca, el informe permaneció abierto sin importar automáticamente y «Cancelar» volvió a biblioteca sin añadir entradas. Se confirmó «Importar 1 registro». Las capturas de biblioteca son del informe final, sin datos privados.

La apertura externa de .nab conserva la ventana `main` única. Se verificaron 534 claves de catálogo español incluidas en el recurso empaquetado y los formatos dinámicos. El catálogo antiguo se retiró. El icono exportado se inspeccionó a 256 y 1024; `screenshots/system-app-icon.png` procede de NSWorkspace.icon(forFile:) sobre el bundle instalado, que comprueba el recurso que resuelve macOS. El intento de captura directa del Dock agotó el tiempo de la herramienta; no se presenta como una captura visual del Dock.

El ZIP y la app llevan licencia, copyright, avisos y ruta al código fuente. Firma ad hoc y verificación estricta del bundle, incluida extracción del ZIP; sin notarización. Esta validación no certifica todo P0 ni accesibilidad completa.

## Validación 0.4.0 — 31 de octubre de 2026

La batería completa con SwiftPM clásico y `NABERIUS_COMPOSE=1` pasó 65 pruebas en 26 suites, incluyendo el ZIP Springer recibido mediante `NABERIUS_TEMPLATE_FIXTURE`. Se comprobaron clases de nombres arbitrarios, ZIP con recursos binarios, selección de otra entrada, conservación en `.nab`, copia original en la exportación, edición escapada de metadatos estructurados, título/propiedades/deshacer y tablas de 90 filas en una clase de dos columnas. Se rechazaron rutas ascendentes, absolutas, ambiguas, symlinks, expansión excesiva e índice truncado; el perfil permitió leer un archivo propio del área de trabajo y bloqueó un archivo de prueba situado fuera de ella.

El PDF real de `sn-jnl` incluyó título nuevo, autores/afiliaciones de muestra del paquete, cita numérica resuelta, referencia sintética, fracción y tabla. Su primera página se inspeccionó renderizada. Esta evidencia acredita ese paquete y las clases sintéticas probadas, no compatibilidad con todos los paquetes TeX. Los archivos originales del editor científico permanecen locales y no se redistribuyen en el repositorio.

La revisión de interfaz de 0.4.0 queda diferida por el usuario hasta disponer de la pantalla. Se instalaron y verificaron los bundles locales y el paquete adjunto; el ejemplo español guardado/reabierto y su PDF también se compusieron sin conexión tras preparar la caché de fuentes. No se presenta como verificación del flujo gráfico.

## Revisión de interfaz 0.4.1 — 31 de octubre de 2026

Se importó el ZIP desde el panel de archivos de la app. El catálogo confirmó `sn-jnl`, sus opciones, 16 archivos y nueve BST, sin duplicar la plantilla existente. Se creó un documento y se editaron título, autor y resumen; el documento y las propiedades conservaron los valores Unicode. La primera copia se guardó mediante el panel nativo.

La prueba encontró tres ajustes de uso: llevar al frente el documento creado desde Configuración, mantener visibles las etiquetas de los campos editoriales y conservar Párrafo en la línea vacía posterior a un título. Las correcciones se comprobaron en la app instalada: el documento aparece directamente, las etiquetas se ven junto a sus valores y el texto nuevo no se incorpora al esquema como título.

Una composición sin red informó una métrica de fuente todavía no almacenada (`cmbx9`). Se corrigió el diagnóstico para indicar la preparación desde Configuración → Composición. Al activar allí la descarga explícita, el motor generó el PDF. La inspección final del PDF en la ventana y el guardado de la segunda copia quedaron interrumpidos al bloquearse otra vez el Mac; no se declaran completados. La evidencia con recursos editoriales se conserva localmente y no se redistribuye.

La batería completa pasó 67 pruebas con LaTeX real. Incluye regresiones de identidad/estilo del párrafo final y distinción entre una fuente ausente en caché y un error de sintaxis. La muestra del proceso durante los timeouts de control mostró el hilo principal en su bucle de eventos normal; no se atribuyeron esos timeouts a un bloqueo de Naberius.

### Cierre de la prueba visual

Con la pantalla disponible se completó la revisión del visor en 0.4.1. Un documento nuevo con título, resumen, autor acentuado y texto de cuerpo produjo un PDF de una página con la clase editorial, en 0,8 segundos. Se guardó el `.nab` por el panel nativo, se reabrió desde Finder y se confirmaron los mismos datos, plantilla y estado Guardado. La recomposición tras reabrir tardó 0,9 segundos; el registro confirmó uso exclusivo de caché local. El cuerpo permaneció en Párrafo y el esquema solo conservó Introduction. Se comprobaron zoom 125 % y ajuste a ventana. Los documentos y PDF de evidencia siguen siendo locales. Las cifras describen esas dos composiciones Debug y no se presentan como garantía de rendimiento general.

Esto cierra el visor y la reapertura que se habían documentado como interrumpidos. No certifica todas las combinaciones de paquetes editoriales ni la auditoría de accesibilidad aplazada por el usuario.


## Validación 0.5.0

85 pruebas pasan con integración real de Tectonic; 85 pasan también con el backend SwiftPM nativo. Se verifican pausa y coalescencia de ediciones, cancelación, modo manual, actividad de ventana, error automático sin alerta, aislamiento entre documentos y PDF desactualizado. Los nuevos datos de columnas y márgenes sobreviven a `.nab` schema 3. Un documento de dos columnas con márgenes asimétricos y tabla de 90 filas compone todas las filas. Se acota la retención a dos pruebas PDF por sesión y se eliminan trabajos temporales fallidos. El test de limpieza comprueba que no se borran temporales ajenos.

Los cuatro ZIP aportados se analizaron y tres produjeron PDF real con contenido nativo, cita, referencia, ecuación y tabla. IEEE se recompuso después de corregir la codificación de fuentes; la inspección del PDF confirma Nimbus Roman en lugar del reemplazo Latin Modern. CJS falla por ausencia de su clase; su diagnóstico no se presenta como compatibilidad completa. Los paquetes y resultados locales permanecen fuera de Git.

Se comprobaron las tres vistas en claro y oscuro en la ventana del usuario (1800 × 1159), importación de los cuatro ZIP, variante libre CJS, guardado/reapertura, actualización tras una pausa conservando foco y cursor, interruptor automático y atajo manual ⇧⌘R. Se corrigieron el filtro nativo de archivos, el ancho del menú de apariencia y el ajuste del PDF a la página completa. El test de PDFKit cubre ajuste completo y zoom manual.

La revisión independiente validó estas capturas y pidió equilibrar el reparto al entrar a Editor + PDF. La corrección conserva el NSTextView y la proporción elegida al arrastrar el divisor; una prueba AppKit verifica inicio equilibrado, ajuste manual y alternancia. Su recaptura posterior sigue pendiente porque el Mac volvió a bloquearse. El mínimo de 940 pt y la accesibilidad integral no están certificados visualmente. No se ha publicado 0.5.0 ni actualizado su release en GitHub.
