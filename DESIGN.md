---
name: Naberius
description: Editor académico nativo de la familia METATRON, RAZIEL y PAIMON.
colors:
  accent-light: color(srgb 0.137 0.29 0.376)
  accent-dark: color(srgb 0.51 0.71 0.77)
  symbol-light: '#234A60'
  icon-navy: '#111B26'
  icon-ivory: '#E8E6D9'
typography:
  home-title:
    fontFamily: -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 32px
    fontWeight: 600
  brand:
    fontFamily: -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 14px
    fontWeight: 600
    letterSpacing: 1px
  outline:
    fontFamily: -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 12px
  status:
    fontFamily: -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 11px
  author:
    fontFamily: -apple-system, BlinkMacSystemFont, sans-serif
    fontSize: 10px
  document-title-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 30.75px
    fontWeight: 700
  document-subtitle-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 16.5px
    fontWeight: 400
  document-heading1-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 22.5px
    fontWeight: 700
  document-heading2-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 18.75px
    fontWeight: 700
  document-heading3-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 16.5px
    fontWeight: 700
  document-body-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 15px
    fontWeight: 400
  document-caption-default:
    fontFamily: Latin Modern Roman, serif
    fontSize: 12.75px
    fontWeight: 400
rounded:
  equation-preview: 8px
  recovery-notice: 10px
spacing:
  navigation-y: 3px
  group-content: 6px
  status-y: 8px
  footer-gap: 9px
  inspector-stack: 10px
  modebar-y: 11px
  inspector-inset: 16px
  footer-inset: 18px
  workspace-inset: 20px
  paragraph-after-default: 8.75px
components:
  button-primary-label:
    padding: 5px 8px
  sidebar-navigation-label:
    padding: 3px 0
  sidebar-brand:
    typography: '{typography.brand}'
    padding: '{spacing.footer-inset}'
  workspace-modebar:
    padding: 11px 20px
  workspace-status:
    typography: '{typography.status}'
    padding: 8px 20px
  editor-zoom:
    typography: '{typography.status}'
    width: 58px
  inspector:
    width: 270px
    padding: '{spacing.inspector-inset}'
  recovery-notice:
    rounded: '{rounded.recovery-notice}'
    padding: 14px
  equation-preview:
    rounded: '{rounded.equation-preview}'
    padding: 10px
  document-sheet-default:
    typography: '{typography.document-body-default}'
    padding: 50px 88.582677px
  proof-header:
    padding: 16px
  proof-stale-note:
    padding: 9px 16px
  proof-footer:
    padding: 12px
---

# Design System: Naberius

## Overview

**Creative North Star: "El escritorio académico de la familia METATRON"**

Naberius hereda el mundo nativo de METATRON, RAZIEL y PAIMON: superficies semánticas de macOS, acento petróleo y un sello geométrico propio. La ampliación para escritura académica da prioridad al texto, al esquema del documento y a propiedades que aparecen cuando se necesitan. La marca identifica la herramienta desde el pie; no ocupa el lugar del contenido.

La interfaz es sobria, densa y operativa. SwiftUI organiza ventanas, navegación y controles; AppKit/TextKit mantiene el lienzo de escritura y PDFKit presenta la prueba compuesta por LaTeX. El sistema cambia con Claro, Oscuro o Sistema. Este registro describe la implementación local 0.2.0, revisada el 30-10-2026; no certifica cumplimiento íntegro de P0 ni una distribución notarizada.

**Key Characteristics:**

- Superficies y estados nativos de macOS.
- Un acento adaptativo y un sello monolineal propio.
- Texto documental en Latin Modern Roman incluida, con jerarquía semántica y plantilla configurable.
- Herramientas compactas, paneles ocultables y escritura sin animaciones añadidas.

Los valores de medidas en el frontmatter representan puntos lógicos de SwiftUI/AppKit. Se expresan como `px` para interoperabilidad del formato y del catálogo; un `px` del catálogo representa un punto lógico del diseño, no un píxel físico de pantalla. Las familias CSS de sistema son equivalentes de previsualización de `NSFont.systemFont`/`.system`, no una dependencia web. Las reglas nativas del código prevalecen sobre el catálogo HTML. El snippet documental incorpora las cuatro OTF como datos locales; no requiere instalar fuentes ni consultar un servidor.

## Colors

Un único acento petróleo cambia con la apariencia; los neutros se resuelven mediante macOS y el marfil queda reservado al recurso de marca.

### Primary

- **Petróleo claro** (`accent-light`): valor sRGB de `Brand.accent` para Aqua; iconos de navegación, marca y tint del entorno.
- **Petróleo luminoso** (`accent-dark`): variante de `Brand.accent` para Dark Aqua; conserva contraste sobre superficies oscuras.
- **Petróleo del símbolo exportado** (`symbol-light`): tinta fija de `symbol-light.svg`. Es un recurso gráfico; no sustituye el acento adaptativo en vistas.

### Neutral

- **Azul profundo del icono** (`icon-navy`): baldosa del icono de aplicación.
- **Marfil del sello** (`icon-ivory`): trazo del icono y de `symbol-dark.svg`.
- **Fondo de ventana**: `NSColor.windowBackgroundColor`, usado por el detalle de `RootView`.
- **Fondo de controles**: `NSColor.controlBackgroundColor`, usado en inspector y aviso de recuperación.
- **Entorno de página**: `NSColor.underPageBackgroundColor`, usado fuera del lienzo.
- **Fondo documental**: `NSColor.textBackgroundColor`, usado por `NSTextView`, tablas y miniaturas.
- **Texto y cursor**: `NSColor.labelColor`; etiquetas auxiliares SwiftUI usan `.secondary`.
- **Separadores**: `NSColor.separatorColor` para líneas de página, tablas y miniaturas; `Divider` para divisiones nativas.
- **Cabecera de tabla**: `NSColor.quaternaryLabelColor` en tablas con encabezado y estilo distinto de Simple.

Los neutros nativos son tokens semánticos, no una paleta hexadecimal fija. Su resultado depende de apariencia, versión del sistema, accesibilidad y composición de la ventana. Las capturas reales `docs/typesetting/equation-editor-light.png` y `equation-editor-dark.png` verifican estos roles en el editor 0.2.0, incluida la raíz visible en lienzo e inspector. No convierten un píxel compuesto en un nuevo token ni certifican todos los estados. El enlace Ko-fi conserva el tratamiento nativo de `Link`.

### Named Rules

**The Native Surface Rule.** Fondos, texto, separadores y estados conservan sus roles semánticos de macOS; no se congelan a los colores del icono.

**The Family Accent Rule.** La identidad interactiva usa `Brand.accent`; los recursos exportados usan sus tintas propias según el fondo.

## Typography

**Display Font:** sistema macOS para títulos y controles de interfaz; Latin Modern Roman para títulos documentales en la plantilla predeterminada.

**Body Font:** Latin Modern Roman incluida. La plantilla puede elegir también Times New Roman, Georgia, Helvetica o Arial; los documentos conservan su selección.

**Label/Mono Font:** sistema para navegación, herramientas y estados; cifras monoespaciadas para palabras y páginas PDF. El log de composición usa sistema monoespaciado de 10pt.

**Character:** la interfaz mantiene la familiaridad de macOS; el documento reúne cuerpo, títulos, negrita y cursiva en una familia de origen TeX. La prueba PDF muestra el resultado real del motor, cuya composición se distingue del lienzo de escritura.

### Hierarchy

- **Título de inicio:** `home-title`; el resto de títulos de controles conserva estilos semánticos SwiftUI como `.title3`, `.headline` y `.caption`.
- **Marca del pie:** `brand`; NABERIUS acompaña un sello de 28pt. La autoría usa `author` y el estado usa `status`.
- **Esquema:** `outline`; primer nivel `.medium`, los demás `.regular`. La navegación sigue usando el sistema aunque el título documental al que conduce use Latin Modern.
- **Documento en edición:** `base = template.fontSize × 1.25`. Los tokens `document-…-default` describen la plantilla de 12pt y su base de edición de 15pt; no fijan el tamaño final del PDF.
- **Escala en edición:** título `base × 2.05`; subtítulo y niveles 3/4 `base × 1.1`; nivel 1 `base × 1.5`; nivel 2 `base × 1.25`; leyenda `base × 0.85`. Título y niveles 1–4 usan bold de la familia seleccionada; subtítulo, párrafo y leyenda parten de regular. El contenido conserva sus rasgos de negrita y cursiva.
- **Párrafos en edición:** alineación justificada; primera línea `paragraphIndentMM × 72 / 25.4 × 1.25`; separación posterior `paragraphSpacingPT × 1.25`. El layout inicial establece 0mm y 7pt, de donde procede `paragraph-after-default`; Libro usa 5mm y 0pt. Los títulos conservan 20pt antes y 10pt después; título documental 16pt después y subtítulo 24pt. TextKit calcula la altura de línea; añade `max(0, (template.lineSpacing − 1) × base × 0.65)`.
- **Interlineado de plantillas integradas:** Tesis 1.5, Informe académico 1.4 y En blanco/Artículo/Libro/Carta 1.15. Son valores de plantilla, no una escala de controles.
- **Documento PDF:** `fontspec` carga los mismos OTF desde `fonts/`, con `Ligatures=TeX`. El cuerpo usa `template.fontSize` y un baselineskip declarado de `fontSize × 1.2`, junto con `\linespread` de la plantilla. Títulos y secciones usan comandos de la clase LaTeX; no se les atribuye la escala del editor.

