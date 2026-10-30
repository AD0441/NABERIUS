# NABERIUS — Especificación de requerimientos del producto

**Versión:** 1.0 · **Fecha:** 29 de octubre de 2026  
**Estado:** línea base funcional y de diseño para revisión en Codex; **no es todavía el prompt de implementación**.  
**Producto:** Naberius · editor visual de documentos académicos y profesionales con composición mediante LaTeX.  
**Plataforma inicial:** macOS, priorizando Apple Silicon; extensibilidad futura evaluable.  
**Autor / identidad editorial:** Sebastián Pastén F.

> **Propósito:** permitir escribir y estructurar documentos como en un procesador de textos moderno, sin aprender comandos LaTeX. La aplicación administra composición tipográfica, plantillas, citas, índices y exportaciones. El usuario se concentra en el contenido.

## 0. Instrucciones de lectura y alcance

- Este documento consolida las decisiones ya tomadas sobre Naberius y propone requisitos verificables para completar el producto.
- **No comenzar a implementar solo por recibir esta especificación.** Antes de programar, el usuario indicará expresamente en Codex qué *skills* y flujo de trabajo utilizar. Codex deberá respetarlos.
- Las referencias a tecnologías son **candidatas**, no una imposición de stack; evaluar compatibilidad, mantenimiento, licencias, rendimiento y habilidades disponibles antes de elegir.
- Etiquetas de prioridad: **P0** = primera versión funcional indispensable; **P1** = siguiente entrega; **P2** = evolución posterior.
- Cada requisito se considera cumplido únicamente con implementación real, pruebas y evidencia. Un mockup o botón sin comportamiento no cuenta como función terminada.
- El nombre del programa es **Naberius**. El formato maestro es **`.nab`**.

## 1. Decisiones de producto ya confirmadas

| Código | Decisión consolidada |
|---|---|
| D-01 | LaTeX queda en segundo plano: **ninguna tarea ordinaria exige escribir código**. |
| D-02 | Dos vistas intercambiables: **páginas** (estilo Word) y **lienzo continuo**. |
| D-03 | **Barra compacta y contextual**: pocas acciones siempre visibles; resto bajo demanda. |
| D-04 | **Inspector híbrido**: controles rápidos junto al elemento, panel lateral para propiedades detalladas. |
| D-05 | **Formato estructurado con personalización controlada**: plantilla como fuente base y excepciones explícitas. |
| D-06 | Plantillas **administradas desde Configuración**; su aplicación al documento no requiere editar LaTeX. |
| D-07 | **Importación guiada y compatibilidad progresiva** con plantillas externas LaTeX. |
| D-08 | **Un archivo `.nab` único y portable**, que encapsula contenido y recursos. |
| D-09 | Modelo **local-first**, uso sin cuenta y escritura/guardado sin conexión. |
| D-10 | Se diseñará la identidad de Naberius revisando primero **METATRON, RAZIEL y PAIMON**; sin modificarlos. |

## 2. Objetivos, usuarios y límites

### 2.1 Objetivos

- **OBJ-01 [P0]** Minimizar la fricción entre abrir un documento y comenzar a redactar.
- **OBJ-02 [P0]** Separar semántica (qué es un título, cita, tabla) de apariencia (cómo la muestra la plantilla).
- **OBJ-03 [P0]** Crear PDF profesional con un motor LaTeX y diagnósticos comprensibles.
- **OBJ-04 [P0]** Preservar datos, referencias e imágenes ante fallos, cierres y traslados a otro Mac.
- **OBJ-05 [P0]** Ofrecer herramientas académicas suficientes sin saturar la interfaz.
- **OBJ-06 [P1]** Facilitar el intercambio con herramientas externas (Word, BibTeX, CSL, Zotero).

### 2.2 Perfiles y escenarios

- Estudiante: informes, memorias, tesis y trabajos con normas de citación.
- Investigador/docente: artículos, proyectos, informes técnicos, bibliografías extensas.
- Profesional: documentos formales que deben adoptar una plantilla y producir un PDF consistente.
- Escritor: manuscritos extensos, capítulos, notas y modo concentración.

### 2.3 Fuera de alcance del MVP

- Colaboración multiusuario en tiempo real, servicios de cuentas y sincronización en nube obligatoria.
- IA integrada o generación automática de texto; no es necesaria para el producto inicial.
- Compatibilidad universal con cualquier clase, paquete o macro LaTeX desde la primera versión.
- Reproducción tipográfica píxel por píxel del PDF dentro del editor de escritura.
- Editor de diagramas complejo, gestor integral de PDFs científicos o maquetación editorial profesional tipo InDesign.
- Publicación automática de archivos personales, telemetría no consentida, ventanas de donaciones intrusivas.

