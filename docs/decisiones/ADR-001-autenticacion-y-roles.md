# ADR-001: Autenticación JWT y Roles con Django Groups

- **Estado:** Aceptado  
- **Fecha:** 2026-06-20  
- **Autor:** Dixon Sanchez Soza

---

## Contexto

El proyecto requiere un sistema de autenticación para una API REST construida con Django REST Framework. Se necesita proteger endpoints, identificar usuarios y controlar qué acciones puede realizar cada uno según su rol.

---

## Decisión

Se utilizará **JWT (JSON Web Tokens)** para autenticación mediante la librería `djangorestframework-simplejwt`, y **Django Groups + permisos built-in** para el manejo de roles y permisos.

---

## Justificación

### Autenticación → JWT con `simplejwt`

| Alternativa | Razón de descarte |
|---|---|
| Session (Django default) | Diseñado para web con browser, no para APIs REST stateless |
| Token DRF built-in | El token nunca expira por defecto, requiere manejo manual en DB |
| **JWT (elegido)** | Estándar moderno para APIs REST, sin estado, expiración automática |

**Ventajas concretas de JWT:**
- Sin estado (stateless): el servidor no necesita almacenar sesiones
- Expiración automática configurable (`ACCESS_TOKEN_LIFETIME`)
- Refresh token con rotación y blacklist incluidos en `simplejwt`
- Compatible con cualquier cliente (mobile, web, third-party)

### Roles → Django Groups + permisos built-in

| Alternativa | Razón de descarte |
|---|---|
| Campo `role` en User | No tiene sistema de permisos granulares integrado |
| Tabla propia de roles | Complejidad innecesaria para el alcance del proyecto |
| **Django Groups (elegido)** | Sistema maduro, integrado con DRF, permisos granulares por acción |

**Ventajas concretas de Django Groups:**
- Sistema de permisos por acción ya integrado (`add_`, `change_`, `delete_`, `view_`)
- DRF lo reconoce nativamente con `DjangoModelPermissions`
- Administración desde el Django Admin sin código extra
- Escalable: se pueden crear grupos y asignar permisos sin modificar modelos

---

## Consecuencias

- Se requiere instalar `djangorestframework-simplejwt`
- Se requiere agregar `rest_framework_simplejwt.token_blacklist` en `INSTALLED_APPS`
- Los roles se administran desde el Django Admin o mediante fixtures/seeders
- Los permisos custom se definen en `shared/api/permissions.py` extendiendo `BasePermission`

---

## Configuración resultante

```python
# settings.py
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "shared.api.permissions.IsAuthenticatedAndActive",
    ],
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}
```