### Fuentes incluidas y logos tipográficos

`DocumentTypography` define `lmroman10-regular.otf`, `lmroman10-bold.otf`, `lmroman10-italic.otf` y `lmroman10-bolditalic.otf`. `DocumentFonts` los registra mediante CoreText con alcance `.process`, sin instalar fuentes en el sistema. La familia predeterminada selecciona `LMRoman10-Regular`, `Bold`, `Italic` y `BoldItalic`. Para una alternativa usa la fuente disponible y sus rasgos, con respaldo en Latin Modern y finalmente `NSFont.userFont`. El proyecto LaTeX copia las OTF y la documentación de licencia para conservar la composición portable.

Los logos son presentación derivada. `DocumentTypography.logos(in:)` reconoce palabras independientes `LaTeX`, `Latex`, `LATEX` y `TeX`, respetando límites de letras, números y guion bajo. El documento conserva el texto original. `RichText.decorateLogos` modifica glifos, kerning y línea base: A al 72% y elevada 0.30 veces el tamaño original; E rebajada 0.215; ajustes posteriores a L, A, T y E de −0.30, −0.12, −0.12 y −0.10 veces ese tamaño. Desactiva ligaduras en el logo. El exportador usa `\LaTeX{}` y `\TeX{}`; los macros del motor determinan su resultado PDF.

Las ecuaciones compuestas proceden de TeX real, recortadas por PDFKit y conservadas como vector hasta dibujarse en AppKit. `EquationTypesetter` parte de 21pt, escala respecto de 10pt y colorea con `labelColor`; las fuentes matemáticas proceden de los paquetes TeX. Hasta disponer del render se usa la representación textual. No se atribuyen las fuentes matemáticas a las cuatro OTF de texto.

### Named Rules

**The Semantic Type Rule.** El estilo del bloque determina su jerarquía; familia, tamaños y layout se derivan de la plantilla. La escala del editor no se declara idéntica a la de los comandos LaTeX.

**The Shared Font Rule.** La familia predeterminada usa las mismas cuatro OTF incluidas en el editor y en `fontspec`; el registro local a un proceso no se sustituye por una instalación de fuentes en el sistema.

## Layout

La ventana parte de 1280 × 850pt y exige al menos 940 × 640pt. `NavigationSplitView` asigna al lateral 195pt mínimo, 225pt ideal y 290pt máximo. El inspector opcional mide 270pt. No hay breakpoints web: el comportamiento se apoya en el redimensionamiento de ventanas y en ocultar paneles.

En modo Páginas el editor tiene un máximo de 780pt y 20pt de espacio horizontal exterior; en Continuo llena el ancho disponible. El inset del texto en Páginas es `template.marginMM × 72 / 25.4 × 1.25` y en Continuo es 40pt; el inset superior es 50pt. El margen inicial de 25mm produce aproximadamente 88.582677pt horizontales. La altura orientativa usa la del papel multiplicada por 1.25: A4 841.89pt, Carta 792pt y Legal 1008pt antes del factor. Los intervalos excluidos entre páginas miden 40pt. El editor conserva una sola instancia de `NSTextView` al cambiar Páginas/Continuo o mostrar la prueba PDF.

La barra de modo y el pie comparten 20pt horizontales, con densidades verticales distintas documentadas en sus tokens. La navegación expande su etiqueta a todo el ancho, añade 3pt verticales y usa `contentShape(Rectangle())`; la dimensión visible del icono no define por sí sola el área de clic. El zoom es un menú compacto de 58pt que muestra el porcentaje actual. El modo concentración oculta sidebar, inspector y barra de modo; Escape permite salir. La prueba PDF se superpone al lienzo: el editor sigue montado, invisible, sin eventos de puntero y oculto a accesibilidad mientras se muestra la prueba.

Inicio centra su contenido con un máximo de 820pt y 46pt de inset. Su bloque principal usa 30pt entre secciones. Estos valores describen ese componente; no obligan a otros módulos a adoptar la composición del inicio.

## Elevation & Depth

La profundidad se expresa con superficies nativas, separadores y la jerarquía entre paneles y documento. El código revisado no añade sombras personalizadas, desenfoques ni transiciones al escribir. Ventanas, sheets, menús, foco y estados de controles conservan su comportamiento de macOS; sus sombras no se redefinen como tokens propios.

### Named Rules

**The Quiet Workspace Rule.** La jerarquía operativa se apoya en las superficies del sistema y en el contenido; escribir y ejecutar atajos no dispara animaciones añadidas.

## Shapes

El documento y las miniaturas mantienen contornos rectangulares. Las líneas propias de página y tabla miden 0.5pt. Los radios explícitos de vista son el de previsualización de ecuación y el del aviso de recuperación. Botones, campos, grupos y selector segmentado conservan las formas del control nativo, sin inventar un radio universal.

El sello tiene extremos y uniones redondos. Su geometría combina un asta a la izquierda, dos barras y una curva abierta de dos lóbulos. La marca del pie usa trazo de 1.2pt; la del inicio y Acerca de usa 2pt. La baldosa del icono pertenece al recurso de marca, no a la forma de las tarjetas del producto.

## Components

### Buttons

Controles familiares y discretos. Las acciones principales usan `.borderedProminent`; las secundarias `.bordered`, `.plain` o `.link` según el contexto existente. Las acciones principales de inicio añaden 8pt horizontales y 5pt verticales dentro de la etiqueta. Hover, foco, pulsación y deshabilitado pertenecen al control nativo. Conservar etiquetas y ayudas de teclado; los iconos de herramientas son SF Symbols.

### Inputs / Fields

Los campos usan `.roundedBorder` en búsqueda, inspector y citas. El inspector aplica `.controlSize(.small)`. Pickers, steppers, toggles y campos conservan sus estados y foco de macOS; el diseño no define un anillo de foco alternativo.

### Navigation

`List` con `.sidebar` agrupa Inicio, Plantillas y Biblioteca, seguido del esquema semántico. Los iconos usan el acento adaptativo. Los rótulos de navegación ocupan todo el ancho de la fila. El esquema admite dos líneas, sangra 12pt por nivel y desplaza la selección de texto al título correspondiente. Este patrón es de escritorio; no existe una navegación móvil implementada.

### Containers

El inspector usa `controlBackgroundColor`, 16pt de inset, pilas de 10pt y contenido de GroupBox con 6pt interiores. Las sheets usan títulos y controles nativos. El aviso de recuperación usa su radio y padding explícitos; no constituye una familia de tarjetas decorativas.

### Workspace controls

El selector Páginas/Continuo es segmentado y mide 205pt. La barra muestra la plantilla en caption, el acceso PDF LaTeX/Escritura y el estado de composición. El pie presenta guardado, palabras, zoom y contexto: Paginación orientativa, Lienzo continuo o PDF LaTeX. En Páginas y escritura ofrece página anterior/siguiente del editor. El zoom sigue compacto a 58pt; AppKit admite magnificación 0.6–1.8 y el menú ofrece 75%, 100%, 125% y 150%.

### Typeset proof

`TypesetProofView` conserva controles de sistema. La cabecera usa 16pt de inset y 12pt entre grupos; identifica el PDF, motor, duración y hora de composición. Actualizar PDF usa ⇧⌘R; Escribir devuelve el foco al editor. Cuando el documento cambió, el aviso de prueba obsoleta usa 9pt verticales y 16pt horizontales. El pie usa 12pt de inset, contador y navegación de página, Detalles de composición y Guardar PDF. Los logs solo se muestran al abrir detalles, con altura máxima de 180pt.

`ProofPDFView` usa PDFKit con ajuste automático, `.singlePageContinuous` y separaciones de página nativas. El PDF verifica fuentes, ecuaciones y páginas de esa composición. El aviso de estado obsoleto distingue la prueba anterior de cambios aún no recompuestos.

### Document layout controls

`DocumentLayoutControls` conserva pickers, steppers, campos y toggles nativos para clase, sangría, separación, encabezado, pie y números de página. Ofrece sangría 0–20mm y separación 0–30pt, en pasos de una unidad. Informe/Tesis y Libro usan capítulos: Título 1 se exporta como capítulo y los demás niveles como apartados. Artículo usa secciones. Carta añade destinatario, saludo y despedida. En el PDF `geometry` aplica el margen de plantilla y `fancyhdr` compone encabezado y pie; la línea de encabezado es 0.4pt solo cuando hay texto.

