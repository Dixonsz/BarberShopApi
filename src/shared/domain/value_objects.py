from dataclasses import dataclass

from shared.domain.exceptions import InvalidValueObject


@dataclass(frozen=True)
class Email:
    value: str

    def __post_init__(self):
        if not self.value or "@" not in self.value:
            raise InvalidValueObject(f"Invalid email address: {self.value}")


@dataclass(frozen=True)
class PhoneNumber:
    value: str

    def __post_init__(self):
        if not self.value or not self.value.isdigit() or not (7 <= len(self.value) <= 15):
            raise InvalidValueObject(f"Invalid phone number: {self.value}")
@dataclass(frozen=True)
class NonEmptyString:
    value: str

    def __post_init__(self):
        if not self.value or not self.value.strip():
            raise InvalidValueObject("String cannot be empty or whitespace.")