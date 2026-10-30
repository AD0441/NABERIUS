# Plantillas — 0.2.0

Configuración → Plantillas reúne integradas, importadas y personales. Cada documento guarda su copia efectiva; actualizar o desinstalar una plantilla no modifica archivos existentes. Se puede duplicar, personalizar, restaurar, desinstalar y elegir la plantilla predeterminada para documentos nuevos.

| Plantilla | Clase LaTeX real | Estructura |
| --- | --- | --- |
| En blanco | article | Párrafos y secciones |
| Informe académico | report | Capítulos y apartados |
| Artículo científico | article | Resumen, secciones y bibliografía |
| Tesis | report | Portada, capítulos y apartados |
| Libro | book | Portada, capítulos y sangría de párrafos |
| Carta | letter | Destinatario, saludo, despedida y firma |

Las seis clases/formats se compilaron realmente con Tectonic. No son certificación de una norma universitaria o editorial. Los PDF y fuentes de prueba están en `typesetting/`.

Propiedades: Latin Modern incluida y familias de sistema permitidas, cuerpo, interlineado, papel, margen uniforme, sangría, espacio entre párrafos, portada, numeración de títulos, encabezado, pie y número de página. Los anexos usan un estilo semántico que activa `\appendix`; los índices se componen a partir de la jerarquía. En informe, tesis y libro, Título 1 corresponde a un capítulo. La numeración de figuras, tablas y ecuaciones permanece global para conservar las referencias del modelo.

Una plantilla puede bloquear todo su diseño o proteger propiedades concretas. Se administra desde Personalizar plantilla; el inspector del documento deshabilita esas propiedades. Cambiar de plantilla sigue siendo una acción explícita y reversible.

El asistente acepta TEX, CLS, STY y ZIP. Limita cantidad, tamaño y expansión de miembros; rechaza rutas peligrosas y enlaces simbólicos. Nunca ejecuta el original. Mapea las clases conocidas, papel, cuerpo, márgenes básicos y familias admitidas; enumera paquetes y avisa de clases o fuentes externas no incorporadas. Se instala una variante semántica y se puede abrir un documento de prueba. Compatibilidad progresiva no significa reconstrucción universal de macros.

Pendientes: márgenes asimétricos, clases editoriales ajenas y mapeos de macros complejos. No se instalan ejecutables ni se descargan dependencias al analizar una plantilla.
