from rest_framework import serializers


class BaseModelSerializers(serializers.ModelSerializer):
    """
    Base serializer for all models, providing common functionality.
    """
    def validate(self, attrs):
        attrs = super().validate(attrs)
        return attrs

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        return representation

class BaseSerializer(serializers.Serializer):
    """
    Base serializer for non-model serializers, providing common functionality.
    """
    def validate(self, attrs):
        attrs = super().validate(attrs)
        return attrs

   