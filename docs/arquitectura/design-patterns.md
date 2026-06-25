# Patrones de diseño del proyecto

## Introducción

La arquitectura y los patrones de diseño no representan lo mismo.

La **arquitectura** define la organización general del sistema, sus capas y la forma en que se comunican. En este proyecto se utiliza una arquitectura modular por capas:

```text
API → Application → Domain ← Infrastructure
```

Los **patrones de diseño** son soluciones reutilizables para problemas concretos que aparecen dentro de esa arquitectura.

No es necesario aplicar todos los patrones existentes. Cada patrón debe incorporarse únicamente cuando resuelva una necesidad real del proyecto.

---

## Patrones principales

Para este proyecto se recomienda utilizar principalmente los siguientes patrones:

1. Repository Pattern.
2. Use Case o Service Layer.
3. Adapter Pattern.
4. Dependency Injection.
5. Strategy Pattern, cuando existan distintas formas de ejecutar una operación.
6. Factory Method, cuando la creación de entidades sea compleja.
7. CQRS ligero, para separar operaciones de lectura y escritura.

La combinación principal será:

```text
Arquitectura modular por capas
├── Use Cases
├── Repository Pattern
├── Adapter Pattern
└── Dependency Injection
```

Los demás patrones se incorporarán solamente cuando el dominio lo requiera.

---

# 1. Repository Pattern

## Objetivo

El patrón Repository crea una abstracción entre la lógica de negocio y el mecanismo utilizado para almacenar o consultar información.

Gracias a este patrón, la capa de aplicación no necesita conocer directamente:

- Django ORM.
- PostgreSQL.
- Consultas SQL.
- APIs externas.
- Detalles de persistencia.

La aplicación trabaja con una interfaz de repositorio y la infraestructura proporciona la implementación técnica.

---

## Problema que resuelve

Sin un repositorio, un caso de uso podría depender directamente del ORM:

```python
from apps.products.infrastructure.models import ProductModel


def deactivate_product(*, product_id):
    product = ProductModel.objects.get(id=product_id)
    product.is_active = False
    product.save()

    return product
```

Este código mezcla:

- Coordinación del caso de uso.
- Acceso a la base de datos.
- Reglas del negocio.
- Detalles del ORM.

Además, dificulta las pruebas porque el caso de uso necesita una base de datos real.

---

## Estructura recomendada

```text
apps/
└── products/
    ├── application/
    │   └── use_cases/
    │       └── deactivate_product.py
    ├── domain/
    │   ├── entities/
    │   │   └── product.py
    │   └── repositories/
    │       └── product_repository.py
    └── infrastructure/
        ├── models/
        │   └── product_model.py
        └── repositories/
            └── django_product_repository.py
```

---

## Contrato del repositorio

El contrato puede declararse en la capa `domain`.

```python
from abc import ABC, abstractmethod
from uuid import UUID

from apps.products.domain.entities.product import Product


class ProductRepository(ABC):

    @abstractmethod
    def get_by_id(self, *, product_id: UUID) -> Product | None:
        raise NotImplementedError

    @abstractmethod
    def save(self, *, product: Product) -> Product:
        raise NotImplementedError

    @abstractmethod
    def delete(self, *, product: Product) -> None:
        raise NotImplementedError
```

Esta clase define **qué operaciones necesita el dominio**, pero no explica cómo se ejecutan.

---

## Implementación con Django ORM

La implementación concreta vive en `infrastructure`.

```python
from uuid import UUID

from apps.products.domain.entities.product import Product
from apps.products.domain.repositories.product_repository import ProductRepository
from apps.products.infrastructure.models.product_model import ProductModel


class DjangoProductRepository(ProductRepository):

    def get_by_id(self, *, product_id: UUID) -> Product | None:
        product_model = (
            ProductModel.objects
            .filter(id=product_id)
            .first()
        )

        if product_model is None:
            return None

        return self._to_domain(product_model=product_model)

    def save(self, *, product: Product) -> Product:
        product_model, _ = ProductModel.objects.update_or_create(
            id=product.id,
            defaults={
                "name": product.name,
                "price": product.price,
                "stock": product.stock,
                "is_active": product.is_active,
            },
        )

        return self._to_domain(product_model=product_model)

    def delete(self, *, product: Product) -> None:
        ProductModel.objects.filter(id=product.id).delete()

    @staticmethod
    def _to_domain(*, product_model: ProductModel) -> Product:
        return Product(
            id=product_model.id,
            name=product_model.name,
            price=product_model.price,
            stock=product_model.stock,
            is_active=product_model.is_active,
        )
```

