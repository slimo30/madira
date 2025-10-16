# api/urls.py

from django.urls import path
from .views.auth_views import (
    LoginView,
    CreateUserView,
    ListUsersView,
    GetUserByIdView,
    GetCurrentUserView,
    DeactivateUserView,
    ReactivateUserView,
    LogoutView, 

)

from .views.views import test_api



from .views.client_views import (
    ClientListCreateView,
    ClientRetrieveUpdateDeleteView,
)


from .views.supplier_views import (
    SupplierListCreateView,
    SupplierRetrieveUpdateDeleteView, )



from .views.order_views import (
    OrderListCreateView,
    OrderRetrieveUpdateDeleteView,
    ClientOrdersListView,
)



from .views.input_views import (
    InputListCreateView,
    InputRetrieveUpdateDeleteView,
    ClientInputsListView,
    OrderInputsListView
)


from .views.product_views import (
    ProductListCreateView,
    ProductRetrieveUpdateDeactivateView,        
)
urlpatterns = [
    # Test endpoint
    path('test/', test_api, name='test-api'),
    
    # Authentication
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),  

    # User management
    path('users/', ListUsersView.as_view(), name='list-users'),
    path('users/create/', CreateUserView.as_view(), name='create-user'),
    path('users/me/', GetCurrentUserView.as_view(), name='current-user'),
    path('users/<int:id>/', GetUserByIdView.as_view(), name='get-user'),
    
    # User activation/deactivation (Admin only)
    path('users/<int:user_id>/deactivate/', DeactivateUserView.as_view(), name='deactivate-user'),
    path('users/<int:user_id>/reactivate/', ReactivateUserView.as_view(), name='reactivate-user'),


    # Client management  CRUD 
    path('clients/', ClientListCreateView.as_view(), name='client-list-create'),
    path('clients/<int:pk>/', ClientRetrieveUpdateDeleteView.as_view(), name='client-detail'),

    # Supplier management CRUD
    path('suppliers/', SupplierListCreateView.as_view(), name='supplier-list-create'),
    path('suppliers/<int:pk>/', SupplierRetrieveUpdateDeleteView.as_view(), name='supplier-detail'),



    # List all orders / Create a new order
    path('orders/', OrderListCreateView.as_view(), name='order-list-create'),

    # Retrieve / Update / Cancel specific order
    path('orders/<int:pk>/', OrderRetrieveUpdateDeleteView.as_view(), name='order-detail'),



        # List all inputs or create a new one
    path('inputs/', InputListCreateView.as_view(), name='input-list-create'),

    # Retrieve, update, or delete a specific input by ID
    path('inputs/<int:pk>/', InputRetrieveUpdateDeleteView.as_view(), name='input-detail'),
    




    path('products/', ProductListCreateView.as_view(), name='product-list-create'),
    path('products/<int:pk>/', ProductRetrieveUpdateDeactivateView.as_view(), name='product-detail'),





     path('orders/<int:order_id>/inputs/', OrderInputsListView.as_view(), name='order-inputs'),
    path('clients/<int:client_id>/orders/', ClientOrdersListView.as_view(), name='client-orders'),
    path('clients/<int:client_id>/inputs/', ClientInputsListView.as_view(), name='client-inputs'),
]




