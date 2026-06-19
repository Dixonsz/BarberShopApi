# Arquitectura del proyecto

## Estructura de capas

Cada módulo funcional se organiza en cuatro capas:

```text
apps/
└── products/
    ├── api/
    ├── application/
    ├── domain/
    └── infrastructure/
```

---

## Capa API

Contiene todo lo relacionado con la interfaz HTTP:

- Views
- Serializers
- Permissions
- Filters
- URLs
- Adaptación de respuestas HTTP

No debe contener reglas complejas de negocio.

---

## Capa Application

Coordina las operaciones del sistema:

- Casos de uso
- Servicios
- Commands
- Queries
- Coordinación de transacciones

Es responsable de ejecutar las operaciones y coordinar el dominio con la infraestructura.

---

## Capa Domain

Contiene el núcleo del negocio:

- Reglas de negocio
- Entidades
- Objetos de valor
- Excepciones del dominio

No debe depender de Django REST Framework ni conocer conceptos HTTP.

---

## Capa Infrastructure

Implementa los detalles técnicos:

- Modelos ORM
- Repositorios
- Selectores
- Clientes de servicios externos
- Correo
- Almacenamiento
- Implementaciones técnicas

---

## Módulo Shared

El módulo `shared` contiene componentes transversales reutilizables:

- Respuestas globales
- Manejo global de excepciones
- Paginación
- Permisos comunes
- Middleware
- Logging
- Modelos abstractos
- Constantes generales

No debe convertirse en una carpeta donde se coloque código sin una responsabilidad clara.

---

## Funciones y métodos

Cada función o método debe tener **una única responsabilidad principal**.

❌ Incorrecto:

```python
def process_order():
    # Crear orden.
    # Validar usuario.
    # Descontar inventario.
    # Enviar correo.
    # Crear factura.
    pass
```

✅ Correcto:

```python
def create_order():
    pass


def reserve_stock():
    pass


def send_order_confirmation():
    pass
```

Los nombres deben describir acciones concretas:

```python
create_product()
update_product()
list_active_products()
validate_available_stock()
```

---

## Argumentos nombrados

En servicios y casos de uso se recomienda usar argumentos nombrados para mejorar la legibilidad.

```python
create_product(
    name="Teclado",
    price=Decimal("25000.00"),
    stock=10,
)
```

En funciones importantes se puede usar `*` para **obligar** el uso de argumentos nombrados:

```python
def create_product(
    *,
    name: str,
    price: Decimal,
    stock: int,
) -> Product:
    pass
```

Esto evita llamadas difíciles de interpretar como:

```python
create_product("Teclado", Decimal("25000.00"), 10)
```

---

## Transacciones

Las transacciones deben definirse en la capa de aplicación o en el caso de uso que represente la unidad de trabajo.

```python
from django.db import transaction


@transaction.atomic
def confirm_order(*, order: Order) -> Order:
    pass
```

No se debe aplicar `transaction.atomic` automáticamente a todas las vistas. Una transacción se utiliza cuando varias operaciones deben confirmarse o revertirse como una sola unidad.