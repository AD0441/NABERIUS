# Marca Naberius

Registro de la implementación 0.3.0, revisado el 30 de octubre de 2026. Naberius pertenece a la familia visual de METATRON, RAZIEL y PAIMON, ampliada para un editor académico nativo de macOS. La auditoría de la familia está en [BRAND_AUDIT.md](BRAND_AUDIT.md); el sistema visual y sus tokens están en [DESIGN.md](../DESIGN.md).

La autoría se reproduce literalmente como **Creado por Sebastián Pastén F.** El apoyo voluntario se rotula **Apoyar en Ko-fi** y conserva el destino comprobado en las tres aplicaciones de referencia: [Ko-fi de la familia](https://ko-fi.com/C0C51WQ1T0). `Brand.author` y `Brand.donation` son la fuente de estos valores. No se afirma que la aplicación sea una entrega completa de P0 ni una distribución notarizada: el bundle local es versión 0.3.0, build 3, con firma ad hoc.

## Sello y procedencia

El símbolo es una interpretación geométrica original del sello histórico de Naberius. Se consultaron la [lámina de The Goetia (Mathers/Crowley, 1904)](https://www.fromoldbooks.org/Mathers-Goetia/pages/024-Seal-of-Naberius/) y la [ficha de dominio público en Wikimedia Commons](https://commons.wikimedia.org/wiki/File:24-naberius-sigilo-ars-goetia.svg), registradas en la auditoría. Esas referencias documentan la procedencia iconográfica; no se redistribuye el escaneo ni se incluye como recurso de la aplicación.

`NaberiusMark` y el generador dibujan un asta, dos barras y una curva abierta con dos lóbulos. Se eliminan los círculos y trazos interiores del símbolo anterior. Extremos y uniones son redondos. El dibujo usa el campo `16 18 64 64`, compartido con los SVG. Conservar sus proporciones al escalar; no estirar ejes por separado ni reutilizar el sello de otra aplicación de la familia.

En la app, el sello del pie mide 28 × 28pt con trazo de 1.2pt; Inicio usa 82 × 82pt y Acerca de 100 × 100pt, ambos con trazo de 2pt. La palabra NABERIUS del pie es sistema, 14pt semibold, tracking 1pt; en Acerca de es 26pt semibold, tracking 2pt.

## Tintas y apariencia

| Recurso o rol | Valor de origen | Uso |
| --- | --- | --- |
| Acento de interfaz en Claro | sRGB (0.137, 0.29, 0.376, 1) | `Brand.accent`, resuelto por Aqua |
| Acento de interfaz en Oscuro | sRGB (0.51, 0.71, 0.77, 1) | `Brand.accent`, resuelto por Dark Aqua |
| Símbolo claro exportado | `#234A60` | `symbol-light.svg`, tinta sobre fondo claro |
| Baldosa del icono | `#111B26` | Azul profundo |
| Símbolo oscuro e icono | `#E8E6D9` | Marfil sobre fondo oscuro |

Los recursos SVG tienen tinta fija. El sello dibujado dentro de la app usa el acento adaptativo, incluida su variante oscura más luminosa. No reemplazarlo automáticamente por el marfil del archivo exportado. La interfaz usa `windowBackgroundColor`, `controlBackgroundColor`, `underPageBackgroundColor`, `textBackgroundColor`, `labelColor` y `separatorColor` de AppKit, además de estilos SwiftUI semánticos; estas superficies no se sustituyen por las tintas del icono.

## Recursos entregados

| Ruta | Contenido |
| --- | --- |
| `Resources/Brand/symbol-light.svg` | Sello vectorial para fondos claros |
| `Resources/Brand/symbol-dark.svg` | Sello vectorial marfil para fondos oscuros |
| `Resources/Brand/app-icon.svg` | Icono vectorial de referencia a 1024 × 1024 |
| `Resources/Brand/app-icon.png` | Icono PNG a 1024 × 1024 con transparencia exterior |
| `Resources/Brand/icon-{16,32,64,128,256,512,1024}.png` | Exportaciones PNG por tamaño |
| `Resources/AppIcon.iconset/` | Tamaños 16, 32, 128, 256 y 512, cada uno con variante @2x |
| `Resources/AppIcon.icns` | Contenedor ICNS incluido en el bundle local |
| `~/Applications/Naberius.app/Contents/Resources/AppIcon.icns` | Copia incluida en la aplicación local; también dentro de `dist/Naberius.zip` |

El icono ocupa una baldosa de 874 × 874 dentro del campo de 1024, con origen (75, 75) y radio 194. Su fondo es opaco dentro de la baldosa y transparente fuera. El sello se dibuja en marfil. El generador conserva la geometría completa y refuerza el trazo normalizado: 7.2 a 16px, 4.8 a 32px, 4 a 64px y 3.4 en tamaños mayores. No usar un reescalado del PNG grande como sustituto de estas exportaciones pequeñas.

## Regeneración

Desde la raíz del proyecto, con las herramientas de desarrollo de Apple y Python 3 disponibles:

```sh
xcrun swift script/make_brand.swift
python3 script/make_icns.py
```

El primer comando produce los SVG, los PNG y el iconset. El segundo empaqueta los PNG en `Resources/AppIcon.icns`. La geometría de `Sources/Naberius/Brand.swift` y la de `script/make_brand.swift` se mantienen en paralelo; si se cambia el sello, revisar ambos dibujos y las salidas pequeñas.

Para volver a empaquetar la app local con el ICNS regenerado:

```sh
./script/build_and_run.sh --build-only
```

El empaquetador solo genera iconos automáticamente cuando falta el ICNS; para actualizar recursos existentes, ejecutar antes los dos comandos explícitos. El script firma y verifica el bundle en una carpeta temporal y entrega `dist/Naberius.zip`. Al ejecutarlo sin `--build-only`, instala y verifica además `~/Applications/Naberius.app`, con acceso desde `Naberius.app` en la raíz. Así evita que los metadatos de sincronización del Escritorio alteren el bundle ejecutable. Estos comandos no producen notarización.

## Evidencia y límites

Se leyeron `Brand.swift`, `WorkspaceView.swift`, `NativeEditor.swift`, `NaberiusApp.swift`, `Sheets.swift`, los generadores y la auditoría. Se inspeccionaron las capturas clara y oscura de `.impeccable/review/`, que muestran el sello y pie de marca en el editor, el acento adaptativo, la navegación de ancho completo y el menú de zoom compacto. El revisor puntuó esas dos correcciones como resueltas y emitió `ship` limitado a ellas. Las capturas y ese veredicto no acreditan todos los flujos, los requisitos P0 ni una revisión integral de accesibilidad.

## Tipografía documental 0.2.0

La interfaz conserva los roles de sistema de la familia. El documento usa Latin Modern Roman incluida (cuatro estilos originales, licencia GUST), tanto en TextKit como en fontspec; los títulos documentales ya no usan la fuente de interfaz. La revisión y los PDF reales están en TYPESETTING.md. La autoría y Ko-fi permanecen iguales; el sello se simplifica en 0.3.0.

## Terminación 0.3.0

Se inspeccionaron las exportaciones de 256/1024 y la resolución del icono instalado mediante NSWorkspace, guardada en screenshots/system-app-icon.png. Las capturas de tablas claras/oscuras muestran el sello simplificado en el pie junto a autoría y Ko-fi. El control directo del Dock agotó el tiempo; no se afirma disponer de una captura de su baldosa en pantalla. El recurso ICNS y la clave CFBundleIconFile del bundle corresponden a la marca nueva.
