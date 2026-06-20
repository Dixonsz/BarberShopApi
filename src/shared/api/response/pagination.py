from typing import Any

from rest_framework import status
from rest_framework.response import Response


class PaginationResponse:
    @staticmethod
    def paginated_response(
        *,
        data: Any,
        message: str = "Success",
        page: int,
        page_size: int,
        total_items: int,
    ) -> Response:
        total_pages = -(-total_items // page_size)
        return Response(
            {
                "success": True,
                "message": message,
                "data": data,
                "meta": {
                    "page": page,
                    "page_size": page_size,
                    "total_items": total_items,
                    "total_pages": total_pages,
                },
            },
            status=status.HTTP_200_OK,
        )