## 3. Pantalla de inicio, documentos y organización

### 3.1 Inicio

- **INI-01 [P0]** Abrir en una pantalla sobria: **Nuevo documento**, **Abrir documento**, **Documentos recientes**, acceso a **Plantillas** y **Biblioteca**.
- **INI-02 [P0]** Permitir nuevo documento en blanco o a partir de cualquier plantilla instalada; mostrar una vista previa breve.
- **INI-03 [P0]** Permitir reabrir la última sesión desde Configuración; no obligar a hacerlo.
- **INI-04 [P0]** La lista de recientes muestra nombre, ubicación, última apertura y estado; no almacenar el texto de los documentos en servicios externos.
- **INI-05 [P0]** Si un archivo reciente fue movido o eliminado, mostrar «Archivo no encontrado», con opciones de localizarlo o quitarlo de la lista.
- **INI-06 [P1]** Fijar favoritos, ordenar, filtrar y buscar documentos recientes.
- **INI-07 [P1]** Carpetas o colecciones de **proyectos** como agrupaciones de documentos existentes, sin alterar automáticamente sus rutas ni crear dependencias entre archivos `.nab`.
- **INI-08 [P1]** Posibilidad de usar varios documentos en pestañas o ventanas y alternar entre ellos sin perder estado.
- **INI-09 [P0]** Estados vacíos útiles: explicar cómo comenzar sin sobrecargar con tutoriales.

### 3.2 Concepto de proyecto

- **PRO-01 [P1]** Un proyecto es una **organización opcional**, no un requisito para editar o compartir un `.nab`.
- **PRO-02 [P1]** Los proyectos guardan referencias a rutas de documentos, orden, favoritos y metadatos locales; un `.nab` sigue siendo independiente.
- **PRO-03 [P1]** Si un archivo se mueve, ofrecer localizarlo o desvincularlo; **no borrar nunca el archivo físico** por quitarlo de una colección.
- **PRO-04 [P1]** Soportar arrastrar documentos entre colecciones sin modificar automáticamente contenido o bibliografía.

## 4. Editor y experiencia de escritura

### 4.1 Espacio de trabajo

- **ED-01 [P0]** Editor visual de contenido estructurado: párrafos, títulos, listas, citas, enlaces, figuras, tablas, ecuaciones y notas.
- **ED-02 [P0]** **Modo continuo:** lienzo limpio sin saltos de página visibles.
- **ED-03 [P0]** **Modo páginas:** hojas, márgenes y cortes de página orientativos, con navegación y zoom.
- **ED-04 [P0]** Ambas vistas deben modificar **el mismo modelo documental**, con el mismo deshacer/rehacer y persistencia.
- **ED-05 [P0]** Conservar selección, cursor, bloque activo y posición lógica al cambiar de vista; reposicionar visualmente lo más cerca posible.
- **ED-06 [P0]** La paginación **definitiva** es la del PDF LaTeX; la vista paginada del editor no prometerá identidad perfecta.
- **ED-07 [P0]** Escritura y desplazamiento fluidos, sin compilar LaTeX por pulsación.
- **ED-08 [P0]** Modo concentración: ocultar navegación, inspector y controles secundarios; salida fácil.
- **ED-09 [P0]** Panel lateral izquierdo ocultable con árbol de títulos, navegación por secciones y estado actual.
- **ED-10 [P1]** Reorganizar secciones completas desde el árbol, manteniendo subapartados y referencias internas.

### 4.2 Barra y menús contextuales

- **UI-01 [P0]** Barra superior compacta: selector de estilo semántico, negrita, cursiva, listas, Insertar, Citar, índice y vista previa.
- **UI-02 [P0]** Al seleccionar texto: acciones rápidas de énfasis, enlace, estilo y cita; evitar tapar permanentemente el contenido.
- **UI-03 [P0]** Al seleccionar una figura, tabla, ecuación o cita: controles específicos, sin opciones irrelevantes.
- **UI-04 [P0]** Inspector derecho opcional para propiedades avanzadas; no mostrarlo si no es necesario.
- **UI-05 [P0]** Cambios simples inmediatos, reversibles por ⌘Z; diálogos solo para operaciones que requieran datos.
- **UI-06 [P0]** Menús nativos: Archivo, Editar, Formato, Insertar, Documento, Referencias, Ver, Ventana, Ayuda; Configuración desde el menú de la aplicación.
- **UI-07 [P0]** Atajos convencionales de macOS: ⌘N/O/S/Z, ⇧⌘Z, ⌘B/I/F; otros configurables o documentados.
- **UI-08 [P1]** Paleta de acciones por búsqueda (por ejemplo ⇧⌘P); no reemplaza controles visuales.
- **UI-09 [P0]** Navegación completa por teclado, foco visible y compatibilidad con VoiceOver.