---

## Cuándo utilizarlo

Conviene utilizar Repository Pattern cuando:

- La aplicación contiene reglas de negocio importantes.
- Se desea evitar que los casos de uso dependan de Django ORM.
- Se necesitan pruebas unitarias sin base de datos.
- Pueden existir diferentes fuentes de datos.
- Se desea mantener clara la separación entre dominio e infraestructura.

No es necesario crear un repositorio genérico con decenas de operaciones. Cada repositorio debe exponer solamente las operaciones requeridas por el módulo.

---

# 2. Use Case Pattern o Service Layer

## Objetivo

Un caso de uso representa una operación completa que el sistema permite ejecutar.

Ejemplos:

```text
CreateProduct
UpdateProduct
DeactivateProduct
RegisterUser
ConfirmOrder
CancelOrder
ReserveStock
```

La capa API recibe la solicitud HTTP, valida los datos y delega la operación al caso de uso.

---

## Regla principal

La vista no debe contener la lógica completa de la operación.

La vista debe limitarse a:

1. Recibir la solicitud.
2. Validar los datos de entrada.
3. Ejecutar el caso de uso.
4. Transformar el resultado en una respuesta HTTP.

---

## Caso de uso como clase

```python
from decimal import Decimal

from apps.products.domain.entities.product import Product
from apps.products.domain.repositories.product_repository import ProductRepository


class CreateProductUseCase:

    def __init__(self, *, repository: ProductRepository):
        self.repository = repository

    def execute(
        self,
        *,
        name: str,
        price: Decimal,
        stock: int,
    ) -> Product:
        product = Product.create(
            name=name,
            price=price,
            stock=stock,
        )

        return self.repository.save(product=product)
```

---

## Caso de uso como función

También se puede implementar mediante una función cuando la operación es sencilla:

```python
from decimal import Decimal

from apps.products.domain.entities.product import Product
from apps.products.domain.repositories.product_repository import ProductRepository


def create_product(
    *,
    name: str,
    price: Decimal,
    stock: int,
    repository: ProductRepository,
) -> Product:
    product = Product.create(
        name=name,
        price=price,
        stock=stock,
    )

    return repository.save(product=product)
```

Ambas opciones son válidas.

Se recomienda usar clases cuando:

- El caso de uso tiene varias dependencias.
- Se desea mantener estado temporal durante la ejecución.
- Se quiere una interfaz uniforme mediante `execute()`.
- El proyecto utiliza inyección de dependencias de forma consistente.

Se recomienda usar funciones cuando:

- La operación es pequeña.
- No mantiene estado.
- Tiene pocas dependencias.
- Una clase no aporta claridad adicional.

---

## Uso desde la API

```python
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.products.api.serializers.product_create_serializer import (
    ProductCreateSerializer,
)
from apps.products.api.serializers.product_response_serializer import (
    ProductResponseSerializer,
)
from apps.products.application.use_cases.create_product import (
    CreateProductUseCase,
)
from apps.products.infrastructure.repositories.django_product_repository import (
    DjangoProductRepository,
)


class ProductCreateView(APIView):

    def post(self, request):
        serializer = ProductCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        use_case = CreateProductUseCase(
            repository=DjangoProductRepository(),
        )

        product = use_case.execute(
            **serializer.validated_data,
        )

        response_serializer = ProductResponseSerializer(product)

        return Response(
            response_serializer.data,
            status=status.HTTP_201_CREATED,
        )
```

La vista conoce HTTP y DRF. El caso de uso no debe conocer ninguno de estos conceptos.

