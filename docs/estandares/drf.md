# Convenciones de Django REST Framework

## Serializers

Los serializers son responsables de:

- Validar datos de entrada
- Convertir datos a tipos de Python
- Representar objetos en respuestas
- Aplicar validaciones simples de campos
- Controlar los campos expuestos por la API

No deben contener lógica de negocio compleja.

❌ Incorrecto:

```python
class OrderSerializer(serializers.Serializer):
    def create(self, validated_data):
        # Validar inventario.
        # Crear orden.
        # Descontar inventario.
        # Enviar correo.
        # Registrar auditoría.
        pass
```

✅ Correcto:

```python
class OrderCreateSerializer(serializers.Serializer):
    product_id = serializers.UUIDField()
    quantity = serializers.IntegerField(min_value=1)
```

La lógica de negocio debe delegarse a un servicio o caso de uso.

---

## Serializers de entrada y salida

Cuando una operación lo requiera, se deben separar los serializers por propósito:

```text
ProductCreateSerializer
ProductUpdateSerializer
ProductDetailSerializer
ProductListSerializer
```

Esto evita exponer campos internos o aceptar datos que solo deben generarse en el servidor.

---

## Vistas

Las vistas deben ser pequeñas y enfocarse en la **comunicación HTTP**.

Sus responsabilidades son:

1. Recibir la solicitud
2. Ejecutar la validación del serializer
3. Obtener el usuario autenticado
4. Ejecutar un caso de uso
5. Serializar el resultado
6. Devolver una respuesta

```python
class ProductCreateView(APIView):
    def post(self, request):
        serializer = ProductCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        product = create_product(
            user=request.user,
            data=serializer.validated_data,
        )

        output = ProductDetailSerializer(product)

        return ApiResponse.success(
            data=output.data,
            message="Producto creado correctamente.",
            status_code=201,
        )
```

Las vistas no deben implementar reglas complejas del negocio.

---

## ViewSets

Se utilizarán `ViewSet`, `GenericViewSet` o `ModelViewSet` cuando el recurso represente operaciones CRUD estándar.

Para acciones específicas se puede usar `@action`:

```python
@action(detail=True, methods=["post"])
def deactivate(self, request, pk=None):
    pass
```

No se deben habilitar operaciones que el recurso no necesite.

---

## Permisos

Los permisos reutilizables deben ubicarse en archivos `permissions.py`. Las validaciones de acceso no deben repetirse dentro de cada vista.

---

## Filtros

Los filtros deben definirse mediante clases declarativas:

```python
class ProductFilter(FilterSet):
    class Meta:
        model = Product
        fields = {
            "category": ["exact"],
            "price": ["gte", "lte"],
            "is_active": ["exact"],
        }
```