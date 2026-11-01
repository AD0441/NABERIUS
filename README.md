<div align="center">
  <img src="Resources/Brand/icon-256.png" width="112" alt="Icono de Naberius">
  <h1>NABERIUS</h1>
  <p><strong>Escritura visual. Composición precisa.</strong></p>
  <p>Da forma a tus ideas y compón documentos con LaTeX desde una aplicación nativa para macOS.</p>
  <p>
    <img alt="macOS 14 o posterior" src="https://img.shields.io/badge/macOS-14%2B-183B4A?logo=apple&logoColor=white">
    <img alt="Swift 6.2 o posterior" src="https://img.shields.io/badge/Swift-6.2%2B-365D72?logo=swift&logoColor=white">
    <img alt="Verificado en Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-verificado-476957">
    <a href="LICENSE"><img alt="Licencia AGPL-3.0-or-later" src="https://img.shields.io/badge/license-AGPL--3.0--or--later-58616B"></a>
  </p>
  <p><a href="https://github.com/AD0441/NABERIUS/releases/tag/v0.5.0">Descargar</a> · <a href="#qué-hacemos-y-qué-hacemos-mejor">Capacidades</a> · <a href="#en-uso">En uso</a> · <a href="#tres-formas-de-trabajar">Vistas</a> · <a href="#empezar">Empezar</a> · <a href="CONTRIBUTING.md">Contribuir</a> · <a href="https://ko-fi.com/C0C51WQ1T0">Apoyar</a></p>
</div>

![Naberius — portada editorial en azul petróleo, tipografía académica y sello en relieve](docs/assets/brand/cover.jpg)

**NABERIUS** reúne escritura estructurada, ecuaciones, tablas y bibliografía en un espacio de trabajo para artículos, tesis e informes. Escribe visualmente y revisa el PDF que compone **LaTeX mediante Tectonic**. Contenido, imágenes, plantilla y referencias viajan juntos en un archivo portable `.nab`.

**Creado por Sebastián Pastén F.** Pertenece a la familia de [METATRON](https://github.com/AD0441/METATRON), [RAZIEL](https://github.com/AD0441/RadioWorkbench) y [PAIMON](https://github.com/AD0441/PAIMON): herramientas nativas, procesamiento local y apoyo voluntario.

**Versión actual: [Naberius 0.5.0 — versión preliminar para Apple Silicon](https://github.com/AD0441/NABERIUS/releases/tag/v0.5.0).** Incluye tres vistas de trabajo, plantillas editoriales en ZIP y diseños de una o dos columnas. [Descargar la app](https://github.com/AD0441/NABERIUS/releases/download/v0.5.0/Naberius.zip) · [Historial de cambios](CHANGELOG.md).

## Qué hacemos y qué hacemos mejor

Naberius acompaña el recorrido del borrador al documento compuesto: escribir con estructura, reunir las fuentes y comprobar cómo quedará cada página.

![Naberius: escritura académica y composición LaTeX en tu Mac](docs/assets/marketing/naberius-cover.jpg)

*Imagen promocional generada con IA a partir de la aplicación real. Las capturas de «En uso» muestran la app instalada.*

- **Escribir con estructura:** títulos, esquema, énfasis, listas, enlaces, búsqueda y reemplazo. Fuentes Latin Modern incluidas y apariencia clara, oscura o del sistema.
- **Trabajar con objetos académicos:** tablas editables dentro del documento, figuras, ecuaciones, notas, índice y referencias cruzadas.
- **Revisar el PDF real:** composición LaTeX, navegación, zoom y guardado. Actualización manual o después de una pausa configurable.
- **Usar tu formato editorial:** importar un ZIP con su clase, macros y recursos; revisar los campos detectados y escribir en una plantilla de revista.
- **Configurar el diseño:** artículo, informe, tesis, libro o carta; una o dos columnas, separación, márgenes por lado, sangría, cabeceras y pies.
- **Organizar fuentes:** APA 7, IEEE, Vancouver y Chicago autor-fecha mediante citeproc-js local. Importar BibTeX/BibLaTeX, RIS o CSL-JSON con revisión previa.
- **Conservar el trabajo:** un archivo `.nab`, guardado atómico, detección de conflictos y recuperación local. Exportar el proyecto LaTeX con sus recursos.

La [matriz de requisitos](docs/STATUS.md) y los [límites conocidos](docs/LIMITATIONS.md) describen el alcance real de la versión.

### Qué mejoramos en tu flujo de trabajo

| Tarea | Cómo ayuda Naberius |
| --- | --- |
| **Escribir y revisar la composición** | Editor y PDF real en la misma ventana, con actualización tras una pausa configurable. |
| **Preparar el formato de una revista** | Importación de ZIP que conserva la clase y los recursos originales; revisión de los campos detectados y aviso si faltan archivos. |
| **Revisar referencias antes de incorporarlas** | Selección de registros, campos conservados y advertencias de importación en una misma revisión. |
| **Llevar el trabajo a otro Mac** | Un archivo `.nab` reúne texto, imágenes, bibliografía y plantilla. También puedes exportar el proyecto LaTeX. |

La escritura aproxima el formato; el PDF confirma las columnas, los saltos y la composición final.

## En uso

Vista **Editor + PDF** de Naberius 0.5.0 con el documento original de demostración [Ideas que toman forma](docs/examples/Ideas-que-toman-forma.nab). A la izquierda se escribe; a la derecha se comprueba la composición real de LaTeX.

![Naberius 0.5.0: editor y PDF real, con títulos, ecuación y tabla](docs/screenshots/editor-pdf-0.5.jpg)

Las capturas siguientes documentan la edición de tablas y la revisión bibliográfica introducidas en 0.3.0.

| Tablas dentro del documento | Revisión de la importación bibliográfica |
| --- | --- |
| ![Tabla en apariencia oscura](docs/screenshots/table-dark.png) | ![Registros, campos y advertencias antes de importar](docs/screenshots/bibliography-light.png) |

## Tres formas de trabajar

Elige la vista sobre el documento y configura la predeterminada en **Configuración → General → Escritura y PDF**.

| Vista | Para qué sirve |
| --- | --- |
| **Escritura** | Una página editable orientativa o un lienzo continuo para desarrollar el texto. Puedes ajustar el ancho de escritura. |
| **Editor + PDF** | Escribir y comprobar el PDF real al mismo tiempo. El divisor permite repartir el espacio entre ambas vistas. |
| **PDF** | Revisar la composición final a todo el ancho, navegar, ampliar y guardar el resultado. |

La página editable aproxima el formato; los saltos, las columnas y la paginación definitiva se comprueban en el PDF. Cambiar de vista conserva el contenido, la selección y el historial.

La actualización automática espera **2, 4 u 8 segundos** después de escribir y solo se programa en la vista dividida con la ventana activa. Puedes desactivar **Automático** y actualizar con **⇧⌘R**. El motor no se ejecuta por cada pulsación. [Guía de vistas y composición](docs/EDITOR_MODES.md).

## Del ZIP de una revista al documento

En **Configuración → Plantillas → Importar plantilla**, selecciona el ZIP editorial. Naberius detecta el documento principal, conserva la clase y los recursos originales, y ofrece los campos de metadata reconocidos. La composición usa ese paquete; no exige crear un adaptador específico para cada revista.

Si faltan clases o estilos, puedes **Completar recursos…**. **Crear diseño libre** permite partir del contenido con un diseño configurable. La compatibilidad depende de los archivos y macros del paquete; una variante libre no certifica el formato de una revista.

Se han probado paquetes IEEE, JIMIS y MECS. El ZIP CJS ensayado carecía de su clase requerida; la app informa el recurso ausente. Los paquetes aportados para pruebas no se redistribuyen en este repositorio. [Funcionamiento, formatos probados y límites](docs/TEMPLATE_PACKAGES.md).

## Bibliografía y tablas

En **Biblioteca → Importar**, revisa registros, campos y advertencias antes de añadir las fuentes. La importación reconoce abreviaturas `@string`, concatenación `#`, `crossref`, `xdata`, nombres institucionales, acentos y fechas. Los campos adicionales y los datos originales se conservan; las limitaciones se muestran durante la revisión. No se promete compatibilidad universal con todas las extensiones BibLaTeX. [Bibliografía](docs/BIBLIOGRAPHY.md).

Haz doble clic en una tabla para editar sus celdas dentro del documento. **Tab / ⇧Tab** cambian de celda, **Intro** avanza de fila y **Esc** termina la edición. Tab en la última celda añade una fila hasta el límite de 200. La vista puede abreviar tablas largas; el PDF conserva sus filas. [Tipografía y composición](docs/TYPESETTING.md).

## Empezar

[Descargar Naberius 0.5.0 para Apple Silicon](https://github.com/AD0441/NABERIUS/releases/tag/v0.5.0) · [Comprobar SHA-256](https://github.com/AD0441/NABERIUS/releases/download/v0.5.0/Naberius.zip.sha256)

Requiere **macOS 14 o posterior**. La app se ha verificado en un Apple M1 con 8 GB; Intel no está verificado. El ZIP tiene firma local ad hoc y no está notarizado.

1. Descomprime el ZIP y coloca **Naberius.app** en Aplicaciones.
2. Crea un documento en blanco, elige una plantilla o abre el ejemplo incluido en este repositorio.
3. Aplica estilos y añade tablas, figuras, ecuaciones o referencias desde los menús.
4. Guarda con **⌘S** y elige **Editor + PDF** para revisar la composición.

**Tectonic se instala por separado.** Puedes escribir y exportar el proyecto LaTeX sin el motor. Para producir el PDF, selecciona Tectonic en **Configuración → Composición** si no se detecta. La preparación inicial de paquetes puede requerir conexión y se inicia expresamente desde allí; después se utiliza la caché local.

Para compilar desde el código, usa Xcode con Swift 6.2 o posterior:

```sh
git clone https://github.com/AD0441/NABERIUS.git
cd NABERIUS
./script/build_and_run.sh
```

El script crea y verifica el bundle, produce `dist/Naberius.zip` e instala `~/Applications/Naberius.app`. `--build-only` solo genera el ZIP; `NABERIUS_APP_DIR` permite elegir el destino de instalación.

## Local por decisión

Naberius funciona sin cuenta y guarda los documentos en tu Mac. No incorpora telemetría ni exige una nube. La descarga de paquetes de composición y la apertura de enlaces, incluido Ko-fi, requieren una acción explícita. [Privacidad](docs/PRIVACY.md).

La interfaz usa SwiftUI, AppKit/TextKit y PDFKit. La composición y el trabajo de disco se realizan fuera de la escritura interactiva. La verificación en Apple Silicon no se presenta como garantía general de memoria, batería o latencia.

## Validación

La versión 0.5.0 pasó **86 pruebas** localmente, incluidas integraciones con Tectonic real; también se verificó la ruta SwiftPM nativa. [CI de la versión](https://github.com/AD0441/NABERIUS/actions/runs/41265658069) · [Pruebas y evidencias](docs/TESTING.md).

```sh
python3 script/sync_localization.py --check
./script/test.sh
./script/build_and_run.sh --build-only
# Integraciones con Tectonic instalado y paquetes disponibles:
NABERIUS_COMPOSE=1 ./script/test.sh
```

Las pruebas ordinarias de CI omiten el motor externo. Esta versión mantiene requisitos pendientes; la auditoría integral de accesibilidad queda para una fase posterior.

## Contribuir

Los aportes son bienvenidos: [errores y propuestas](https://github.com/AD0441/NABERIUS/issues), pruebas con documentos anonimizados, compatibilidad editorial y traducciones. Consulta [CONTRIBUTING.md](CONTRIBUTING.md).

[Arquitectura](docs/ARCHITECTURE.md) · [Formato `.nab`](docs/DOCUMENT_FORMAT.md) · [Plantillas ZIP](docs/TEMPLATE_PACKAGES.md) · [Material para la web](docs/PRESENTATION.md)

## Apoyar el proyecto

Los aportes voluntarios ayudan a mantener el desarrollo y las pruebas de Naberius.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/C0C51WQ1T0)

## Identidad y licencia

El sello simplificado de Naberius conserva el azul profundo y el marfil de la familia. Su geometría original combina un asta, dos barras y una curva abierta. Se incluyen SVG, PNG, ICNS, el [generador de iconos](script/make_brand.swift), la [base geométrica de la portada](script/make_cover_reference.swift) y su [dirección artística](docs/assets/brand/cover-prompt.txt). [Criterios de identidad](docs/BRAND.md) · [Procedencia de la portada](docs/PRESENTATION.md).

Código propio: **AGPL-3.0-or-later**, copyright 2026 Sebastián Pastén F. Los componentes de terceros conservan sus licencias: [avisos](THIRD_PARTY_NOTICES.md), [licencia](LICENSE) y [autoría](COPYRIGHT). citeproc-js se utiliza bajo su opción AGPL; las fuentes Latin Modern conservan GUST y los estilos/locales CSL, CC BY-SA.

<div align="center">
  <picture><source media="(prefers-color-scheme: dark)" srcset="Resources/Brand/symbol-dark.svg"><img src="Resources/Brand/symbol-light.svg" width="70" alt="Símbolo de Naberius"></picture>
  <p><strong>Creado por Sebastián Pastén F.</strong></p>
  <p><a href="https://www.sebastianpasten.com/desarrollos-aplicaciones-para-mac-software-sdr">Más aplicaciones para Mac</a></p>
</div>
