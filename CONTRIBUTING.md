# Contribuir a Naberius

Usa una rama desde `main` y una solicitud de cambios centrada en un problema. Describe el comportamiento resultante, la validación ejecutada y los límites que permanezcan. Para errores, incluye pasos reproducibles, versión de macOS y motor; usa documentos sintéticos sin datos personales.

```sh
python3 script/sync_localization.py --check
./script/test.sh
./script/build_and_run.sh --build-only
```

Si cambias composición, prueba además `NABERIUS_COMPOSE=1 ./script/test.sh` con Tectonic instalado. La primera preparación de paquetes puede necesitar conexión; no conviertas esa descarga en una acción automática de la app. Las pruebas ordinarias de CI omiten esas integraciones externas.

Conserva los identificadores semánticos y la compatibilidad de `.nab`, la autoría **Creado por Sebastián Pastén F.**, el enlace de Ko-fi y los avisos de dependencias. No ejecutes comandos procedentes de archivos importados. Los textos de interfaz se obtienen con `L10n`; actualiza el catálogo con `python3 script/sync_localization.py` y no traduzcas claves persistentes ni contenido de documentos.

Las contribuciones se realizan bajo AGPL-3.0-or-later. Los recursos de terceros mantienen sus licencias. Las afirmaciones de rendimiento deben incluir una medición reproducible; las mejoras visuales, capturas reales pertinentes. No presentes pruebas parciales como cumplimiento completo de P0 o de accesibilidad.
