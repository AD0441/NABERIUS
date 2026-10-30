# Composición tipográfica — 0.2.0

La revisión de los requisitos ED-01/06, EQ-01, PL-02, EST-01 y EXP-01/07/10 encontró una desconexión: el editor inicial usaba títulos de sistema y Times New Roman, mientras que el PDF se generaba mediante Tectonic. La presencia de un motor real no bastaba para ofrecer una experiencia tipográfica coherente.

## Texto y fuentes

Las nuevas plantillas usan **Latin Modern Roman**, derivada de Computer Modern. Los cuatro estilos originales se incluyen sin modificar, bajo GUST Font License, con README y manifiesto. Procedencia: [CTAN, paquete Latin Modern](https://ctan.org/tex-archive/fonts/lm). La interfaz de navegación conserva la tipografía nativa de macOS; títulos y cuerpo del documento usan la familia documental.

CoreText registra las fuentes únicamente para el proceso. El proyecto LaTeX exportado incluye esos mismos archivos en `fonts/` y `fontspec` los carga por nombre de archivo, sin depender de una instalación global. Referencia de la selección de fuentes: [documentación oficial de fontspec](https://latex3.github.io/fontspec/).

Los documentos anteriores mantienen su familia guardada. En Propiedades → Diseño se puede elegir Latin Modern o pulsar «Usar tipografía LaTeX»; no se cambia silenciosamente el formato de archivos existentes.

## LaTeX y TeX

Los nombres LaTeX, Latex, LATEX y TeX se representan tipográficamente cuando son palabras independientes. El generador emite `\LaTeX{}` y `\TeX{}`. En el editor se usan métricas, kerning y sustitución de glifos de TextKit; los caracteres originales, la selección UTF-16 y el texto copiado permanecen intactos. El resaltado o estilos distintos entre partes de una palabra se respetan.

## Prueba del documento

«PDF LaTeX» abre la composición real en el espacio de trabajo. No es una captura del editor. Se conservan la instancia del editor, su selección y deshacer al volver a escribir. La prueba muestra motor, duración y hora; permite navegar páginas, guardar el PDF y leer el registro de composición. Tras editar, se informa que el PDF quedó desactualizado. «Actualizar PDF» ejecuta Tectonic fuera del actor principal; no se compila por tecla.

El modo Páginas del editor continúa siendo orientativo, tal como exige ED-06. Incluye desplazamiento por páginas ajustado al papel. El PDF determina cortes, composición matemática, ligaduras e hifenación. Tectonic utiliza XeTeX: [documentación oficial](https://tectonic-typesetting.github.io/book/latest/getting-started/unicode.html).

## Matemáticas

El inspector permite editar fracción, raíz, exponente, subíndice, sumatoria, integral y símbolos sin escribir comandos. «Componer con LaTeX» produce una fórmula con Tectonic y recorta su PDF para mostrarla tanto en el inspector como dentro del documento. La caché es local y limitada a 32 expresiones; se invalida por expresión y no forma parte del archivo maestro. Mientras no se compone, la vista se identifica como estructura aproximada. El PDF completo siempre utiliza matemáticas LaTeX.

## Evidencia

En `docs/typesetting/` hay PDF reales de las seis plantillas, sus `.tex`, fuentes, licencias y registros. `article-page-1.png` y `equation.png` son renderizaciones de esos PDF, no maquetas de la app. `embedded-fonts.txt` registra nombres incrustados obtenidos de los diccionarios internos del PDF; los atributos reconstruidos por PDFKit no se utilizan para identificar la fuente incrustada.

La batería de 40 pruebas incluye compilación real de los seis formatos, ecuación recortada, glifo A del logotipo sin cambiar el texto, compatibilidad de archivos anteriores y preservación del documento ante un fallo del motor. Se verificó la ventana 0.2.0 después de desbloquear el Mac: Latin Modern, logotipos, PDF real desde la app, aviso al editar y raíz matemática de Tectonic en lienzo e inspector. Las capturas anteriores a 0.2.0 se conservan como evidencia histórica. Se confirmó el lote final: raíz visible en inspector y lienzo en claro/oscuro, atajos protegidos en prueba y zoom PDF al 125 %. El revisor cerró los tres hallazgos del lote; el alcance no certifica todo P0.

Las capturas de desarrollo `proof-light.png` y `proof-dark.png` muestran los controles pero omiten la capa de mosaicos de PDFKit al usar NSView.cacheDisplay. No se usan para demostrar contenido. El PDF fue visible en la captura nativa CUA; los archivos article.pdf y article-page-1.png documentan la composición. Las capturas equation-editor-light/dark sí muestran el contenido nativo y el inspector.