### Brand footer

El pie usa una pila con 9pt de separación y 18pt de inset. Incluye sello, NABERIUS, Configuración, la autoría literal **Creado por Sebastián Pastén F.** y el enlace voluntario **Apoyar en Ko-fi**. Su destino es el comprobado en la familia: `https://ko-fi.com/C0C51WQ1T0`. Se abre por acción del usuario.

## Do's and Don'ts

### Do:

- **Do** usar superficies, foco, selección y controles semánticos de macOS en nuevas vistas.
- **Do** resolver la identidad interactiva mediante `Brand.accent` en Claro, Oscuro y Sistema.
- **Do** mantener el contenido como centro y exponer propiedades mediante paneles ocultables.
- **Do** derivar familia, tamaños y layout documentales de estilos semánticos y de la plantilla guardada, usando las OTF incluidas para Latin Modern.
- **Do** conservar el sello original, la autoría literal y el destino Ko-fi comprobado de la familia.

### Don't:

- **Don't** aplicar el navy o el marfil del icono como fondos fijos de la interfaz.
- **Don't** reducir un área de navegación a los píxeles visibles del icono o del rótulo.
- **Don't** reconstruir el editor al cambiar Páginas/Continuo ni añadir animación a la escritura.
- **Don't** describir la paginación del editor ni su escala tipográfica como resultado final; verificar la prueba PDF actualizada.
- **Don't** convertir los valores de una captura en una nueva paleta ni presentar el catálogo HTML como implementación de la app.

Evidencia de 0.2.0: `Sources/Naberius/{NativeEditor,DocumentTypesetter,TypesetProofView,WorkspaceView,DocumentLayoutControls}.swift` y `Sources/NaberiusCore/{Typesetting,Document,LaTeX}.swift`. `docs/typesetting/` contiene PDF reales de las seis plantillas, fuentes copiadas, salida TeX, registros e inventario de fuentes incrustadas.

`docs/typesetting/equation-editor-light.png` y `equation-editor-dark.png` son capturas reales del binario final 0.2.0. Ambas muestran la tipografía documental, los logos y la raíz compuesta visible en el lienzo y en el inspector, después de corregir el tinte de plantilla SwiftUI con `.template` y `.primary`.

La verificación nativa por CUA del flujo principal comprobó la prueba PDF al 125%, con texto real, zoom propio del visor y sin la toolbar de edición. Los archivos `docs/typesetting/proof-light.png` y `proof-dark.png` proceden de `NSView.cacheDisplay`: muestran el chrome, pero omiten los mosaicos de PDFKit. No constituyen evidencia visual del contenido PDF. `article-page-1.png` es una renderización de `article.pdf`, y `equation.png` una renderización de la salida de ecuación; tampoco son capturas de UI.

El alcance de esta evidencia se limita a esos estados del editor y la prueba comprobada. Las capturas de 0.1.0 y su veredicto limitado de navegación/zoom son históricas y no se trasladan como aprobación integral de 0.2.0. No se ejecutó detector HTML/CSS porque el artefacto es nativo. El sidecar conserva los tokens y la marca; no añade cambios visuales ni certifica cumplimiento integral de P0.

## Terminación 0.3.0

El sello usa un asta izquierda, dos barras y una curva abierta de dos lóbulos, sin terminales circulares ni trazos interiores. La fuente vectorial normalizada es `16 18 64 64`. Se conservan navy/marfil y el acento adaptativo; los PNG pequeños refuerzan el trazo sin eliminar geometría. Ver docs/BRAND.md para tamaños y regeneración.

La tabla seleccionada monta una sola cuadrícula AppKit sobre su adjunto, dentro del documento. Los campos usan Latin Modern, filas con altura ajustable y desplazamiento horizontal/vertical. Una barra compacta añade/quita filas y columnas y termina la edición; el pie muestra Tab/⇧Tab/Esc. La vista no editada abrevia a ocho filas con aviso; el PDF conserva todos los datos.

La importación bibliográfica presenta selección de registros a la izquierda y revisión de metadata/advertencias a la derecha. Los datos originales se despliegan bajo demanda. Las cadenas de interfaz y errores se resuelven mediante L10n y el catálogo español empaquetado; no se traducen identificadores persistentes ni datos del usuario.
