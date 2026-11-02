# Revisión de requisitos y bases de GitHub

**Fecha:** 1 de noviembre de 2026. **Versión revisada:** Naberius 0.5.0, código en `f6bb712afb60035837653adedc51268974569dc5`.

**Seguimiento 0.6.0:** la implementación posterior corrige las citas narrativas, incorpora pegado TSV en tablas y añade las listas de figuras y tablas. Las observaciones y el CSV siguientes conservan el estado histórico de 0.5.0; el estado actual está en [STATUS](STATUS.md) y la validación en [TESTING](TESTING.md). Las demás bibliotecas de esta revisión siguen siendo candidatas.


La recomendación es conservar el editor nativo y el formato `.nab`, corregir primero las citas narrativas y ampliar capacidades mediante componentes concretos. Pandoc, SyncTeX, bibliotecas matemáticas y el parser de Better BibTeX ofrecen puntos de apoyo; ninguno sustituye por sí solo el modelo semántico y las pruebas de Naberius.

## Alcance y evidencia

Se revisaron los **175 requisitos identificados**: 141 P0, 29 P1 y 5 P2. Las decisiones D-01–D-10 y los 15 casos AC son referencias adicionales, no se suman a ese conteo. El [CSV completo](REQUIREMENTS_REVIEW.csv) conserva todos los códigos, texto, estado anterior, evaluación y acción propuesta.

La copia `docs/REQUIREMENTS.md` es idéntica al archivo original entregado: SHA-256 `3cc766ae9e8691711a6084f823666fb6220068a733218036e7fe88373472d273`. Se trató como especificación de producto; este encargo autoriza revisar y buscar soluciones, no incorporar todavía todas las dependencias.

La matriz de entrada declaraba 128 P0 implementados y 13 parciales, con los 34 P1/P2 pendientes. Eso **no equivalía a 128 requisitos certificados**. Había funciones posteriores a 0.3.0 sin reflejar y partes de requisitos compuestos ya presentes.

La revisión es documental y estática, con una prueba específica de citas. Las 86 pruebas y la evidencia visual de 0.5.0 se consultaron en [TESTING](TESTING.md); no se volvió a ejecutar toda la batería ni se validaron las bibliotecas candidatas dentro de la app. Las licencias se leyeron en sus fuentes actuales. Los repositorios evaluados como candidatos en este informe no figuraban archivados; eso no prueba estabilidad, seguridad ni rendimiento de cada versión.

## Hallazgos que cambian la lista de trabajo

| Requisitos | Evaluación |
| --- | --- |
| **CIT-02, CIT-06** | Citas narrativas con varios autores requieren corrección. El código añade manualmente el primer apellido al resultado sin autor; así no delega íntegramente los nombres al estilo CSL. |
| **TAB-07** | Parcial: ya existen tablas extensas en PDF y encabezados repetidos. Faltan celdas combinadas y cubrir variantes complejas; no debe figurar todo como pendiente. |
| **INS-02** | Parcial: índice de contenido y anexos presentes; faltan listas específicas de figuras y tablas. |
| **TXT-08** | Parcial: palabras y páginas PDF ya se muestran; faltan caracteres y estadísticas de avance completas. |
| **EST-06** | Parcial: hay duplicación y personalización de plantillas; falta un intercambio dedicado de plantillas personales. |
| **VIS-14** | La documentación de marca, fuentes editables del icono, procedimiento de la portada y avisos existen. El rótulo pendiente quedó obsoleto. |
| **DOC-02 / EST-01** | Los márgenes por lado y dos columnas llegaron en 0.5.0. La limitación que decía que faltaban márgenes asimétricos estaba desactualizada. |
| **PL-05, PL-06** | Hay que distinguir el mapeo de archivos individuales del ZIP que conserva y compone la clase original. El análisis no ejecuta el paquete; la composición sí interpreta TeX dentro de los límites existentes. |
| **INI-08** | Pendiente real: `NaberiusApp` mantiene una única `Session` y una ventana principal. Ventanas independientes requieren aislar documento, deshacer, recuperación y PDF. |
| **EQ-05, EQ-06** | Pendientes reales: `MathExpression` representa una operación con campos de texto; no es un árbol de expresiones anidadas ni una matriz editable. |
| **EXP-04, EXP-05; CIT-07; REF-09** | DOCX/Markdown, estilos CSL personales y búsqueda de metadata en línea siguen pendientes. |
| **UI-09, CAL-05 y auditorías relacionadas** | Se mantienen como pendientes/parciales. Su implementación integral continúa aplazada por la decisión del usuario; no bloquea esta investigación. |

