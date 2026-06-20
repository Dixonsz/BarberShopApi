from typing import Any

from rest_framework import status
from rest_framework.response import Response


class SuccessResponse:
    @staticmethod
    def success(
        *,
        data: Any = None,
        message: str = "Success",
        status_code: int = status.HTTP_200_OK,
        meta: dict[str, Any] | None = None,
    ) -> Response:
        return Response(
            {"success": True, "message": message, "data": data, "meta": meta},
            status=status_code,
        )
