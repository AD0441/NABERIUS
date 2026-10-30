# Límites de la versión 0.3.0

Esta entrega es una primera versión local funcional. No se declara terminado todo el alcance P0 de la especificación.

- La vista páginas es orientativa. Usa una hoja de ancho acotado, márgenes y separaciones; no replica la composición de LaTeX. Los cortes explícitos se representan mediante un marcador semántico.
- Papel disponible: A4, Carta y Legal. El formato Oficio de 13 pulgadas no está incorporado.
- Las tablas se editan directamente con doble clic y navegación Tab/⇧Tab/Intro. Hay desplazamiento y vista abreviada de ocho filas, sin eliminar datos. El PDF usa longtable para tablas extensas. No hay celdas combinadas; una celda individual más alta que una página no se divide automáticamente por longtable. Las pruebas cubren 90 filas en cuatro clases, sin equivaler a cualquier combinación posible de contenido.
- Las ecuaciones ofrecen estructuras básicas mediante campos y símbolos. No hay composición anidada arbitraria, matrices ni alineaciones complejas. La vista de estructura se identifica como aproximada hasta pulsar Componer con LaTeX; entonces el inspector y el lienzo usan la salida matemática real. El PDF completo siempre compone con LaTeX.
- Las seis plantillas usan clases reales article/report/book/letter, con cabeceras, pies y anexos. Los ejemplos no acreditan conformidad con una norma universitaria/editorial; faltan márgenes asimétricos y opciones avanzadas de índices.
- Las plantillas externas se convierten en variantes semánticas seguras. Las macros/clases originales no se ejecutan ni se reconstruyen universalmente.
- El pegado RTF conserva énfasis compatible normalizado; HTML/Markdown puede degradarse a texto. Los fragmentos entre documentos Naberius sí llevan objetos, imágenes y referencias; un destino externo no copiado queda advertido como ausente. No es importación semántica completa desde Word.
- La importación bibliográfica ofrece revisión previa y conserva datos originales/adicionales. Admite @string, concatenación y herencia compatibles; no interpreta todas las extensiones BibLaTeX. Omite preámbulos con aviso. BibTeX desde RIS/CSL exporta los campos del formulario; .nab y CSL-JSON conservan los datos adicionales. Ver BIBLIOGRAPHY.md.
- Tectonic se detecta en el sistema o se selecciona manualmente. No se incluye un motor autónomo con todos sus paquetes. La primera preparación necesita red explícita; después puede componerse sin conexión con dependencias en caché.
- No hay DOCX, Markdown, sincronización, Zotero, búsqueda de DOI/ISBN, proyectos, reorganización completa de secciones ni colaboración en esta versión.
- El editor comparte una sesión en las ventanas de la aplicación. Los documentos independientes en ventanas/pestañas requieren una fase posterior.
- El catálogo español está incluido; la traducción al inglés y la externalización completa de mensajes dinámicos quedan pendientes.
- VoiceOver se apoya en AppKit/SwiftUI y se inspeccionó el árbol de accesibilidad. Falta la auditoría manual completa con lector de pantalla y los objetos académicos requieren descripciones accesibles más ricas.
- La app se firma ad-hoc para uso local; no tiene Developer ID, notarización ni instalador de distribución.

La matriz STATUS.md distingue lo implementado, la evidencia ejecutada y lo pendiente. Las pruebas no se presentan como certificación de todos los requisitos.
