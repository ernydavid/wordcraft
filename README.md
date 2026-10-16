# Words

![Words — logo](branding/words/assets/words-logo.svg)

**Words** es un editor de documentos multiplataforma derivado de [WordCraft](https://github.com/storytold/wordcraft) (Rust + egui).
Es un proyecto independiente; no está afiliado ni respaldado por ArtCraft.

## Descargar Words — versión beta 0.7.1

> **Versión de prueba:** los instaladores aún no tienen firma digital pública de Windows ni notarización de Apple. Descarga los archivos únicamente desde este repositorio y verifica su procedencia.

| Sistema | Descargar | Formato |
|---|---|---|
| Windows 64 bits | [**Instalar Words**](https://github.com/ernydavid/wordcraft/releases/download/words-v0.7.1-beta.2/Words-0.7.1-Windows-x64.msi) | MSI |
| Windows portable | [**Words portable**](https://github.com/ernydavid/wordcraft/releases/download/words-v0.7.1-beta.2/Words-0.7.1-Windows-x64-portable.zip) | ZIP |
| macOS Intel / Apple Silicon | [**Instalar Words**](https://github.com/ernydavid/wordcraft/releases/download/words-v0.7.1-beta.2/Words-0.7.1-macOS-universal.dmg) | DMG |
| Navegador | [**Words Web**](https://ernydavid.github.io/wordcraft/) | Aplicación web |
| Web (archivos) | [**Descargar sitio web**](https://github.com/ernydavid/wordcraft/releases/download/words-v0.7.1-beta.2/Words-0.7.1-Web.zip) | ZIP |

[**Ver todas las versiones y descargas en GitHub Releases →**](https://github.com/ernydavid/wordcraft/releases)

## Plataformas

- Windows 64 bits: instalador MSI y versión portable.
- macOS 11 o posterior: aplicación universal Intel / Apple Silicon en DMG.
- Web: aplicación WebAssembly estática.

## Estructura Git

- `main`: se mantiene sincronizada con `storytold/wordcraft`.
- `custom`: versión Words, con branding, empaquetado y mejoras propias.

### Configuración inicial

```bash
git clone https://github.com/ernydavid/wordcraft.git
cd wordcraft
git remote add upstream https://github.com/storytold/wordcraft.git
git switch custom
```

Los iconos se generan antes de compilar:

```bash
python -m pip install pillow cairosvg
python branding/words/generate_icons.py
```

La identidad visual se configura en `branding/words/`, con los puntos de integración imprescindibles en `apps/wordcraft/`, `apps/wordcraft-web/`, `crates/ui-egui/` y `crates/control-key/`.

## Compilaciones

El workflow [Words - Build and Release](.github/workflows/words-release.yml) construye Windows, macOS y web. Los archivos de instalación se guardan como artefactos de GitHub Actions. Al publicar un tag `words-v*` también crea un GitHub Release.

Para publicar la versión web, activa **Settings → Pages → Build and deployment → GitHub Actions**. Para que `workflow_dispatch` aparezca en Actions, configura `custom` como rama predeterminada (o mueve la definición del workflow a la rama predeterminada). Los pushes a `custom` también activan el workflow.

### Versiones locales

- Windows: `pwsh branding/words/windows/package.ps1` (MSVC + WiX v5).
- macOS: `bash branding/words/macos/package.sh` (Xcode y targets Intel/Apple Silicon).
- Web: `bash branding/words/web/package.sh` (Rust WebAssembly y Trunk).

**Atención:** no se han verificado compilaciones exitosas. Antes de publicar instaladores al público configura las firmas, notarización y prueba de uso real.

## Actualizaciones originales

```bash
git switch main
git fetch upstream
git merge --ff-only upstream/main
git push origin main

git switch custom
git merge main
# Resolver posibles conflictos y validar compilaciones
git push origin custom
```

## Licencias y atribuciones

El código de WordCraft original es `MIT OR Apache-2.0`; conserva los avisos de derechos de autor, `NOTICE`, `ATTRIBUTION.md` y los textos de licencia correspondientes. Las marcas de ArtCraft tienen una licencia separada en [docs/brand/LICENSE-brand.txt](docs/brand/LICENSE-brand.txt) y no deben utilizarse para presentar Words como producto oficial.

El logo de Words incluido es provisional y original, editable en [branding/words/assets/words.svg](branding/words/assets/words.svg). Queda pendiente una auditoría de los enlaces y nombres originales que pudieran aparecer en pantallas o servicios y de los recursos distribuidos, además de sustituir el fabricante provisional en los instaladores.
