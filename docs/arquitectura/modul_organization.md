# Estructura de módulos — SaasStyle

Referencia de arquitectura para la organización de tablas en módulos Django.  
Las dependencias fluyen en una sola dirección: `shared → tenants → users → dominio`.

---

## Resumen de capas

| Capa | Módulo | Responsabilidad |
|------|--------|-----------------|
| L0 | `shared` | Catálogos sin dependencias externas |
| L1 | `tenants` | Multi-tenancy: negocio, sucursales, suscripción |
| L2 | `users` | Autenticación y membresías |
| L3 | `clients` | CRM por sucursal |
| L3 | `catalog` | Servicios y productos por sucursal |
| L3 | `billing` | Facturación y citas |

---

## L0 — `shared/`

Tablas de catálogo puro. Sin FK salientes, sin lógica de negocio.  
Son los primeros en migrar y en poblar con fixtures/seeds.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `tax_regimes` | Regímenes tributarios disponibles en la plataforma |
| `roles` | Roles de usuario (owner, admin, stylist, etc.) |
| `plans` | Planes de suscripción con límites de branches/users |
| `identification_types` | Tipos de documento con regex de validación |
| `payment_methods` | Métodos de pago aceptados |
| `contact_channels` | Canales de contacto (WhatsApp, SMS, Email) |

**Notas de implementación:**

- Ninguna tabla de este módulo tiene FK hacia otros módulos.
- `plans` es referenciado por `subscriptions` vía `plan_code` (UNIQUE), no por UUID — decisión de diseño para facilitar seeds y referencias legibles.
- `roles` se sincroniza con `django.contrib.auth.Group` mediante un signal `post_save`.

---

## L1 — `tenants/`

Núcleo del modelo multi-tenant. Define la jerarquía `Business → Branch` y controla el acceso por suscripción.

El middleware de tenant vive aquí y expone `request.business` y `request.branch` al resto de la app.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `businesses` | Entidad raíz del tenant (salón, spa, barbería) |
| `branches` | Sucursales de un negocio |
| `branch_schedules` | Horarios por día de la semana por sucursal |
| `subscriptions` | Suscripción activa de un negocio a un plan |

**Notas de implementación:**

- `subscriptions.plan_code` referencia `plans.code` con `ON UPDATE CASCADE`.
- `branch_schedules` tiene un `UNIQUE(branch_id, weekday)` — un registro por día.
- El middleware debe resolver el tenant antes de cualquier query en los módulos L2/L3.

---

## L2 — `users/`

Autenticación JWT y membresías. Determina qué usuario puede hacer qué dentro de cada tenant.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `users` | Usuarios de la plataforma (staff y admins) |
| `business_memberships` | Rol de un usuario a nivel de negocio |
| `branch_memberships` | Rol de un usuario a nivel de sucursal |

**Notas de implementación:**

- `business_memberships` tiene `UNIQUE(user_id, business_id)` — un usuario tiene un rol por negocio.
- `branch_memberships` tiene `UNIQUE(user_id, branch_id)` — un usuario tiene un rol por sucursal.
- Las funciones de permiso (`can_manage_branch`, `is_branch_staff`, etc.) se definen aquí.
- Un stylist típicamente tiene `branch_membership` sin `business_membership`.

---

## L3 — `clients/`

CRM por sucursal. Gestiona el historial y métricas de clientes.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `clients` | Ficha del cliente asociada a una sucursal |
| `ratings` | Calificación de una cita completada (1–5) |

**Notas de implementación:**

- `clients` acumula métricas derivadas (`last_visit`, `total_visits`, `total_spent`, `cancellations`) que se actualizan vía signal o `update_fields` al completar una cita en `billing`.
- `ratings` tiene `UNIQUE(appointment_id)` — una calificación por cita.
- `clients.created_by` referencia `users` como auditoría opcional.

---

## L3 — `catalog/`

Catálogo de servicios y productos por sucursal. Independiente de facturación.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `services` | Servicios ofrecidos (precio, duración en minutos) |
| `products` | Productos en inventario (precio, stock, stock mínimo) |

**Notas de implementación:**

- Ambas tablas son scoped por `branch_id` — cada sucursal tiene su propio catálogo.
- `billing` referencia estas tablas mediante `invoice_items.reference_id` con `item_type IN ('service', 'product')` (FK flexible, no constraint de base de datos).
- Los snapshots en `invoice_items` (`snap_name`, `unit_price`) preservan el historial de facturación ante cambios de precio o eliminación de ítems.

---

## L3 — `billing/`

Facturación e historial de citas. Módulo con más dependencias — referencia usuarios, clientes, sucursales y catálogo.

**Tablas:**

| Tabla | Descripción |
|-------|-------------|
| `invoices` | Factura emitida a un cliente en una sucursal |
| `invoice_items` | Línea de factura (servicio o producto) con snapshot |
| `appointment_history` | Registro de citas con estado y monto |

**Notas de implementación:**

- `invoice_items.reference_id` es una FK flexible — apunta a `services` o `products` según `item_type`. No tiene constraint de DB; la integridad se maneja a nivel de aplicación.
- `invoice_items.subtotal` se calcula como `(unit_price × quantity) − discount`.
- El signal de cita completada en este módulo es el que actualiza las métricas en `clients`.

---

## Decisión pendiente — `appointments/`

Actualmente `appointment_history` vive en `billing/` porque incluye `total` y status de pago. Sin embargo, si el módulo de citas crece (reagendamiento, recordatorios, disponibilidad por stylist, calendario), conviene extraerlo a su propio módulo:

```
appointments/        ← agenda, disponibilidad, notificaciones
billing/             ← invoices, invoice_items (consume appointment_id)
```

Por ahora un solo módulo es suficiente. Extraer cuando la lógica de agenda supere la de facturación en complejidad.

---

## Estructura de directorios sugerida

```
saas_style/
├── shared/
│   ├── models.py          # TaxRegime, Role, Plan, IdentificationType, PaymentMethod, ContactChannel
│   ├── admin.py
│   ├── serializers.py
│   └── fixtures/
│       └── initial_data.json
├── tenants/
│   ├── models.py          # Business, Branch, BranchSchedule, Subscription
│   ├── middleware.py      # TenantMiddleware
│   └── ...
├── users/
│   ├── models.py          # User, BusinessMembership, BranchMembership
│   ├── auth/              # JWT views, tokens
│   └── permissions.py
├── clients/
│   ├── models.py          # Client, Rating
│   └── signals.py
├── catalog/
│   ├── models.py          # Service, Product
│   └── ...
└── billing/
    ├── models.py          # Invoice, InvoiceItem, AppointmentHistory
    └── signals.py         # Actualiza métricas en clients
```