Se actualizaron las descripciones inequívocamente desfasadas de [STATUS](STATUS.md) y [LIMITATIONS](LIMITATIONS.md). La línea base original no se modificó.

El enlace VIS-12 del original usa otro alias de Ko-fi. Se conserva el destino posteriormente comprobado en la familia y usado en la app, https://ko-fi.com/C0C51WQ1T0, de acuerdo con la instrucción del autor de mantener la identidad de sus aplicaciones.

### Cita narrativa: diagnóstico reproducido

En [Bibliography.swift](../Sources/NaberiusCore/Bibliography.swift), la rama narrativa toma `authors.components(separatedBy:";").first`. Para un artículo sintético con Pérez, Gómez y Rojas, la misma lógica y el motor local produjeron:

```text
Lógica actual de Naberius: Pérez (2024)
Motor CSL author-only:   Pérez et al.
Nombre calculado por CSL + año: Pérez et al. (2024)
```

Es una reproducción del algoritmo de 0.5.0 con sus recursos reales, no una prueba de interfaz. El [reproductor histórico](research/citation-narrative-0.5.swift) y su [salida](research/citation-narrative-0.5.txt) quedan guardados.

La [documentación de citeproc-js](https://citeproc-js.readthedocs.io/en/latest/running.html#special-citation-forms) distingue `author-only`, `suppress-author` y `composite`. `makeCitationCluster` no aplica `composite`; conviene estudiar `processCitationCluster` para el contexto completo. Los [fixtures del proyecto](https://github.com/Juris-M/citeproc-js/tree/master/fixtures/local) permiten contrastar resultados. La primera corrección debe cubrir varios autores, instituciones, fuentes sin autor, estilos numéricos y localización. **No basta con añadir “et al.” manualmente.**

## Bases de GitHub y forma de aprovecharlas

### Componentes con encaje concreto

| Base y licencia consultada | Requisitos | Uso propuesto | Coste o límite principal |
| --- | --- | --- | --- |
| [Pandoc](https://github.com/jgm/pandoc) · [GPL-2.0-or-later](https://github.com/jgm/pandoc/blob/main/pandoc.cabal) | EXP-04/05, OBJ-06 | Proceso externo opcional para DOCX y Markdown, alimentado desde el documento semántico. | Requiere un adaptador y pruebas de pérdidas; convertir el TeX editorial directamente no garantiza recuperar su estructura. |
| [SyncTeX](https://github.com/jlaurens/synctex) · [MIT](https://github.com/jlaurens/synctex/blob/main/LICENSE) | ED-05, EXP-07; mejora de la vista combinada | Relacionar posiciones de PDF y fuente generada; después enlazarlas a UUID de bloques. | No vuelve editable al PDF. Hay que crear el mapa UUID–archivo–línea y asociarlo a la revisión exacta de la composición. |
| [MathLive](https://github.com/arnog/mathlive) · [MIT](https://github.com/arnog/mathlive/blob/master/LICENSE.txt) | EQ-01/03/05/06 | Prototipo de edición visual especializada, estructuras y matrices en una vista local aislada. | Es un componente web: necesita WKWebView, bridge y recursos empaquetados. No es una dependencia Swift que se añada sin cambios de arquitectura. |
| [SwiftMath](https://github.com/mgriebling/SwiftMath) · [MIT](https://github.com/mgriebling/SwiftMath/blob/main/LICENSE) | EQ-01/05; previsualización | Alternativa nativa para dibujar fórmulas con CoreText/CoreGraphics. Su manifiesto declara macOS 12+, dentro del mínimo de Naberius. | Es un renderizador, no un editor visual completo ni un motor de documentos LaTeX. Sus fuentes conservan licencias [GUST](https://github.com/mgriebling/SwiftMath/blob/main/Sources/SwiftMath/mathFonts.bundle/GUST-FONT-LICENSE.txt) y [OFL](https://github.com/mgriebling/SwiftMath/blob/main/Sources/SwiftMath/mathFonts.bundle/OFL.txt). |
| [prosemirror-tables](https://github.com/ProseMirror/prosemirror-tables) · [MIT](https://github.com/ProseMirror/prosemirror-tables/blob/master/LICENSE) | TAB-06/07 | Referencia de mapa de celdas, selección rectangular, pegado y reglas de combinación. Adaptar esos conceptos a Swift y al editor nativo. | No se puede insertar directamente en NSTableView. El modelo actual `[[String]]` necesita evolucionar para rowspan/colspan. |
| [bibtex-parser de Better BibTeX](https://github.com/retorquere/bibtex-parser) · [MIT](https://github.com/retorquere/bibtex-parser/blob/master/LICENSE) | REF-08 | Contrastar el parser propio con un parser especializado y sus casos; evaluar `parseVerbatim` y conservación de campos. | El paquete actual usa WASM por defecto y ofrece una entrada TypeScript/JS `/js`. La integración con JavaScriptCore debe validarse; no se ha probado como reemplazo. |
| [GRDB.swift](https://github.com/groue/GRDB.swift) · [MIT](https://github.com/groue/GRDB.swift/blob/master/LICENSE) | REF-06, PRO-01/04, BUS-06, GUA-07 | SQLite local para colecciones, índices y metadata de proyectos cuando crezca la biblioteca. | No sustituir el contenedor portable `.nab`. Migrar la biblioteca JSON actual conservando IDs y sin actualizar documentos automáticamente. |
| [Estilos CSL](https://github.com/citation-style-language/styles) · [CC BY-SA 3.0](https://github.com/citation-style-language/styles#licensing) | CIT-07 | Importar estilos personales sobre el citeproc-js existente; preservar autoría, versión y dependencias. | Resolver estilos dependientes y locales sin red implícita. Un archivo CSL configura citas, no la clase editorial de la revista. |

Las capacidades de cada proyecto se comprobaron en README, API o código. La selección anterior es una propuesta de integración; no afirma que los componentes hayan pasado pruebas de Naberius.

### Referencias de implementación

- **[LaTeX Workshop](https://github.com/James-Yu/LaTeX-Workshop)**, [MIT](https://github.com/James-Yu/LaTeX-Workshop/blob/master/LICENSE.txt): su organización de recetas, errores y sincronización sirve para ampliar la capa de composición. Adaptar la coordinación; no incorporar VS Code ni su extensión como runtime.
- **[CotEditor](https://github.com/CotEditor/CotEditor)**: referencia nativa para documentos, búsqueda y ventanas. Su [código es Apache-2.0 y sus imágenes tienen una licencia diferente](https://github.com/CotEditor/CotEditor/blob/main/LICENSE). El [main declara macOS 26+](https://github.com/CotEditor/CotEditor/blob/main/README.md), por lo que cualquier adaptación debe respetar nuestro mínimo macOS 14. No se propone reutilizar sus imágenes.
- **[Zotero](https://github.com/zotero/zotero)**: la [API local](https://github.com/zotero/zotero/blob/main/chrome/content/zotero/xpcom/server/server_localAPI.js) ofrece una ruta opcional para CIT-08. Preferir importar una copia de los registros mediante interfaz local; no leer directamente su SQLite ni incorporar su aplicación. El [código de Zotero es AGPLv3](https://github.com/zotero/zotero/blob/main/COPYING). La integración permanece P2 y requiere activación explícita.
- **[Tectonic](https://github.com/tectonic-typesetting/tectonic)** ya es la base de composición. Su [CLI documenta `--synctex`](https://github.com/tectonic-typesetting/tectonic/blob/master/docs/src/ref/v1cli.md). Naberius todavía no lo solicita ni consume esos datos. El motor conserva [MIT y las licencias de sus componentes](https://github.com/tectonic-typesetting/tectonic/blob/master/LICENSE).

### Opciones que no adoptaría ahora

| Opción | Motivo |
| --- | --- |
| [STTextView](https://github.com/krzyzanowskim/STTextView) | TextKit 2 y macOS 14 son relevantes, pero está orientado principalmente a edición de código. Su [licencia actual es GPLv3 u opción comercial](https://github.com/krzyzanowskim/STTextView/blob/main/LICENSE.md), no debe asumirse MIT por referencias antiguas. Reemplazar el editor exige volver a validar adjuntos, tablas, selección y deshacer. |
| [Citation.js](https://github.com/citation-js/citation-js) | [MIT](https://github.com/citation-js/citation-js/blob/main/LICENSE.md), modular y útil para formatos bibliográficos. Lo conservaría como alternativa de contraste, evitando duplicar ahora el renderizador CSL que ya funciona. |
| [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX) | Su [README](https://github.com/SwiftLaTeX/SwiftLaTeX/blob/master/README.md) lo describe como motores WebAssembly para navegador, licencia AGPLv3 y edición WYSIWYG del PDF en desarrollo. Su nombre no significa que sea una biblioteca Swift nativa ni una solución lista para editar cualquier PDF. |
| Reemplazar todo el editor por ProseMirror/Tiptap | Puede resolver partes de edición web, pero rehace el puente del documento, adjuntos, historial y superficie nativa. Las tablas de ProseMirror son una referencia útil sin exigir esa migración. |

## Diseño de integración propuesto

1. **Conservar** NabDocument, UUID, guardado atómico, recuperación, editor nativo, PDFKit, Tectonic y citeproc-js.
2. **Exportación:** crear `NabDocument → Pandoc AST JSON → DOCX/Markdown`. Enumerar qué ocurre con citas, ecuaciones, notas, tablas, figuras y referencias cruzadas. No prometer campos dinámicos de Zotero/Word ni maquetación idéntica al PDF.
3. **Matemáticas:** distinguir entrada visual, representación persistente y dibujo. Para anidación y matrices, diseñar un árbol versionado compatible con documentos anteriores. Comparar una prueba nativa con SwiftMath y un MathLive local aislado; el PDF de Tectonic sigue siendo la referencia final.
4. **Tablas:** añadir pegado TSV/HTML tabular primero. Para combinar celdas, introducir un mapa de ocupación y spans con invariantes, migración y transacciones de deshacer. Conservar el PDF multipágina ya implementado.
5. **PDF sincronizado:** conservar el `.synctex.gz` y un mapa de bloques por composición. Un clic en PDF desactualizado debe usar su revisión o advertir, nunca saltar usando el mapa de otra revisión.
6. **Paquetes editoriales:** evaluar backends externos detectados de TeX Live/MacTeX y recetas con LuaLaTeX/Biber, manteniendo argumentos fijos, cancelación y límites de acceso. No instalar automáticamente ni habilitar shell-escape. Un archivo de clase ausente en el ZIP, como en el CJS probado, debe seguir diagnosticándose como ausente.
7. **Biblioteca y ventanas:** cada documento debe tener Session, UndoManager y estado de PDF propios; compartir solo biblioteca/configuración. GRDB sería un almacenamiento de metadata local, no una dependencia del archivo portable.

Las propuestas 3, 4 y 5 necesitan trabajo en el modelo o mapas del documento; añadir una biblioteca no las completa automáticamente.

## Orden recomendado y pruebas para aceptar cada lote

| Orden | Entrega | Criterio concreto |
| --- | --- | --- |
| **1** | Citas narrativas y lista de pendientes coherente | APA con uno, dos y tres autores; institución y autor ausente; numeración/idioma; resultado calculado por CSL y deshacer/guardar intactos. |
| **2** | Mejoras sobre la base nativa: TSV, listas de figuras/tablas, CSL personal y reorganización de secciones | Pegado desde Numbers/Excel conservando filas/celdas; una transacción de deshacer; destinos UUID conservados tras mover secciones; estilo inválido rechazado sin alterar el documento. |
| **3** | Prototipos de matemáticas y SyncTeX | Fórmula anidada y matriz editable guardadas/reabiertas; ida y vuelta editor/PDF tras recomponer y con plantilla ZIP; medir latencia y memoria en M1/8 GB. |
| **4** | DOCX y Markdown con Pandoc | Fixture con títulos, marcas, imagen, tabla, fórmula, cita y nota; recursos completos, advertencias de pérdidas y archivo `.nab` intacto. |
| **5** | Compatibilidad editorial ampliada | Paquete que realmente exige LuaLaTeX/Biber, cancelación y diagnóstico de herramientas ausentes; sin acceso fuera del trabajo autorizado. |
| **6** | Ventanas independientes, proyectos y biblioteca ampliada | Dos documentos con deshacer, guardado y PDF independientes; quitar una colección no borra archivos; migración JSON→SQLite conserva referencias. |

La accesibilidad integral continúa reservada para la fase acordada. DOI/ISBN y Zotero son rutas opcionales posteriores; no se convierten en requisitos de cuenta o red del editor.

## Qué se hizo en esta revisión

- Comparación completa de códigos y prioridades; correcciones documentales identificadas en el CSV.
- Lectura de código local, tests existentes y fuentes primarias de GitHub, con revisión de licencias.
- Diagnóstico local y sintético de la cita narrativa, archivado y reproducible.
- Ninguna dependencia instalada ni incorporada, ningún cambio de runtime o de formato `.nab`, ninguna descarga de paquetes de revista ni modificación de documentos personales.
- Las propuestas y su encaje están evaluados; las integraciones continúan pendientes de implementar y validar. La [trazabilidad de fuentes](research/github-source-snapshot.json) registra ramas y hashes de archivos consultados.

