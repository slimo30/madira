from rest_framework import generics, permissions, status
from rest_framework.response import Response
from ..models import Product
from ..serializers import ProductSerializer

# ---------------------------
# List and Create
# ---------------------------
class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.filter(is_active=True).order_by('name')
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]


# ---------------------------
# Retrieve, Update, Deactivate (instead of Delete)
# ---------------------------
class ProductRetrieveUpdateDeactivateView(generics.RetrieveUpdateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        """
        Soft delete → deactivate instead of delete
        """
        product = self.get_object()
        product.is_active = False
        product.save()
        return Response({'detail': f'{product.name} has been deactivated.'},
                        status=status.HTTP_200_OK)