---

# 3. Adapter Pattern

## Objetivo

El patrón Adapter permite que una herramienta externa pueda utilizarse mediante una interfaz definida por la aplicación.

Puede aplicarse a:

- Proveedores de pago.
- Servicios de correo.
- Almacenamiento de archivos.
- Sistemas de mensajería.
- APIs externas.
- Generadores de PDF.
- Servicios de autenticación externos.

---

## Ejemplo: servicio de correo

La aplicación define el contrato:

```python
from abc import ABC, abstractmethod


class EmailSender(ABC):

    @abstractmethod
    def send(
        self,
        *,
        recipient: str,
        subject: str,
        body: str,
    ) -> None:
        raise NotImplementedError
```

La infraestructura implementa el contrato utilizando Django:

```python
from django.core.mail import send_mail

from apps.shared.application.ports.email_sender import EmailSender


class DjangoEmailSender(EmailSender):

    def send(
        self,
        *,
        recipient: str,
        subject: str,
        body: str,
    ) -> None:
        send_mail(
            subject=subject,
            message=body,
            from_email=None,
            recipient_list=[recipient],
        )
```

El caso de uso trabaja con la interfaz:

```python
class SendOrderConfirmationUseCase:

    def __init__(self, *, email_sender: EmailSender):
        self.email_sender = email_sender

    def execute(
        self,
        *,
        customer_email: str,
        order_number: str,
    ) -> None:
        self.email_sender.send(
            recipient=customer_email,
            subject="Orden confirmada",
            body=f"La orden {order_number} fue confirmada.",
        )
```

El caso de uso no sabe si el correo se envía mediante Django, SendGrid, Amazon SES u otro proveedor.

---

# 4. Dependency Injection

## Objetivo

La inyección de dependencias consiste en proporcionar a una clase o función las herramientas que necesita, en lugar de crearlas directamente dentro de ella.

---

## Acoplamiento directo

```python
class CreateProductUseCase:

    def execute(self, *, name, price, stock):
        repository = DjangoProductRepository()

        product = Product.create(
            name=name,
            price=price,
            stock=stock,
        )

        return repository.save(product=product)
```

El caso de uso está acoplado a `DjangoProductRepository`.

---

## Dependencia inyectada

```python
class CreateProductUseCase:

    def __init__(self, *, repository: ProductRepository):
        self.repository = repository

    def execute(self, *, name, price, stock):
        product = Product.create(
            name=name,
            price=price,
            stock=stock,
        )

        return self.repository.save(product=product)
```

La implementación se proporciona desde afuera:

```python
use_case = CreateProductUseCase(
    repository=DjangoProductRepository(),
)
```

---

## Beneficios

- Reduce el acoplamiento.
- Facilita las pruebas unitarias.
- Permite sustituir implementaciones.
- Hace explícitas las dependencias.
- Evita que el dominio conozca detalles técnicos.

No es obligatorio utilizar una librería o contenedor de inyección de dependencias. En Python, la inyección mediante constructores y argumentos suele ser suficiente.

---

# 5. Strategy Pattern

## Objetivo

Strategy Pattern permite intercambiar diferentes algoritmos que cumplen la misma responsabilidad.

Es útil cuando existen varias formas de:

- Calcular descuentos.
- Calcular impuestos.
- Definir costos de envío.
- Procesar pagos.
- Reservar inventario.
- Asignar precios.
- Validar determinadas políticas.

---

## Contrato de estrategia

```python
from abc import ABC, abstractmethod
from decimal import Decimal


class DiscountStrategy(ABC):

    @abstractmethod
    def calculate(
        self,
        *,
        subtotal: Decimal,
    ) -> Decimal:
        raise NotImplementedError
```

---

## Estrategias concretas

```python
from decimal import Decimal


class NoDiscountStrategy(DiscountStrategy):

    def calculate(
        self,
        *,
        subtotal: Decimal,
    ) -> Decimal:
        return Decimal("0.00")
```

```python
from decimal import Decimal


class PercentageDiscountStrategy(DiscountStrategy):

    def __init__(self, *, percentage: Decimal):
        self.percentage = percentage

    def calculate(
        self,
        *,
        subtotal: Decimal,
    ) -> Decimal:
        return subtotal * self.percentage / Decimal("100")
```

```python
from decimal import Decimal


class FixedDiscountStrategy(DiscountStrategy):

    def __init__(self, *, amount: Decimal):
        self.amount = amount

    def calculate(
        self,
        *,
        subtotal: Decimal,
    ) -> Decimal:
        return min(self.amount, subtotal)
```

---

## Uso de la estrategia

```python
class CalculateOrderTotalUseCase:

    def __init__(
        self,
        *,
        discount_strategy: DiscountStrategy,
    ):
        self.discount_strategy = discount_strategy

    def execute(
        self,
        *,
        subtotal: Decimal,
    ) -> Decimal:
        discount = self.discount_strategy.calculate(
            subtotal=subtotal,
        )

        return subtotal - discount
```

Este patrón evita condicionales extensos:

```python
if discount_type == "percentage":
    ...
elif discount_type == "fixed":
    ...
elif discount_type == "coupon":
    ...
```

No se debe utilizar Strategy Pattern si solamente existe un comportamiento y no hay variantes reales.

---

# 6. Factory Method

## Objetivo

Factory Method centraliza la creación de objetos cuando construirlos requiere reglas, valores predeterminados o validaciones.

En muchos casos no es necesario crear una clase llamada `Factory`. Un método de clase dentro de la entidad puede ser suficiente.

---

## Ejemplo dentro de una entidad

```python
from dataclasses import dataclass
from decimal import Decimal
from uuid import UUID, uuid4

from apps.products.domain.exceptions import (
    InvalidProductNameError,
    InvalidProductPriceError,
    InvalidProductStockError,
)


@dataclass
class Product:
    id: UUID
    name: str
    price: Decimal
    stock: int
    is_active: bool

    @classmethod
    def create(
        cls,
        *,
        name: str,
        price: Decimal,
        stock: int,
    ) -> "Product":
        normalized_name = name.strip()

        if not normalized_name:
            raise InvalidProductNameError()

        if price <= Decimal("0.00"):
            raise InvalidProductPriceError()

        if stock < 0:
            raise InvalidProductStockError()

        return cls(
            id=uuid4(),
            name=normalized_name,
            price=price,
            stock=stock,
            is_active=True,
        )
```

El método `create()` garantiza que todos los productos nuevos se construyan respetando las reglas iniciales.

---

## Cuándo usar una clase Factory

Una clase Factory separada puede resultar útil cuando:

- Se crean varios tipos de objetos.
- La construcción depende de configuración externa.
- Se requieren varias dependencias.
- Existen diferentes procesos de creación.
- La entidad no debe asumir toda la lógica de ensamblado.

Para entidades simples, se recomienda comenzar con un método `create()`.

---

# 7. CQRS ligero

## Objetivo

CQRS separa las operaciones que modifican información de las operaciones que únicamente consultan información.

En este proyecto puede aplicarse una versión sencilla, sin buses de mensajes ni bases de datos separadas.

---

## Commands

Representan operaciones que cambian el estado:

```text
CreateProduct
UpdateProduct
DeactivateProduct
IncreaseStock
ConfirmOrder
CancelOrder
```

Posible organización:

```text
application/
└── commands/
    ├── create_product.py
    ├── update_product.py
    └── deactivate_product.py
```

---

## Queries

Representan operaciones de lectura:

```text
GetProductDetail
ListActiveProducts
SearchProducts
ListProductsByCategory
```

Posible organización:

```text
application/
└── queries/
    ├── get_product_detail.py
    └── list_active_products.py
```

---

## Selectors

Los selectors pueden vivir en `infrastructure` y encapsular consultas optimizadas del ORM:

```python
from django.db.models import QuerySet

from apps.products.infrastructure.models.product_model import ProductModel


def list_active_products() -> QuerySet[ProductModel]:
    return (
        ProductModel.objects
        .filter(is_active=True)
        .select_related("category", "brand")
        .order_by("name")
    )
```

Los selectors son especialmente útiles para:

- Listados.
- Filtros.
- Búsquedas.
- Reportes.
- Consultas con `select_related`.
- Consultas con `prefetch_related`.
- Agregaciones.
- Proyecciones optimizadas.

---

## Regla práctica

```text
Command → modifica datos.
Query → consulta datos.
Selector → implementa consultas ORM optimizadas.
Repository → persiste o recupera entidades del dominio.
```

No todas las consultas necesitan convertirse en objetos o clases. Las funciones simples son suficientes mientras mantengan una responsabilidad clara.

---

# Flujo completo recomendado

## Escritura

Ejemplo: creación de un producto.

```text
POST /api/products/
        ↓
ProductCreateSerializer
        ↓
CreateProductUseCase
        ↓
Product.create()
        ↓
ProductRepository
        ↓
DjangoProductRepository
        ↓
ProductModel / PostgreSQL
```

---

## Lectura

Ejemplo: listado de productos activos.

```text
GET /api/products/
        ↓
ProductFilterSerializer
        ↓
ListActiveProductsQuery
        ↓
ProductSelector
        ↓
Django ORM
        ↓
ProductResponseSerializer
```

---

# Estructura recomendada del módulo

```text
apps/
└── products/
    ├── api/
    │   ├── serializers/
    │   │   ├── product_create_serializer.py
    │   │   └── product_response_serializer.py
    │   ├── views/
    │   │   ├── product_create_view.py
    │   │   └── product_list_view.py
    │   ├── permissions/
    │   ├── filters/
    │   └── urls.py
    │
    ├── application/
    │   ├── commands/
    │   │   ├── create_product.py
    │   │   └── update_product.py
    │   ├── queries/
    │   │   └── list_active_products.py
    │   ├── use_cases/
    │   ├── services/
    │   └── ports/
    │       └── image_storage.py
    │
    ├── domain/
    │   ├── entities/
    │   │   └── product.py
    │   ├── value_objects/
    │   │   └── money.py
    │   ├── repositories/
    │   │   └── product_repository.py
    │   ├── strategies/
    │   │   └── pricing_strategy.py
    │   ├── exceptions/
    │   └── services/
    │
    └── infrastructure/
        ├── models/
        │   └── product_model.py
        ├── repositories/
        │   └── django_product_repository.py
        ├── selectors/
        │   └── product_selector.py
        ├── adapters/
        │   └── supabase_image_storage.py
        ├── clients/
        └── migrations/
```

---

# Pruebas unitarias

Una de las ventajas principales de estos patrones es la posibilidad de probar los casos de uso sin Django ORM.

---

## Repositorio en memoria

```python
from uuid import UUID

from apps.products.domain.entities.product import Product
from apps.products.domain.repositories.product_repository import ProductRepository


class InMemoryProductRepository(ProductRepository):

    def __init__(self):
        self.products: dict[UUID, Product] = {}

    def get_by_id(self, *, product_id: UUID) -> Product | None:
        return self.products.get(product_id)

    def save(self, *, product: Product) -> Product:
        self.products[product.id] = product
        return product

    def delete(self, *, product: Product) -> None:
        self.products.pop(product.id, None)
```

---

## Prueba del caso de uso

```python
from decimal import Decimal

from apps.products.application.use_cases.create_product import (
    CreateProductUseCase,
)


def test_create_product():
    repository = InMemoryProductRepository()

    use_case = CreateProductUseCase(
        repository=repository,
    )

    product = use_case.execute(
        name="Teclado",
        price=Decimal("25000.00"),
        stock=10,
    )

    assert product.name == "Teclado"
    assert product.price == Decimal("25000.00")
    assert product.stock == 10
    assert repository.get_by_id(product_id=product.id) == product
```

Esta prueba no necesita:

- Base de datos.
- Migraciones.
- Cliente HTTP.
- Django REST Framework.

---

# Reglas de implementación

## 1. No aplicar patrones sin una necesidad real

Un patrón debe resolver un problema concreto. No debe incorporarse únicamente para aumentar la cantidad de carpetas o clases.

---

## 2. Mantener dependencias en una sola dirección

La dirección recomendada es:

```text
API → Application → Domain
Infrastructure → Domain
API → Infrastructure
```

El dominio no debe importar:

- Django.
- Django REST Framework.
- Modelos ORM.
- Serializers.
- Views.
- Requests.
- Responses.

---

## 3. Evitar repositorios genéricos excesivos

No se recomienda crear una única clase con operaciones como:

```python
create()
update()
delete()
filter()
search()
paginate()
export()
send_email()
```

Cada repositorio debe representar una colección o agregado específico del dominio.

---

## 4. Diferenciar repositorios y selectors

Un repositorio trabaja principalmente con entidades del dominio.

Un selector está orientado a consultas de lectura y puede devolver:

- QuerySets.
- DTOs.
- Diccionarios.
- Proyecciones.
- Resultados agregados.

Ejemplo:

```text
ProductRepository.get_by_id()
```

Devuelve una entidad del dominio.

```text
list_product_catalog()
```

Puede devolver una consulta optimizada para una respuesta HTTP.

---

## 5. Mantener las transacciones en Application

La transacción debe rodear la operación completa que representa una unidad de trabajo.

```python
from django.db import transaction


@transaction.atomic
def confirm_order(
    *,
    order_id,
    order_repository,
    stock_repository,
):
    order = order_repository.get_by_id(order_id=order_id)

    order.confirm()

    stock_repository.reserve_for_order(order=order)
    order_repository.save(order=order)

    return order
```

No se recomienda colocar `transaction.atomic` en todas las vistas de forma automática.

---

## 6. Utilizar excepciones del dominio

Las reglas de negocio deben generar excepciones propias:

```python
class ProductNotFoundError(Exception):
    pass


class InsufficientStockError(Exception):
    pass


class ProductAlreadyInactiveError(Exception):
    pass
```

La capa API puede transformarlas en respuestas HTTP mediante el manejador global de excepciones.

---

# Orden recomendado de implementación

Para evitar sobreingeniería, se recomienda implementar los patrones progresivamente.

## Primera etapa

1. Crear casos de uso para operaciones importantes.
2. Mantener las vistas delgadas.
3. Separar comandos y consultas.
4. Crear selectors para consultas complejas.

## Segunda etapa

1. Crear entidades de dominio.
2. Crear contratos de repositorio.
3. Implementar repositorios con Django ORM.
4. Inyectar repositorios en los casos de uso.

## Tercera etapa

1. Crear adapters para servicios externos.
2. Incorporar estrategias cuando existan comportamientos intercambiables.
3. Crear factories cuando la construcción de objetos se vuelva compleja.
4. Agregar repositorios en memoria para pruebas.

---

# Decisión del proyecto

La decisión inicial del proyecto será utilizar:

- **Use Case Pattern** para representar operaciones del sistema.
- **Repository Pattern** para separar el dominio de Django ORM.
- **Adapter Pattern** para integrar servicios externos.
- **Dependency Injection** para reducir el acoplamiento.
- **CQRS ligero** para diferenciar lecturas y escrituras.

Los patrones Strategy y Factory Method se incorporarán solamente cuando exista una necesidad concreta.

La regla general será:

> API recibe, Application coordina, Domain decide e Infrastructure implementa los detalles técnicos.

---

# Conclusión

La arquitectura define la estructura general del proyecto, mientras que los patrones de diseño ayudan a resolver problemas específicos dentro de esa estructura.

El objetivo no es crear la mayor cantidad posible de abstracciones, sino mantener:

- Responsabilidades claras.
- Bajo acoplamiento.
- Código fácil de probar.
- Reglas de negocio independientes.
- Integraciones técnicas reemplazables.
- Casos de uso fáciles de comprender.

El patrón principal del proyecto será la combinación de **Use Cases, Repository, Adapter e inyección de dependencias**, complementada por una separación ligera entre comandos y consultas.
