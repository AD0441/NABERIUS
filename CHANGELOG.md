# Cambios

## 0.3.0 — 2026-10-30

- Sello minimalista: un asta, dos barras y una curva abierta; recursos con ajuste óptico por tamaño.
- Tablas editables en el documento, Tab/⇧Tab/Intro/Esc, desplazamiento y deshacer por celda. Vista abreviada sin pérdida de filas; longtable con encabezados repetidos en PDF.
- Importación bibliográfica revisable: @string, concatenación, herencia, nombres y acentos; preservación de originales y campos adicionales, con advertencias explícitas.
- Catálogo español externo compartido por interfaz y núcleo; licencias incluidas en la app.
- Preparación de publicación AGPL-3.0-or-later siguiendo las convenciones de main de la familia.


## 0.2.0 — 30 de octubre de 2026

Revisión de la conexión entre escritura visual y composición LaTeX a partir de los requisitos originales.

- Latin Modern Roman incluida y compartida por TextKit y fontspec; títulos documentales en la misma familia.
- Logotipos LaTeX/TeX tipográficos sin alterar texto, selección ni portapapeles.
- PDF del motor dentro del espacio de trabajo, revisión explícita, estado desactualizado, navegación, zoom y registro.
- Fórmulas visuales compuestas con Tectonic para inspector y lienzo.
- Clases reales de artículo, informe, tesis, libro y carta; cabeceras, pies, sangría, anexos y separadores.
- Tres estilos distintos de tabla en LaTeX, copiado portable con dependencias y controles de plantilla protegidos.
- Mapeo seguro de clases, márgenes, fuentes y dependencias de plantillas externas; activación predeterminada.
- Ediciones simples proyectadas solo al párrafo afectado; regresiones de listas, párrafos y protección de la prueba PDF.

## 0.1.0 — 30 de octubre de 2026

Primera implementación local de Naberius para macOS y Apple Silicon. Editor semántico nativo, inicio y recientes, plantillas, biblioteca local y del documento, citas CSL, objetos académicos con inspector, búsqueda/reemplazo, guardado .nab comprimido y atómico, diario de recuperación, exportación LaTeX y PDF con Tectonic. Identidad geométrica original dentro de la familia METATRON, firma del autor y Ko-fi bajo interacción explícita.

Versión de desarrollo sin publicación en GitHub. Ver docs/LIMITATIONS.md y docs/STATUS.md para las capacidades todavía parciales.

- Apertura de documentos mediante panel nativo no bloqueante y filtro por extensión resistente a cambios de ubicación.
- Instalación local en `~/Applications`, acceso desde la raíz del proyecto y ZIP firmado verificado, evitando metadatos de sincronización del Escritorio.
