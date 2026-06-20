from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler

from shared.application.exceptions import (
    ApplicationException,
    PermissionDeniedException,
    ResourceNotFoundException,
)
from shared.domain.exceptions import (
    DomainException,
    EntityNotFoundException,
)


def custom_exception_handler(exc, context):

    if isinstance(exc, EntityNotFoundException):
        return Response(
            {"success": False, "message": str(exc), "error": None},
            status=status.HTTP_404_NOT_FOUND,
        )

    if isinstance(exc, DomainException):
        return Response(
            {"success": False, "message": str(exc), "error": None},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )

    if isinstance(exc, PermissionDeniedException):
        return Response(
            {"success": False, "message": str(exc), "error": None},
            status=status.HTTP_403_FORBIDDEN,
        )

    if isinstance(exc, ResourceNotFoundException):
        return Response(
            {"success": False, "message": str(exc), "error": None},
            status=status.HTTP_404_NOT_FOUND,
        )

    if isinstance(exc, ApplicationException):
        return Response(
            {"success": False, "message": str(exc), "error": None},
            status=status.HTTP_400_BAD_REQUEST,
        )

    response = exception_handler(exc, context)
    if response is not None:
        data = response.data

        if isinstance(data, dict):
            message = data.get("detail", "Error")
        else:
            message = str(data)
        return Response(
            {"success": False, "message": message, "error": None},
            status=response.status_code,
        )

    return Response(
        {"success": False, "message": "Internal server error", "error": None},
        status=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )
