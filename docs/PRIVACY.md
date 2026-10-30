# Privacidad

Naberius no crea cuentas ni envía documentos, bibliografía o imágenes a servicios remotos. No incluye analítica, publicidad ni IA. Escribir, guardar, recuperar e importar funciona localmente.

Las únicas salidas de red previstas son el enlace Ko-fi al pulsarlo y, por acción explícita en Configuración → Composición, las descargas de paquetes que realiza Tectonic. Ese motor consulta su repositorio tipográfico, no un servicio de composición al que subir el documento.

Los datos de usuario se almacenan en los .nab elegidos y en `~/Library/Application Support/Naberius/` (recientes, biblioteca, plantillas y recuperación). Los archivos temporales de exportación se crean en el directorio temporal del sistema. No contienen credenciales. Las recuperaciones se descartan únicamente desde la interfaz o mediante administración local del usuario.

El código LaTeX recibido no se ejecuta: la importación crea un mapeo semántico seguro. La composición usa `--untrusted`, desactiva shell-escape y genera el código desde datos escapados. La aplicación local actual tiene firma ad-hoc y no usa App Sandbox; no se presenta como una frontera de seguridad para compilar LaTeX arbitrario.
