# Bibliografía — 0.3.0

Los registros viajan en `.nab`. La biblioteca personal es local y las transferencias al documento son explícitas. Editar esa biblioteca no modifica automáticamente documentos existentes.

citeproc-js se ejecuta en JavaScriptCore con APA 7, IEEE, Vancouver (NLM citation-sequence) y Chicago autor-fecha; locales es-ES/en-US. Se conservan citas múltiples, narrativa/parentética, localizador, prefijo y sufijo. No se consultan automáticamente DOI, ISBN ni servicios externos.

## Importación revisable

Importar abre un informe antes de añadir registros. Se puede seleccionar cada entrada, revisar advertencias y desplegar datos originales. El formulario de una referencia conserva también el acceso a sus datos importados.

BibTeX/BibLaTeX admite llaves anidadas, campos entre comillas, entradas entre paréntesis, comentarios, abreviaturas `@string` (incluidas definiciones posteriores), concatenación `#`, `crossref` y `xdata`. Resuelve herencia compatible, nombres institucionales, sufijos, partículas, acentos TeX comunes y fechas. Las abreviaturas desconocidas y los ciclos producen avisos; no se inventa metadata. La entrada original y sus campos resueltos permanecen en el registro. Campos sin correspondencia CSL se conservan y se señalan expresamente.

CSL-JSON conserva los campos originales, nombres estructurados, fechas completas y propiedades adicionales. RIS conserva el registro original y los tags; avisa de tags sin correspondencia. Latin-1 se convierte a Unicode con aviso cuando UTF-8 no resulta válido. Límite de entrada: 10 MB; BibTeX/CSL-JSON: hasta 10.000 entradas. La herencia y la expansión tienen límites adicionales para rechazar archivos patológicos.

No es un intérprete completo de BibLaTeX. Los preámbulos se omiten con aviso y no se incorporan a LaTeX; conviene guardar el archivo original si depende de ellos. Los comandos desconocidos se conservan como texto, sin ejecutarlos. Los campos repetidos usan el último valor con aviso y conservan la entrada original.

## Conservación y exportación

| Destino | Conservación |
| --- | --- |
| `.nab` | Campos del formulario, CSL estructurado, entrada original, campos adicionales y advertencias. |
| CSL-JSON | Campos CSL completos y metadata de procedencia en `custom.naberius-import`. La reimportación en Naberius recupera esos datos. Otros programas pueden ignorar esa extensión. |
| BibTeX desde BibTeX/BibLaTeX | Tipo y clave originales cuando son válidos, campos resueltos y campos adicionales. La herencia se aplana para no depender de padres no seleccionados. Actualiza los campos editados; no es una copia byte a byte. |
| BibTeX desde CSL-JSON/RIS | Campos representados en el formulario. Las propiedades adicionales siguen en `.nab` y CSL-JSON, pero no se trasladan a BibTeX. El formulario lo advierte. |

Cambiar un campo representado reemplaza su valor efectivo en CSL; dejar intacto autor o año conserva nombres estructurados y fechas completas. Editar el año en BibTeX elimina `date`/`month` anteriores de esa exportación para no reintroducir una fecha contradictoria. Los datos originales siguen disponibles en `.nab`/CSL-JSON.

Los datos bibliográficos importados nunca se ejecutan. La composición PDF usa valores escapados; el archivo BibTeX exportado conserva comandos originales como datos para revisión en herramientas externas. No debe interpretarse la exportación como validación de esos comandos.

Zotero, estilos CSL propios y un editor de todos los campos extendidos quedan para después. Las licencias y autores de estilos/locales permanecen en sus XML y en THIRD_PARTY_NOTICES.md.
