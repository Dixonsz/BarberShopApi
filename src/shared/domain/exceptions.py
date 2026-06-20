class DomainException(Exception):
    """Base para todas las excepciones de dominio."""
    pass


class BusinessRuleViolation(DomainException):
    """Una regla de negocio fue violada."""
    pass


class EntityNotFoundException(DomainException):
    """Una entidad requerida no existe."""
    pass


class InvalidValueObject(DomainException):
    """Un value object recibió un valor inválido."""
    pass