# Terax

**Una terminal ligera con explorador de carpetas y seguimiento de Git. Sin agentes de IA integrados.**

Esta versión es un fork modificado de [crynta/terax-ai](https://github.com/crynta/terax-ai), mantenido por separado en [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai). El proyecto original pertenece a Crynta y sus colaboradores.

## Funciones

- Terminal nativa con pestañas, paneles divididos, búsqueda e integración con el shell.
- Explorador de carpetas con búsqueda, gestión de archivos y actualizaciones en vivo.
- Estado de Git, diferencias, preparación de cambios, commits, push e historial gráfico.
- Se conservan el editor, los servidores de lenguaje opcionales, las vistas previas y los temas como herramientas complementarias.

No incluye chat de IA, agentes, proveedores de IA, autocompletado con IA ni entrada de voz. Los programas CLI se pueden ejecutar manualmente. Los datos antiguos de IA y los hooks externos no se cargan ni se eliminan automáticamente.

## Compilar

Requiere Rust estable, Node 22+, pnpm y los [prerrequisitos de Tauri](https://tauri.app/start/prerequisites/).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Paquete de producción:
pnpm tauri build
```

**Atención:** la configuración del actualizador aún apunta a las versiones del proyecto original. Aceptar una actualización puede sustituir este fork por la versión original. Sus instaladores y paquetes no deben confundirse con esta versión sin IA. No se garantiza una firma específica de este fork.

Consulta el [README en inglés](../../README.md) para las instrucciones completas y las limitaciones de distribución. También: [documentación](../README.md), [contribuciones](../../CONTRIBUTING.md) y [seguridad](../../SECURITY.md). Informa de problemas en el repositorio de este fork.

Licencia [Apache-2.0](../../LICENSE). Se conservan los créditos y avisos originales.
