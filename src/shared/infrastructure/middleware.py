import logging
import uuid

from django.http import HttpResponse
from django.utils.deprecation import MiddlewareMixin

from shared.types import TenantRequest

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(MiddlewareMixin):

    def process_request(self, request: TenantRequest) -> None:
        logger.info("%s %s", request.method, request.path)

    def process_response(
        self, request: TenantRequest, response: HttpResponse
    ) -> HttpResponse:
        logger.info(
            "%s %s → %s", request.method, request.path, response.status_code
        )
        return response


class TenantMiddleware(MiddlewareMixin):
    
    def process_request(self, request: TenantRequest) -> None:
        raw = request.headers.get("X-Tenant-ID")
        try:
            request.tenant_id = uuid.UUID(raw) if raw else None
        except ValueError:
            request.tenant_id = None