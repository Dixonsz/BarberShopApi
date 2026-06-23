from django.db import models


class Environment(models.TextChoices):
    DEVELOPMENT = 'development', 'Development'
    STAGING = 'staging', 'Staging'
    PRODUCTION = 'production', 'Production'

class BusinessType(models.TextChoices):
    SALON = 'salon', 'Salon'
    SPA = 'spa', 'Spa'
    BARBERSHOP = 'barbershop', 'Barbershop'

class Visibility(models.TextChoices):
    PUBLIC = 'public', 'Public'
    PRIVATE = 'private', 'Private'


DEFAULT_PAGE_SIZE = 10
MAX_PAGE_SIZE = 100

DATE_FORMAT = '%Y-%m-%d'
DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S'