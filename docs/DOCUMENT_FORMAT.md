# Formato .nab v1

Un .nab es un único archivo binario autocontenido, no una carpeta ni una dependencia de la biblioteca personal.

| Campo | Representación |
| --- | --- |
| Cabecera | UTF-8 `NABERIUS\0` + `1\n` (11 bytes) |
| Tamaño del JSON | UInt64 big-endian (8 bytes) |
| Integridad | SHA-256 del JSON sin comprimir (32 bytes) |
| Contenido | JSON UTF-8 comprimido con LZFSE de Apple |

El JSON tiene `schemaVersion=1`, UUID del documento, metadatos, copia efectiva de plantilla, bloques, nodos académicos, assets con Data base64, referencias, cursor UTF-16 y fecha de modificación. Los bloques contienen UUID, estilo y marcas de texto (negrita, cursiva, super/subíndice, enlace o UUID de objeto). Las imágenes tienen nombre informativo y UUID: no dependen de rutas externas. TIFF conserva el original junto a una representación PNG de trabajo.

Se rechazan versiones desconocidas, checksum incorrecto, identificadores duplicados, referencias a recursos ausentes y dimensiones inseguras. Límites: 128 MB de JSON descomprimido, 32 MB por imagen/representación y 80 MB de recursos combinados. No se extraen rutas arbitrarias del archivo. El checksum detecta corrupción; no es firma de autenticidad.

El guardado usa Data.write(.atomic) y comprueba la huella del archivo leído antes de sobrescribir. Un cambio externo produce un conflicto y ofrece guardar copia. La protección no sustituye la coordinación entre herramientas externas que escriban simultáneamente sin respetar bloqueos.

## Recuperación

`~/Library/Application Support/Naberius/Recovery/<UUID>.nab` es el snapshot. `<UUID>.nab.journal` contiene transacciones JSON por línea, con bloques modificados, orden y propiedades cambiadas. Cada transacción se sincroniza a disco desde el actor de almacenamiento. Los checkpoints sustituyen el snapshot atómicamente y consolidan el diario. Al recuperar se reproducen solo líneas completas; una última transacción truncada se descarta. No se promete recuperar bytes que todavía no llegaron al sistema de archivos.

## Intercambio

El proyecto LaTeX exportado incluye main.tex, references.bib, references.json y assets/. Las cuatro fuentes Latin Modern y su licencia se incluyen en fonts/. Los motores y las familias de sistema opcionales no se incluyen. Abrir en otro Mac conserva los datos, pero reproducir el PDF exige un motor y las fuentes declaradas. El esquema está en Sources/NaberiusCore/Document.swift; la implementación del contenedor en Archive.swift.

## Extensiones compatibles de 0.2.0

La plantilla admite layout y lockedProperties opcionales; los archivos antiguos sin esos campos siguen siendo legibles. layout registra clase LaTeX, sangría, espacio entre párrafos, encabezado/pie, numeración de página y correspondencia. El estilo appendix y el nodo separator son semánticos. Las versiones antiguas de la aplicación no conocen esos valores y deben actualizarse antes de abrir documentos que los usen.

El portapapeles propio utiliza un contenedor .nab con la selección y solo sus objetos, imágenes y referencias necesarios. Al pegar se clonan UUID y se reconectan destinos internos; los recursos idénticos se reutilizan. Un destino no copiado entre documentos se marca como ausente. No se incluyen rutas de imágenes ni una dependencia de la biblioteca personal.
