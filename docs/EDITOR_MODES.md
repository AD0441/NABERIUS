# Escritura y PDF

Naberius ofrece tres vistas desde el selector sobre el documento:

- **Escritura:** página orientativa o lienzo continuo editable. Usa Latin Modern o la familia y tamaño detectados en el paquete. Las cabeceras editoriales, columnas y saltos definitivos pertenecen al PDF.
- **Editor + PDF:** escritura a la izquierda y PDF real de Tectonic a la derecha. Al entrar, ambas áreas reciben un reparto equilibrado; el divisor cambia sus anchos y su proporción se conserva al alternar vistas. La composición mantiene el foco y la selección; el PDF anterior permanece visible hasta recibir el resultado nuevo.
- **PDF:** prueba a todo el ancho, con navegación, zoom, registro y guardado.

En **Configuración → General → Escritura y PDF** se elige la vista al abrir, la actualización automática y la pausa de 2, 4 u 8 segundos. El interruptor **Automático** de la vista dividida cambia la misma preferencia. **Actualizar PDF / ⇧⌘R** sigue disponible con la automatización desactivada.

La composición automática solo se programa cuando hay cambios, está seleccionada la vista dividida y la ventana está activa. Escribir otra vez cancela la espera y el trabajo automático obsoleto. No hay sondeo continuo ni composición por pulsación. Los errores automáticos aparecen dentro de la vista; no interrumpen con una alerta. La descarga inicial de paquetes sigue siendo una acción explícita en Configuración → Composición.

**Apariencia de escritura** permite alternar página/lienzo y limitar el editor al ancho orientativo de una columna. En Propiedades de un documento editorial se puede ajustar fuente y cuerpo del editor sin cambiar el diseño que define su clase LaTeX. Esta superficie editable aproxima el resultado; el PDF es la prueba exacta y no se edita directamente.

Los diseños libres admiten una o dos columnas, separación y márgenes por lado. Hay una plantilla integrada de artículo en dos columnas. En paquetes editoriales, **Crear diseño libre** produce una variante separada y configurable; no certifica el formato de la revista. **Completar recursos…** incorpora clases, estilos o un ZIP adicional conservando el documento principal.
