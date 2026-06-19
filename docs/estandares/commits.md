# Guía de Conventional Commits

> Convención estándar para mensajes de commit en proyectos de software.

---

## Formato base

```
<tipo>(<alcance>): <descripción corta>

[cuerpo opcional]

[pie de página opcional]
```

- **tipo**: categoría del cambio (obligatorio)
- **alcance**: módulo o área afectada (opcional, entre paréntesis)
- **descripción corta**: resumen en imperativo, minúsculas, máx. ~72 caracteres
- **cuerpo**: explicación del *por qué*, no del *qué* (separado por línea en blanco)
- **pie de página**: referencias a issues, breaking changes, co-autores

---

## Tipos de commits

| Tipo       | Cuándo usarlo                                          |
|------------|--------------------------------------------------------|
| `feat`     | Nueva funcionalidad                                    |
| `fix`      | Corrección de bug                                      |
| `docs`     | Solo cambios en documentación                          |
| `style`    | Formato, espacios, comas (sin cambio de lógica)        |
| `refactor` | Reestructuración sin nueva feature ni fix              |
| `test`     | Agregar o corregir tests                               |
| `chore`    | Mantenimiento: dependencias, configs, herramientas     |
| `perf`     | Mejora de rendimiento                                  |
| `ci`       | Cambios en pipelines CI/CD                             |
| `build`    | Sistema de build o dependencias externas               |
| `revert`   | Revertir un commit anterior                            |

---

## Ejemplos

### Feature nueva
```
feat(auth): agregar login con Google OAuth
```

### Bug fix con referencia a issue
```
fix(api): corregir validación de token expirado

El token no era invalidado correctamente cuando expiraba durante
una sesión activa, causando respuestas 401 inesperadas.

Closes #42
```

### Breaking change
```
feat(db)!: migrar schema de usuarios a nueva estructura

BREAKING CHANGE: el campo `nombre` se divide en `nombre` y `apellido`.
Actualizar todas las queries y formularios que usen el campo anterior.
```

### Documentación
```
docs(readme): agregar instrucciones de instalación local
```

### Refactor sin cambio funcional
```
refactor(products): extraer lógica de filtrado a hook useProductFilter
```

### Chore de dependencias
```
chore: actualizar dependencias de desarrollo a versiones LTS
```

### Revert
```
revert: feat(auth): agregar login con Google OAuth

Revierte el commit abc1234 por conflicto con el flujo de sesiones actual.
```

### Múltiples alcances o cambio general (sin alcance)
```
style: aplicar formato Prettier a todo el proyecto
```

---

## Reglas clave

1. **Imperativo en la descripción**: `agregar`, `corregir`, `actualizar` — no "agregado" ni "Agregando"
2. **Sin punto final** en la descripción corta
3. **Minúsculas** siempre en tipo, alcance y descripción
4. **Cuerpo separado** de la descripción por una línea en blanco
5. **Breaking changes** se marcan con `!` después del tipo/alcance, o con `BREAKING CHANGE:` en el pie
6. **Una sola responsabilidad** por commit — si necesitás usar "y" en la descripción, considerá dividirlo

---

## Alcances sugeridos por tipo de proyecto

### Web Full Stack
`auth` · `api` · `ui` · `db` · `routes` · `components` · `hooks` · `services` · `config` · `deploy`

### Backend / API REST
`auth` · `users` · `payments` · `notifications` · `middleware` · `models` · `migrations`

### Frontend SPA
`pages` · `components` · `store` · `router` · `styles` · `i18n` · `utils`

---

## Herramientas complementarias

| Herramienta | Propósito |
|-------------|-----------|
| `commitlint` | Valida que los commits sigan la convención |
| `husky` | Ejecuta hooks de Git (pre-commit, commit-msg) |
| `commitizen` | CLI interactivo para redactar commits guiados |
| `standard-version` / `semantic-release` | Genera versiones y CHANGELOG automáticamente |

### Ejemplo de configuración rápida

```bash
# Instalar commitlint + husky
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky

# Configurar commitlint
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js

# Activar hook de Git
npx husky install
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit "$1"'
```

---

## Referencia oficial

- Especificación completa: [https://www.conventionalcommits.org](https://www.conventionalcommits.org)
- Angular commit guidelines (origen): [https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit)