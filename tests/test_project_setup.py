import pytest
from django.contrib.auth import get_user_model


@pytest.mark.django_db
def test_django_database_connection():
    User = get_user_model()

    user = User.objects.create_user(username='testuser', password='testpass')
    assert user.pk is not None