### 4.3 Comportamiento de texto

- **TXT-01 [P0]** Estilos: título del documento, subtítulo, Título 1–4, párrafo, cita extensa, listas, pies y notas.
- **TXT-02 [P0]** Enter después de un título crea un párrafo normal; Enter en lista mantiene el elemento o sale si está vacío.
- **TXT-03 [P0]** El índice y la numeración se actualizan al cambiar nombres o niveles de títulos.
- **TXT-04 [P0]** Negrita, cursiva, enlaces, superíndice y subíndice son marcas de texto, no cambios arbitrarios de fuente.
- **TXT-05 [P0]** Cortar, copiar y pegar preservan contenido estructurado compatible; «Pegar sin formato» limpia marcas.
- **TXT-06 [P0]** Pegado desde Word/HTML/Markdown sin ejecutar contenido activo ni importar formato peligroso; conservar lo compatible y degradar limpiamente lo demás.
- **TXT-07 [P0]** Deshacer/rehacer consistente también para operaciones de tablas, citas y cambios de propiedades.
- **TXT-08 [P1]** Conteo de palabras, caracteres, páginas estimadas y estadísticas de avance discretas.

## 5. Búsqueda, revisión y corrección

### 5.1 Buscar y reemplazar

- **BUS-01 [P0]** ⌘F busca en el documento abierto con coincidencias destacadas y navegación anterior/siguiente.
- **BUS-02 [P0]** Buscar en títulos, párrafos, listas, pies de figuras, tablas y notas donde exista texto editable.
- **BUS-03 [P0]** Buscar/reemplazar con opción «una coincidencia» o «todas», integrado en deshacer.
- **BUS-04 [P0]** Opciones de mayúsculas/minúsculas y palabra completa.
- **BUS-05 [P1]** Búsqueda avanzada por estilos, secciones y expresiones regulares con previsualización antes de reemplazos masivos.
- **BUS-06 [P2]** Búsqueda global entre documentos recientes o proyectos **solo bajo activación explícita**, con índice local y controles para eliminarlo.

### 5.2 Ortografía y lenguaje

- **ORT-01 [P0]** Revisión ortográfica local con sugerencias y subrayado discreto.
- **ORT-02 [P0]** Idioma configurable por documento, como mínimo español e inglés; admitir variantes regionales si el sistema las ofrece.
- **ORT-03 [P0]** «Ignorar», «Agregar al diccionario» y corrección mediante menú contextual.
- **ORT-04 [P0]** Activar/desactivar revisión y autocorrección por separado; **no alterar silenciosamente términos técnicos o nombres propios**.
- **ORT-05 [P1]** Idioma por selección o bloque y reconocimiento de contenido mixto.
- **ORT-06 [P2]** Revisión gramatical y de estilo opcional; priorizar motores locales y no enviar texto a servicios remotos sin consentimiento explícito.
- **ORT-07 [P0]** Errores de ortografía nunca deben bloquear guardado, apertura ni exportación.

## 6. Elementos académicos y referencias cruzadas

### 6.1 Tablas

- **TAB-01 [P0]** Insertar tabla desde cuadrícula visual de filas/columnas.
- **TAB-02 [P0]** Editar celdas con teclado; añadir/eliminar filas y columnas; establecer encabezados.
- **TAB-03 [P0]** Título, nota, fuente y alineación desde controles contextuales/inspector.
- **TAB-04 [P0]** Identificador persistente, numeración automática y referencias cruzadas actualizables.
- **TAB-05 [P0]** Estilos visuales: académico, simple y cuadrícula; representación según plantilla.
- **TAB-06 [P1]** Pegado de rangos tabulares desde hojas de cálculo, conservando estructura.
- **TAB-07 [P1]** División en varias páginas, encabezados repetidos, celdas combinadas y tablas grandes con control de compatibilidad.

### 6.2 Figuras

- **FIG-01 [P0]** Insertar por archivo, arrastrar/soltar y pegar desde portapapeles.
- **FIG-02 [P0]** Reemplazar imagen, ajustar dimensiones visualmente, alinear y mantener proporción.
- **FIG-03 [P0]** Título, nota, fuente, texto alternativo e identificador estable.
- **FIG-04 [P0]** Numeración y referencias cruzadas automáticas, incluso tras reordenar figuras.
- **FIG-05 [P0]** Conservar archivo original y representación/exportación adecuada sin degradación acumulativa.
- **FIG-06 [P1]** Opciones comprensibles de colocación: integrada, automática o página propia; documentar el ajuste real del motor LaTeX.
- **FIG-07 [P2]** Subfiguras y composición avanzada.

### 6.3 Ecuaciones

- **EQ-01 [P0]** Editor matemático **visual**: fracciones, raíces, exponentes, subíndices, letras griegas, sumas e integrales básicas.
- **EQ-02 [P0]** Ecuaciones en línea o en bloque; numeración opcional en bloque.
- **EQ-03 [P0]** Edición posterior visual sin reescribir toda la ecuación.
- **EQ-04 [P0]** Identificador estable y referencias cruzadas para ecuaciones numeradas.
- **EQ-05 [P1]** Matrices, alineación multirrenglón y símbolos especializados.
- **EQ-06 [P1]** Edición de código matemático LaTeX opcional, en modo avanzado; nunca requisito para uso habitual.

### 6.4 Otras inserciones

- **INS-01 [P0]** Enlaces, notas al pie, citas extensas, salto de página y separadores estructurales.
- **INS-02 [P1]** Índice automático, lista de figuras, lista de tablas y anexos.
- **INS-03 [P0]** Referencias cruzadas a títulos, figuras, tablas y ecuaciones mediante selección visual del destino.
- **INS-04 [P0]** Los números mostrados se calculan; no se escriben como texto fijo en el documento.
- **INS-05 [P0]** Si falta un destino, mostrar una advertencia legible y nunca sustituirlo silenciosamente por un número incorrecto.

## 7. Plantillas, estilos y propiedades del documento

### 7.1 Administrador

- **PL-01 [P0]** Administración central en **Naberius → Configuración → Plantillas**.
- **PL-02 [P0]** Catálogo integrado: blanco, informe académico, artículo científico, tesis, libro y carta, inicialmente con formatos de ejemplo verificables.
- **PL-03 [P0]** Categorías: integradas, importadas y personales.
- **PL-04 [P0]** Previsualizar, instalar, activar, duplicar, personalizar, restaurar y desinstalar sin afectar documentos existentes.
- **PL-05 [P0]** Asistente de importación para `.tex`, `.cls`, `.sty` y `.zip`: análisis, dependencias, mapeo inicial, documento de prueba y diagnóstico.
- **PL-06 [P0]** Clasificar importaciones como compatibles, parcialmente compatibles o no compatibles; **no prometer soporte universal**.
- **PL-07 [P1]** Soporte progresivo para macros complejas, plantillas editoriales especiales y correspondencias avanzadas de estilos.
- **PL-08 [P0]** Versionado de plantillas; una actualización no cambia un documento existente sin consentimiento.
- **PL-09 [P0]** Evaluar plantillas externas como material no confiable: prevenir ejecución libre de scripts/shell, accesos fuera del área de trabajo y expansión insegura de ZIP.

### 7.2 Estilos estructurados

- **EST-01 [P0]** La plantilla define estilos semánticos, márgenes, tipografía, interlineado, numeración, encabezados y pies.
- **EST-02 [P0]** La personalización del documento modifica solo ese documento, no la plantilla base.
- **EST-03 [P0]** Admitir excepciones locales explícitas, pero respetar propiedades bloqueadas por plantillas estrictas.
- **EST-04 [P0]** Al cambiar de plantilla, preservar contenido, jerarquía, imágenes, citas e identificadores.
- **EST-05 [P0]** Permitir restaurar valores de plantilla y revisar advertencias antes de aplicar cambios incompatibles.
- **EST-06 [P1]** Guardar variantes de formato como plantilla personal y exportarlas para compartir.

### 7.3 Propiedades por documento

- **DOC-01 [P0]** **General:** título, subtítulo, autor(es), institución, fecha, idioma, resumen y palabras clave.
- **DOC-02 [P0]** **Diseño:** plantilla, papel (A4/Carta/oficio si procede), márgenes, tipografía, interlineado y sangrías permitidos.
- **DOC-03 [P0]** **Estructura:** portada, índices, numeración, anexos, encabezados y pies.
- **DOC-04 [P0]** **Referencias:** estilo bibliográfico, idioma de localización y bibliografía al final o en sección indicada.
- **DOC-05 [P0]** **Exportación:** formato, metadatos, destino y opciones según capacidad real.
- **DOC-06 [P0]** Metadatos reutilizables en portada, documento y PDF sin reescribirlos en cada ubicación.

## 8. Bibliografía y citas

### 8.1 Bibliotecas

- **REF-01 [P0]** Biblioteca personal local reutilizable entre documentos.
- **REF-02 [P0]** Biblioteca **integrada en el `.nab`** para asegurar que los documentos se abran sin la biblioteca personal.
- **REF-03 [P0]** Citas como objetos vinculados a identificadores bibliográficos, no como texto estático.
- **REF-04 [P0]** Cuando cambie el registro personal, ofrecer actualización del registro del documento **solo con acción explícita**.
- **REF-05 [P0]** Eliminar o modificar una referencia personal no rompe una cita existente en un documento.
- **REF-06 [P1]** Colecciones, etiquetas, filtros y detección asistida de posibles duplicados.

### 8.2 Ingreso e importación

- **REF-07 [P0]** Crear, revisar y corregir registros manuales de artículos, libros, capítulos, tesis, informes, sitios web, etc.
- **REF-08 [P0]** Importar BibTeX, BibLaTeX, RIS y CSL-JSON, con validación y explicación de campos no representables.
- **REF-09 [P1]** Buscar metadatos por DOI, ISBN, título o autor mediante acceso a red **opcional** y explícito.
- **REF-10 [P0]** No fabricar metadatos faltantes; permitir confirmación y edición antes de guardar.
- **REF-11 [P1]** Adjuntar PDF u otros recursos a la biblioteca personal; si se incrustan en `.nab`, advertir del tamaño.

### 8.3 Citas y estilos

- **CIT-01 [P0]** Insertar referencias con un buscador visual, sin comandos bibliográficos.
- **CIT-02 [P0]** Modalidades: parentética, narrativa, múltiples referencias, páginas, prefijo y sufijo según estilo.
- **CIT-03 [P0]** Bibliografía automática con fuentes citadas, con opción de bibliografía general si el estilo/plantilla lo admite.
- **CIT-04 [P0]** Cambiar estilos bibliográficos regenera citas y bibliografía sin modificar manualmente el contenido.
- **CIT-05 [P0]** Preparar soporte de **APA 7, IEEE, Vancouver y Chicago**, mediante CSL y pruebas representativas de cada estilo.
- **CIT-06 [P0]** Localización al español y variantes de idioma mediante reglas del motor bibliográfico, evitando reemplazos manuales ingenuos.
- **CIT-07 [P1]** Importar estilos `.csl` personalizados y mostrar su origen/versionado.
- **CIT-08 [P2]** Integración con Zotero como fuente opcional, sin convertirlo en dependencia indispensable.

## 9. Formato `.nab`, guardado y recuperación

### 9.1 Contenedor autocontenido

- **NAB-01 [P0]** Un solo archivo `.nab`, portable y autocontenido, preferiblemente contenedor comprimido con manifiesto versionado.
- **NAB-02 [P0]** Datos semánticos del documento, bibliografía, estilos, metadatos, plantilla efectiva e imágenes dentro del archivo.
- **NAB-03 [P0]** Identificadores persistentes para documento, secciones, figuras, tablas, ecuaciones y referencias.
- **NAB-04 [P0]** Esquema interno versionado, verificable y migrable; comprobar integridad al abrir.
- **NAB-05 [P0]** No depender de rutas absolutas para recursos esenciales. Una fuente o paquete de sistema no incorporado se identifica y se comunica claramente.
- **NAB-06 [P0]** Proteger la extracción/lectura frente a archivos corruptos, rutas peligrosas, recursos sobredimensionados y contenido activo no confiable.
- **NAB-07 [P0]** Documentar el formato para evitar encierro irreversible en un contenedor propietario.

### 9.2 Guardado y protección de trabajo

- **GUA-01 [P0]** Autoguardado sin bloquear la escritura; consolidación aproximada a los **2 s de inactividad**, sujeta a validación.
- **GUA-02 [P0]** ⌘S fuerza guardado consistente; barra de estado: guardando, guardado, error.
- **GUA-03 [P0]** Escritura atómica (temporal + reemplazo seguro), evitando dejar un `.nab` parcialmente sobrescrito.
- **GUA-04 [P0]** Estado de recuperación duradero entre consolidaciones, con restauración tras cierre inesperado.
- **GUA-05 [P0]** Detectar ediciones externas simultáneas; jamás sobrescribir conflictos en silencio.
- **GUA-06 [P0]** Si falla el disco o la escritura, informar, conservar el estado en memoria y ofrecer guardar copia en otro destino.
- **GUA-07 [P1]** Historial persistente de versiones, administrado fuera del `.nab` principal, con política de retención y vista de restauración.
- **GUA-08 [P0]** Exportar o compilar nunca modifica ni corrompe el documento maestro.

## 10. Exportación y composición

- **EXP-01 [P0]** PDF mediante motor LaTeX, con plantilla, imágenes, citas, ecuaciones, numeración y metadatos pertinentes.
- **EXP-02 [P0]** Exportar proyecto LaTeX portable: `.tex`, bibliografía y dependencias/recursos exportables; ZIP cuando corresponda.
- **EXP-03 [P0]** Exportar bibliografía a BibTeX y CSL-JSON.
- **EXP-04 [P1]** DOCX con conservación de texto y estructura compatible, informando diferencias de maquetación.
- **EXP-05 [P1]** Markdown estructurado, con aviso sobre elementos sin representación equivalente.
- **EXP-06 [P2]** HTML o formatos de publicación adicionales.
- **EXP-07 [P0]** Vista previa del PDF bajo demanda y actualización no bloqueante; no recompilar por cada tecla.
- **EXP-08 [P0]** Los errores se traducen a mensajes comprensibles; registros técnicos disponibles en «Detalles».
- **EXP-09 [P0]** Si falla la compilación, la edición y el guardado continúan funcionando.
- **EXP-10 [P0]** Distinguir fidelidad del PDF final de la paginación orientativa dentro del editor.
- **EXP-11 [P0]** Procesar documentos y plantillas no confiables en área restringida, sin `shell-escape` ni ejecución de scripts por defecto.

## 11. Marca, diseño y consistencia con METATRON, RAZIEL y PAIMON

### 11.1 Revisión obligatoria de las aplicaciones de referencia

**Antes de diseñar o implementar la identidad de Naberius, revisar directamente los repositorios, código visual, recursos gráficos, capturas, documentación y flujos existentes (si están disponibles):**

1. **METATRON** — <https://github.com/AD0441/METATRON>
   - Buscar y estudiar `docs/BRAND.md`, `script/make_brand.swift`, recursos de icono, navegación, ajustes, paletas y componentes reales.
2. **RAZIEL** — nombre visible asociado a **RadioWorkbench**: <https://github.com/AD0441/RadioWorkbench>
   - Revisar navegación, paneles, controles de macOS, distribución, créditos, estados visuales y README. **RAZIEL** es la forma que figura en la documentación disponible, aunque la solicitud inicial lo llamó «Raizel».
3. **PAIMON** — <https://github.com/AD0441/PAIMON>
   - Revisar paleta, estructura, ventanas, controles, iconografía, presentación del producto y documentación.

**Obligatorio:** informar qué patrones se han comprobado realmente, cuáles no se encontraron y cuáles se proponen adaptar. **No inventar códigos hexadecimales, fuentes o componentes** de las aplicaciones si no aparecen en el material revisado. No modificar estos tres proyectos, que son únicamente referencias.

### 11.2 Diseño visual de Naberius

- **VIS-01 [P0]** Crear una **familia visual coherente** con las otras aplicaciones del autor, pero una identidad independiente para Naberius.
- **VIS-02 [P0]** Analizar colores reales de las referencias y construir **tokens semánticos**: fondo, superficie, texto, secundario, acento, borde, selección, éxito, advertencia y error; documentar variantes claro/oscuro.
- **VIS-03 [P0]** **Modo claro, oscuro y seguir sistema**; cambios inmediatos y persistencia de preferencia.
- **VIS-04 [P0]** Contraste accesible, foco visible, tamaños legibles, barras sobrias y uso del color solo como apoyo —nunca como único indicador—.
- **VIS-05 [P0]** Minimizar saturación cromática y ornamento: amplio espacio en blanco, jerarquía tipográfica, iconos de sistema y paneles discretos.
- **VIS-06 [P0]** Crear **icono original de Naberius**, evocando la escritura y opcionalmente una interpretación geométrica del sigilo de Naberius del *Ars Goetia*. No copiar sin comprobar derechos/licencias ni reutilizar el icono de METATRON.
- **VIS-07 [P0]** Verificar legibilidad del símbolo en 16, 32, 64, 128, 256 y 1024 px; adaptar ópticamente tamaños pequeños si es necesario.
- **VIS-08 [P0]** Identidad reproducible: SVG editable, variantes claro/oscuro, PNG de alta resolución, `AppIcon.icns` y script o procedimiento documentado para regenerar activos.
- **VIS-09 [P0]** Definir iconografía y ventanas consistentes: inicio, editor, biblioteca, configuración, inspector, exportador y diálogos de error.
- **VIS-10 [P0]** Barra lateral con navegación, estados vacíos útiles, indicación de archivo actual y un pie discreto para Configuración, Acerca de, crédito y donaciones.
- **VIS-11 [P0]** Firma visible: **«Creado por Sebastián Pastén F.»** en Acerca de y/o pie de la barra lateral, siguiendo el patrón verificado en las referencias.
- **VIS-12 [P0]** Enlace de apoyo voluntario **<https://ko-fi.com/sebastianpasten>**, accesible desde Acerca de / Ayuda / pie de barra lateral, **solo al hacer clic**.
- **VIS-13 [P0]** No mostrar anuncios, pop-ups de donaciones, bloqueos funcionales ni solicitudes persistentes de contribución.
- **VIS-14 [P1]** Documentar identidad en `docs/BRAND.md` y mantener fuentes editables y avisos de terceros.
- **VIS-15 [P0]** Capturas de modos claro y oscuro y pruebas de icono en Dock, Finder y diferentes escalas.
- **VIS-16 [P0]** Interfaz en español; externalizar cadenas para localización. Inglés como objetivo P1 o P0 si el coste es bajo y se verifica.

### 11.3 Entregable previo de diseño

Codex deberá producir una **auditoría comparativa breve** de METATRON, RAZIEL y PAIMON con: color/paletas reales, tipografías, barras laterales, controles, dark mode, iconos, estados vacíos, créditos, enlaces Ko-fi, decisiones adoptadas y diferencias justificadas para Naberius. Esta auditoría precede a fijar la identidad visual definitiva.

## 12. Privacidad, seguridad, accesibilidad y rendimiento

- **CAL-01 [P0]** Sin cuenta, registro, nube ni conexión obligatoria para crear, escribir, guardar y exportar documentos con dependencias disponibles.
- **CAL-02 [P0]** Operaciones de red (DOI/ISBN, actualizaciones, enlaces externos) explícitas y separadas del editor; informar si requieren conexión.
- **CAL-03 [P0]** No telemetría oculta ni envío de contenido a servicios de IA.
- **CAL-04 [P0]** Protección frente a plantillas, archivos comprimidos y documentos externos maliciosos.
- **CAL-05 [P0]** Soporte de teclado y VoiceOver, controles etiquetados, contraste y enfoque visibles.
- **CAL-06 [P0]** Inicio y escritura responsivos en un Mac Apple Silicon; probar al menos documentos cortos y extensos. Si se dispone de un Mac M1 con 8 GB, usarlo como escenario de referencia medido, no como garantía supuesta.
- **CAL-07 [P0]** Compilación, exportación, indexación y recuperación fuera del hilo principal; operaciones cancelables cuando sea razonable.
- **CAL-08 [P0]** Evitar pérdida de contenido por fallos de vista previa, bibliografía, plantilla o exportación.
- **CAL-09 [P0]** Respetar licencias de librerías, motores, estilos y recursos iconográficos; conservar avisos requeridos.

## 13. Arquitectura orientativa: definir después de elegir skills

**No fijar todavía un stack irreversible.** Evaluar, de acuerdo con las skills que luego indique el usuario:

- UI macOS: alternativa nativa **SwiftUI/AppKit** o arquitectura de escritorio ligera que pueda integrar un editor rico de calidad.
- Editor semántico: evaluar **ProseMirror/Tiptap** u otra solución robusta para selección, tablas, historial, pegado y nodos académicos.
- Matemáticas: componente visual especializado (por ejemplo, motor compatible con representación LaTeX) sin necesidad de escribir comandos.
- Composición PDF: **Tectonic u otro motor LaTeX validado**; compatibilidad real con clases/paquetes es criterio decisivo.
- Transformación e interoperabilidad: **Pandoc / CSL** o bibliotecas equivalentes con pruebas de citas y exportaciones.
- Biblioteca personal: almacenamiento local transaccional, por ejemplo SQLite; `.nab` como documento autocontenido separado.
- Comunicación asíncrona entre UI, autoguardado, biblioteca y procesos de exportación.
- Pruebas automatizadas del esquema `.nab`, serialización, citas, referencias cruzadas, importación y round-trip.

**Nota:** seleccionar la arquitectura con base en prototipos técnicos y licencias, no únicamente en su popularidad.

## 14. Fases de entrega

### Fase 0 — Investigación y validación técnica

- Auditar METATRON, RAZIEL y PAIMON y documentar identidad visual verificable.
- Validar editor semántico con doble modo, almacenamiento `.nab`, fórmula visual, citas CSL y compilación LaTeX.
- Evaluar stack final **después** de recibir instrucciones de skills del usuario.

### Fase 1 — MVP de escritura y publicación (P0)

- Inicio, documentos recientes, nuevo/abrir, dos modos, barra contextual, inspector.
- Texto semántico, títulos, listas, búsqueda/reemplazo y ortografía básica.
- `.nab` portable, autoguardado, recuperación, biblioteca personal y del documento.
- Tabla, figura, ecuación visual básica, citas, referencias cruzadas y plantillas integradas.
- Importación guiada inicial de plantillas, PDF y proyecto LaTeX, BibTeX/CSL-JSON.
- Identidad original, claro/oscuro, accesibilidad básica y Ko-fi discreto.

### Fase 2 — Interoperabilidad y productividad (P1)

- Proyectos/colecciones, favoritos, búsqueda avanzada, historial persistente.
- Mejoras a tablas/ecuaciones, DOCX/Markdown, importación DOI/ISBN en línea.
- Plantillas externas más complejas, estilos CSL personalizados, inglés, mejoras de accesibilidad.

