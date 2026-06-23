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

    @staticmethod
    def created(*, data: Any = None, message: str = "Created") -> Response:
        return SuccessResponse.success(
            data=data,
            message=message,
            status_code=status.HTTP_201_CREATED,
        )
