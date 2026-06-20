from rest_framework import status
from rest_framework.response import Response


class NotFoundResponse:
    @staticmethod
    def not_found(
        *,
        message: str = "Resource not found",
        status_code: int = status.HTTP_404_NOT_FOUND,
    ) -> Response:
        return Response(
            {"success": False, "message": message, "error": None},
            status=status_code,
        )