### Fase 3 — Ecosistema ampliado (P2)

- Integración Zotero, revisión gramatical opcional, búsqueda transversal, HTML y funciones de colaboración si se justifican.

## 15. Pruebas de aceptación críticas

La implementación debe demostrar como mínimo los siguientes casos, con pruebas reproducibles:

1. **AC-01:** crear un documento, escribir, cerrar, reabrir y comprobar contenido, estilos, cursor lógico e imágenes.
2. **AC-02:** alternar 20 veces entre páginas y continuo sin perder contenido, selección ni historial de deshacer.
3. **AC-03:** aplicar Título 1 y Título 2 mediante controles; el índice se actualiza y Enter vuelve al párrafo.
4. **AC-04:** insertar y reordenar tres figuras, dos tablas y una ecuación; las referencias cruzadas conservan su destino y actualizan números.
5. **AC-05:** insertar referencias narrativas y parentéticas; cambiar APA 7 por IEEE; regenerar citas y bibliografía sin editar texto manualmente.
6. **AC-06:** copiar un `.nab` a otro director o equipo compatible; abrirlo con imágenes, referencias, estilos y estructura íntegros, sin acceso a biblioteca personal.
7. **AC-07:** simular interrupción de guardado; debe recuperarse una versión íntegra y reportarse la última operación no persistida si la hubiera.
8. **AC-08:** provocar error de LaTeX; continuar escribiendo y guardando normalmente, con mensaje comprensible.
9. **AC-09:** modificar una plantilla y confirmar que no altera automáticamente otros documentos ni la plantilla original.
10. **AC-10:** importar un paquete de plantilla compatible y uno incompatible; recibir diagnóstico claro, sin ejecutar código externo.
11. **AC-11:** buscar/reemplazar términos en texto y pie de figura, con deshacer correcto y sin corromper nodos de cita.
12. **AC-12:** comprobar modo claro/oscuro, VoiceOver, navegación por teclado, contraste e icono en múltiples tamaños.
13. **AC-13:** abrir el enlace Ko-fi únicamente por interacción explícita; ninguna llamada automática al iniciar o editar.
14. **AC-14:** detectar y gestionar un archivo reciente inexistente sin borrar archivos ajenos.
15. **AC-15:** comprobar exportación PDF, proyecto LaTeX y formatos bibliográficos con recursos incluidos; registrar advertencias de compatibilidad.

## 16. Entregables documentales esperados al implementar

- `README.md` con descripción honesta, instalación, captura real, limitaciones, privacidad y enlaces pertinentes.
- `docs/REQUIREMENTS.md` o equivalente basado en esta especificación y matriz P0/P1/P2.
- `docs/ARCHITECTURE.md`, `docs/DOCUMENT_FORMAT.md`, `docs/TEMPLATES.md`, `docs/BIBLIOGRAPHY.md`.
- `docs/BRAND.md` con referencias verificadas, paletas, modo oscuro, icono y procedimiento de reproducción.
- `docs/TESTING.md`, `docs/PRIVACY.md`, `docs/LIMITATIONS.md`, `CHANGELOG.md`, `THIRD_PARTY_NOTICES.md`.
- Código y recursos del producto nuevo **sin modificar METATRON, RAZIEL/RadioWorkbench ni PAIMON**.
- Build local reproducible, pruebas, datos sintéticos de demostración, instrucciones de empaquetado y estado real de firma/notarización de macOS, si aplica.
- Reporte por fase: **implementado / probado / pendiente / limitación conocida**; nunca declarar funciones verificadas sin ejecutarlas.

## 17. Restricciones de proceso para Codex

1. **Esperar las skills que indicará el usuario** antes de elegir el flujo definitivo de trabajo o generar el prompt operacional.
2. Inspeccionar las referencias de diseño, las dependencias y la factibilidad técnica antes de establecer patrones visuales o stack.
3. No realizar cambios en repositorios ajenos de referencia; el trabajo corresponde exclusivamente al proyecto Naberius.
4. No introducir funciones extra que contradigan el enfoque de escritura, local-first y minimalismo.
5. No sacrificar integridad del documento por fidelidad visual ni esconder errores de exportación.
6. No solicitar claves, permisos de publicación o acceso a servicios externos si no son necesarios para las etapas autorizadas.
7. Plantear alternativas documentadas ante incompatibilidades reales y marcar explícitamente las funciones que aún no se han implementado.

---

**Criterio rector:** *Naberius debe hacer que escribir sea lo importante; la plantilla, la tipografía, las citas y LaTeX deben trabajar para el autor, no al revés.*
