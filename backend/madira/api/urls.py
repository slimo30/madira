from django.urls import path, include
from rest_framework.routers import DefaultRouter

# ===== Import your OutputViewSet =====
from .views.output_views import OutputViewSet
from .views.stockmovement_views import StockMovementViewSet

# ===== Import your existing views =====
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
from .views.client_summary_views import (
  
    ClientCompleteDetailsView,
)
from .views.supplier_views import (
    SupplierListCreateView,
    SupplierRetrieveUpdateDeleteView,
)
from .views.order_views import (
    OrderListCreateView,
    OrderRetrieveUpdateDeleteView,
    ClientOrdersListView,
)
from .views.input_views import (
    InputListCreateView,
    InputRetrieveUpdateDeleteView,
    ClientInputsListView,
    OrderInputsListView,
)
from .views.product_views import (
    ProductListCreateView,
    ProductRetrieveUpdateDeactivateView,
)

# ===== Import Dashboard Views =====
from .views.dashbord_views import ComprehensiveDashboardView

# ===== Import Report Views =====
from .views.report_views import ComprehensiveReportView, ReportEstimateView

# ===== Import Backup Views =====
from .views.backup_views import DatabaseBackupView

# ======================================================
#  1. Add DRF router for OutputViewSet and StockMovementViewSet
# ======================================================
router = DefaultRouter()
router.register(r'outputs', OutputViewSet, basename='output')
router.register(r'stock-movements', StockMovementViewSet, basename='stockmovement')

# ======================================================
#  2. Define URL patterns (your existing + router URLs)
# ======================================================
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

    # User activation/deactivation
    path('users/<int:user_id>/deactivate/', DeactivateUserView.as_view(), name='deactivate-user'),
    path('users/<int:user_id>/reactivate/', ReactivateUserView.as_view(), name='reactivate-user'),

    # Clients CRUD
    path('clients/', ClientListCreateView.as_view(), name='client-list-create'),
    path('clients/<int:pk>/', ClientRetrieveUpdateDeleteView.as_view(), name='client-detail'),
    
   
    #  FLUTTER DESKTOP - COMPLETE CLIENT DETAILS (EVERYTHING IN ONE API)
    path('clients/<int:client_id>/complete/', ClientCompleteDetailsView.as_view(), name='client-complete-details'),

    # Suppliers CRUD
    path('suppliers/', SupplierListCreateView.as_view(), name='supplier-list-create'),
    path('suppliers/<int:pk>/', SupplierRetrieveUpdateDeleteView.as_view(), name='supplier-detail'),

    # Orders CRUD
    path('orders/', OrderListCreateView.as_view(), name='order-list-create'),
    path('orders/<int:pk>/', OrderRetrieveUpdateDeleteView.as_view(), name='order-detail'),

    # Inputs CRUD
    path('inputs/', InputListCreateView.as_view(), name='input-list-create'),
    path('inputs/<int:pk>/', InputRetrieveUpdateDeleteView.as_view(), name='input-detail'),

    # Products CRUD
    path('products/', ProductListCreateView.as_view(), name='product-list-create'),
    path('products/<int:pk>/', ProductRetrieveUpdateDeactivateView.as_view(), name='product-detail'),

    # Relations
    path('orders/<int:order_id>/inputs/', OrderInputsListView.as_view(), name='order-inputs'),
    path('clients/<int:client_id>/orders/', ClientOrdersListView.as_view(), name='client-orders'),
    path('clients/<int:client_id>/inputs/', ClientInputsListView.as_view(), name='client-inputs'),

    # ======================================================
    #  COMPREHENSIVE DASHBOARD ANALYTICS - ALL DATA IN ONE API
    # ======================================================
    path('dashboard/', ComprehensiveDashboardView.as_view(), name='dashboard'),

    # ======================================================
    #  COMPREHENSIVE REPORT - All Data in One Excel File
    # ======================================================
    # Estimate report generation time before downloading
    path('reports/estimate/', ReportEstimateView.as_view(), name='report-estimate'),
    
    # Download the full report
    path('reports/download/', ComprehensiveReportView.as_view(), name='report-download'),

    # ======================================================
    #  DATABASE BACKUP & RESTORE - SQL Files
    # ======================================================
    # Get backup/restore information
    # path('backup/info/', BackupInfoView.as_view(), name='backup-info'),
    
    # Download SQL backup
    path('backup/download/', DatabaseBackupView.as_view(), name='backup-download'),
    
    # Restore from SQL backup
    # path('backup/restore/', DatabaseRestoreView.as_view(), name='backup-restore'),

    # ======================================================
    #  3. Include router-generated URLs (Outputs)
    # ======================================================
    path('', include(router.urls)),
]



