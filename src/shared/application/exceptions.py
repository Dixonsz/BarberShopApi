from shared.domain.exceptions import (
    EntityNotFoundException,  # noqa: F401
)


class ApplicationException(Exception):
    """Base para todas las excepciones de aplicación."""
    pass

class UseCaseException(ApplicationException):
    """Error en la ejecución de un caso de uso."""
    pass

class PermissionDeniedException(ApplicationException):
    """El usuario no tiene permisos para ejecutar esta acción."""
    pass