# Calidad de código

## Tipado

Se recomienda usar anotaciones de tipos en funciones, métodos y estructuras importantes.

```python
from decimal import Decimal


def calculate_total(
    price: Decimal,
    quantity: int,
) -> Decimal:
    return price * quantity
```

También en servicios y casos de uso:

```python
def create_product(
    *,
    name: str,
    price: Decimal,
) -> Product:
    pass
```

El tipado debe mejorar la claridad sin generar complejidad innecesaria.

---

## Excepciones

No se debe usar `Exception` para representar errores empresariales conocidos.

❌ Incorrecto:

```python
raise Exception("No hay inventario")
```

✅ Correcto:

```python
raise InsufficientStockError(
    "No existe inventario suficiente."
)
```

Las excepciones deben representar claramente el error:

```text
ProductNotFoundError
InsufficientStockError
OrderAlreadyConfirmedError
InvalidOrderStateError
```

No se deben capturar excepciones genéricas dentro de cada vista:

❌ Incorrecto:

```python
try:
    product = create_product(...)
except Exception as error:
    return Response({"error": str(error)})
```

Las excepciones deben ser procesadas por el **manejador global de la API**.

---

## Respuestas de la API

Las respuestas exitosas deben usar la clase global `ApiResponse`:

```python
return ApiResponse.success(
    data=serializer.data,
    message="Producto obtenido correctamente.",
)
```

No se deben construir manualmente respuestas de error en cada vista, salvo que exista una justificación técnica documentada.

### Formato de respuesta exitosa

```json
{
  "success": true,
  "message": "Producto obtenido correctamente.",
  "data": {},
  "errors": null,
  "meta": null
}
```

### Formato de respuesta con error

```json
{
  "success": false,
  "message": "El producto no existe.",
  "data": null,
  "errors": {
    "code": "product_not_found",
    "details": null
  },
  "meta": null
}
```

---

## Pruebas

Las pruebas deben usar nombres descriptivos que expresen el comportamiento esperado:

```python
def test_create_product_returns_created_product():
    pass
```

### Estructura

```text
tests/
├── unit/          # Reglas de dominio y funciones aisladas
├── integration/   # Interacción con base de datos y servicios externos
└── api/           # Endpoints, autenticación, permisos y respuestas HTTP
```

Cada corrección importante debe incluir una prueba que reproduzca el error cuando sea posible.

---

## Herramientas de calidad

| Herramienta | Propósito |
|-------------|-----------|
| `ruff` | Linting y formato (reemplaza flake8, isort, black) |
| `pytest` | Pruebas automatizadas |
| `pytest-django` | Integración de pytest con Django |
| `pytest-cov` | Reporte de cobertura de pruebas |

### Comandos de uso frecuente

Verificar antes de hacer commit:

```bash
ruff check .
ruff format --check .
pytest
```

Corregir automáticamente errores compatibles:

```bash
ruff check . --fix
ruff format .
```

---

## Configuración de Ruff

Ubicada en `pyproject.toml` en la raíz del repositorio:

```toml
[tool.ruff]
line-length = 88
target-version = "py312"
exclude = [
    ".git",
    ".venv",
    "venv",
    "migrations",
]

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "UP",  # pyupgrade
]
ignore = []

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "auto"
```

La documentación explica las reglas del proyecto; Ruff aplica automáticamente las que pueden verificarse técnicamente.

---

## Configuración de Pytest

También en `pyproject.toml`:

```toml
[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
python_files = [
    "test_*.py",
    "*_test.py",
]
testpaths = [
    "tests",
    "src/apps",
]
```

La ruta de `DJANGO_SETTINGS_MODULE` debe ajustarse si el proyecto usa una estructura de configuración diferente.