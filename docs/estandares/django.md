# Convenciones de Django

## Aplicaciones

Cada aplicación debe representar un **módulo funcional del negocio**.

✅ Correcto:

```text
users
products
orders
payments
```

❌ Evitar nombres genéricos:

```text
main
general
data
common
utils
```

Los elementos verdaderamente compartidos deben ubicarse en el módulo `shared`.

---

## Modelos

Los modelos usan nombres en **singular** y `PascalCase`.

✅ Correcto:

```python
class Product(models.Model):
    pass
```

❌ Incorrecto:

```python
class Products(models.Model):
    pass
```

Los campos usan `snake_case`:

```python
created_at = models.DateTimeField(auto_now_add=True)
is_active = models.BooleanField(default=True)
```

Los modelos deben incluir `__str__`:

```python
def __str__(self) -> str:
    return self.name
```

---

## Relaciones

Los nombres deben representar claramente la entidad relacionada. Se debe definir `related_name` cuando facilite la navegación inversa o evite ambigüedad.

```python
category = models.ForeignKey(
    Category,
    on_delete=models.PROTECT,
    related_name="products",
)
```

---

## Restricciones de base de datos

Las reglas que deban garantizarse independientemente de la aplicación deben declararse también en la base de datos:

- Campos únicos
- Restricciones de valores
- Índices
- Integridad referencial

```python
class Meta:
    constraints = [
        models.CheckConstraint(
            condition=models.Q(price__gte=0),
            name="product_price_gte_zero",
        ),
    ]
```

---

## Consultas

Las consultas complejas no deben escribirse directamente en las vistas.

❌ Incorrecto:

```python
class ProductListView(APIView):
    def get(self, request):
        products = (
            Product.objects
            .filter(is_active=True)
            .select_related("category")
            .order_by("-created_at")
        )
```

✅ Correcto:

```python
def list_active_products():
    return (
        Product.objects
        .filter(is_active=True)
        .select_related("category")
        .order_by("-created_at")
    )
```

Las consultas de lectura deben ubicarse en `selectors.py`, `queries.py` o en un repositorio cuando corresponda.