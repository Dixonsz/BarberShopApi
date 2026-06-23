import uuid
from typing import Any

from django.http import HttpRequest

UUID = uuid.UUID

type JsonDict = dict[str, Any]
type Headers = dict[str, str]


class TenantRequest(HttpRequest):
    tenant_id: UUID | None