# Convenciones de Python

## Naming

### Variables y funciones — `snake_case`

```python
product_name = "Teclado"
available_stock = 10


def calculate_total_price():
    pass
```

### Clases — `PascalCase`

```python
class ProductService:
    pass
```

### Constantes — `UPPER_SNAKE_CASE`

```python
MAX_PAGE_SIZE = 100
DEFAULT_CURRENCY = "CRC"
```

### Archivos y módulos — `snake_case`

```text
product_service.py
exception_handler.py
api_response.py
```

### Nombres descriptivos

Los nombres deben expresar claramente la responsabilidad del elemento.

✅ Correcto:

```python
def calculate_order_total():
    pass
```

❌ Incorrecto:

```python
def process():
    pass
```

### Variables booleanas

Deben expresar una condición.

✅ Correcto:

```python
is_active
has_permission
can_confirm_order
requires_authentication
```

❌ Incorrecto:

```python
active
permission
confirmation
authentication
```

---

## Formato

### Longitud de línea

Máximo **88 caracteres** por línea (aplicado automáticamente por Ruff).

### Comillas

Se utilizan **comillas dobles** como formato predeterminado.

```python
message = "Producto creado correctamente."
```

### Importaciones

No se deben usar importaciones con comodín.

❌ Incorrecto:

```python
from apps.products.models import *
```

✅ Correcto:

```python
from apps.products.models import Product
```

### Orden de importaciones

1. Librería estándar de Python
2. Django y dependencias externas
3. Módulos internos del proyecto

Cada grupo separado por una línea en blanco. Ruff (`I` — isort) aplica esto automáticamente.

```python
from decimal import Decimal
from typing import Any

from django.db import transaction
from rest_framework.response import Response

from apps.products.models import Product
from shared.api.responses import ApiResponse
```

---

## Comentarios y documentación

Los comentarios deben explicar el **motivo** de una decisión, no repetir lo que hace el código.

❌ Incorrecto:

```python
# Guardar producto.
product.save()
```

✅ Correcto:

```python
# Se limita la actualización para evitar modificar columnas no relacionadas.
product.save(update_fields=["stock", "updated_at"])
```

Las funciones complejas pueden usar docstrings:

```python
def reserve_stock(*, product: Product, quantity: int) -> None:
    """Reserva inventario disponible para una orden."""
```

No es obligatorio agregar docstrings a funciones simples cuyo propósito sea evidente por su nombre.

---

## Código muerto

No se debe mantener código antiguo comentado. El historial de cambios vive en Git.

❌ Incorrecto:

```python
# old_product = Product.objects.get(id=product_id)
# old_product.save()
```

También deben eliminarse:

- Variables sin utilizar
- Importaciones innecesarias
- Funciones obsoletas
- Archivos que ya no formen parte del proyecto