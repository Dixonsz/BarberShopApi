from typing import Any

from rest_framework import status
from rest_framework.response import Response


class ErrorResponse:
    @staticmethod
    def error(
        *,
        message: str = "Error occurred",
        error: Any = None,
        status_code: int = status.HTTP_400_BAD_REQUEST,
    ) -> Response:
        return Response(
            {"success": False, "message": message, "error": error},
            status=status_code,
        )
