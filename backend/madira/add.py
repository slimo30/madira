#!/usr/bin/env python
"""
Random Data Generator for Madira Database - CONSTRAINT-AWARE VERSION
====================================================================
Respects ALL model constraints and validation rules.

Usage:
    python add.py --small
    python add.py --medium  
    python add.py --large
    python add.py --xlarge  # 1 MILLION ROWS
"""

import os
import sys
import django
import random
from datetime import datetime, timedelta
from decimal import Decimal
from faker import Faker

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'madira.settings')
django.setup()

from django.contrib.auth import get_user_model
from django.utils import timezone
from api.models import (
    Client, Supplier, Product, Order, Input, Output, 
    OrderOutput, StockMovement
)

fake = Faker(['fr_FR', 'ar_SA'])
User = get_user_model()


class DataGenerator:
    """Generate random test data respecting ALL model constraints"""
    
    def __init__(self, verbose=True):
        self.verbose = verbose
        self.created_users = []
        self.created_clients = []
        self.created_suppliers = []
        self.created_products = []
        self.created_orders = []
        self.created_inputs = []
        self.created_outputs = []
        
    def log(self, message):
        if self.verbose:
            print(f" {message}")
    
    def clear_all_data(self):
        """Clear all data from the database in correct order (respecting FK constraints)"""
        print("\n️  Clearing all data...")
        
        # Delete in correct order to respect PROTECT foreign keys
        OrderOutput.objects.all().delete()  # First - references StockMovement and Output
        StockMovement.objects.all().delete()  # Second - references Output
        Output.objects.all().delete()  # Third - references Input
        Input.objects.all().delete()  # Fourth - references Order
        Order.objects.all().delete()  # Fifth - references Client
        Product.objects.all().delete()
        Supplier.objects.all().delete()
        Client.objects.all().delete()
        User.objects.exclude(is_superuser=True).delete()
        
        print(" All data cleared!\n")
    
    def create_users(self, count=5):
        print(f"\n Creating {count} users...")
        roles = [User.Role.ADMIN, User.Role.RESPONSIBLE]
        
        for i in range(count):
            username = f"user_{fake.user_name()}_{i}"
            user = User.objects.create_user(
                username=username[:50],
                password='password123',
                full_name=fake.name()[:100],
                role=random.choice(roles),
                is_active=True
            )
            self.created_users.append(user)
        print(f" Created {len(self.created_users)} users\n")
    
    def create_clients(self, count=50):
        print(f"\n Creating {count} clients...")
        cities = ['Alger', 'Oran', 'Constantine', 'Annaba', 'Blida']
        client_types = [Client.Type.NEW, Client.Type.OLD]
        
        for i in range(count):
            client = Client.objects.create(
                name=(fake.company() if random.random() > 0.6 else fake.name())[:100],
                phone=f"0{random.randint(5, 7)}{random.randint(10000000, 99999999)}"[:20],
                address=f"{fake.street_address()}, {random.choice(cities)}",
                client_type=random.choice(client_types),
                credit_balance=Decimal(random.randint(0, 50000)),
                is_active=True,
                notes=fake.sentence() if random.random() > 0.5 else ''
            )
            self.created_clients.append(client)
            if (i + 1) % 100 == 0:
                self.log(f"Created {i+1}/{count} clients...")
        print(f" Created {len(self.created_clients)} clients\n")
    
    def create_suppliers(self, count=20):
        print(f"\n Creating {count} suppliers...")
        types = ['Construction', 'Quincaillerie', 'Électricité', 'Plomberie']
        
        for i in range(count):
            supplier = Supplier.objects.create(
                name=f"{fake.company()} {random.choice(types)}"[:100],
                phone=f"0{random.randint(5, 7)}{random.randint(10000000, 99999999)}"[:20],
                address=fake.address(),
                is_active=True,
                notes=''
            )
            self.created_suppliers.append(supplier)
        print(f" Created {len(self.created_suppliers)} suppliers\n")
    
    def create_products(self, count=30):
        print(f"\n Creating {count} products...")
        products = [
            ('Ciment 50kg', Product.Unit.KILOGRAM),
            ('Sable', Product.Unit.SQUARE_METER),
            ('Brique', Product.Unit.PIECE),
            ('Fer 8mm', Product.Unit.KILOGRAM),
            ('Peinture', Product.Unit.LITER),
            ('Carrelage', Product.Unit.SQUARE_METER),
            ('Porte', Product.Unit.PIECE),
            ('Fenêtre', Product.Unit.PIECE),
        ]
        
        for i in range(min(count, len(products) * 4)):
            name, unit = products[i % len(products)]
            product = Product.objects.create(
                name=f"{name} {i+1}"[:100],
                unit=unit,
                current_quantity=Decimal(random.randint(0, 500)),
                description='',
                is_active=True
            )
            self.created_products.append(product)
        print(f" Created {len(self.created_products)} products\n")
    
    def create_orders(self, count=100):
        print(f"\n Creating {count} orders...")
        statuses = [Order.Status.PENDING, Order.Status.IN_PROGRESS, Order.Status.COMPLETED, Order.Status.CANCELLED]
        
        for i in range(count):
            client = random.choice(self.created_clients)
            days_ago = random.randint(0, 180)
            order_date = timezone.now() - timedelta(days=days_ago)
            
            # CONSTRAINT: total_amount max 12 digits, 2 decimals = max 9,999,999,999.99
            total_amount = Decimal(random.randint(10000, 9999999))  # Max ~10M DA
            status = random.choice(statuses)
            
            # NOTE: paid_amount is now a @property calculated from Input objects
            # We create the order first, then create Input objects to simulate payments
            
            order = Order.objects.create(
                client=client,
                order_date=order_date,
                delivery_date=order_date + timedelta(days=random.randint(1, 30)) if random.random() > 0.3 else None,
                status=status,
                total_amount=total_amount,
                description=''
            )
            self.created_orders.append(order)
            
            if (i + 1) % 500 == 0:
                self.log(f"Created {i+1}/{count} orders...")
        print(f" Created {len(self.created_orders)} orders\n")
    
    def create_inputs(self, count=200):
        print(f"\n Creating {count} inputs...")
        input_types = [Input.Type.CLIENT_PAYMENT, Input.Type.SHOP_DEPOSIT]
        
        created = 0
        attempts = 0
        max_attempts = count * 3
        
        while created < count and attempts < max_attempts:
            attempts += 1
            user = random.choice(self.created_users)
            input_type = random.choice(input_types)
            
            days_ago = random.randint(0, 180)
            input_date = timezone.now() - timedelta(days=days_ago)
            
            # CONSTRAINT: amount max 12 digits
            amount = Decimal(random.randint(10000, 9999999))
            
            order = None
            
            # CONSTRAINT: CLIENT_PAYMENT requires order, SHOP_DEPOSIT must NOT have order
            if input_type == Input.Type.CLIENT_PAYMENT:
                unpaid_orders = [o for o in self.created_orders if o.remaining_amount > Decimal('100')]
                if not unpaid_orders:
                    continue
                order = random.choice(unpaid_orders)
                # CONSTRAINT: Prevent overpayment
                amount = min(amount, order.remaining_amount)
                if amount < Decimal('100'):
                    continue
            
            try:
                inp = Input.objects.create(
                    type=input_type,
                    amount=amount,
                    date=input_date,
                    order=order,
                    created_by=user,
                    description=''
                )
                self.created_inputs.append(inp)
                created += 1
                
                if created % 500 == 0:
                    self.log(f"Created {created}/{count} inputs...")
            except Exception as e:
                continue
        
        print(f" Created {len(self.created_inputs)} inputs\n")
    
    def create_outputs(self, count=300):
        print(f"\n Creating {count} outputs...")
        
        # All 6 output types
        output_types = [
            Output.Type.WITHDRAWAL,
            Output.Type.SUPPLIER_PAYMENT,
            Output.Type.CONSUMABLE,
            Output.Type.GLOBAL_STOCK_PURCHASE,
            Output.Type.CLIENT_STOCK_USAGE,
            Output.Type.OTHER_EXPENSE
        ]
        
        # OPTIMIZATION: Cache input balances in memory to avoid repeated DB queries
        input_balances = {inp.id: inp.amount for inp in self.created_inputs}
        
        created = 0
        attempts = 0
        max_attempts = count * 2  # Reduced from 3x
        
        while created < count and attempts < max_attempts:
            attempts += 1
            
            # OPTIMIZATION: Find inputs with balance from cache (no DB queries)
            available_inputs = [
                inp for inp in self.created_inputs 
                if input_balances[inp.id] > Decimal('1000')
            ]
            
            if not available_inputs:
                print(f"️  No more inputs with sufficient balance. Created {created}/{count} outputs.")
                break
            
            user = random.choice(self.created_users)
            output_type = random.choice(output_types)
            source_input = random.choice(available_inputs)
            
            days_ago = random.randint(0, 180)
            output_date = timezone.now() - timedelta(days=days_ago)
            
            # Amount: don't exceed cached balance
            max_amount = min(input_balances[source_input.id], Decimal('999999'))
            if max_amount < Decimal('100'):
                continue
            
            amount = Decimal(random.randint(100, int(max_amount)))
            
            # Apply OUTPUT CONSTRAINTS
            order = None
            supplier = None
            product = None
            
            try:
                # WITHDRAWAL: no order, supplier, or product
                if output_type == Output.Type.WITHDRAWAL:
                    pass
                
                # SUPPLIER_PAYMENT: requires supplier + order, no product
                elif output_type == Output.Type.SUPPLIER_PAYMENT:
                    if not self.created_suppliers or not self.created_orders:
                        continue
                    supplier = random.choice(self.created_suppliers)
                    order = random.choice(self.created_orders)
                
                # CONSUMABLE: no order, supplier, or product
                elif output_type == Output.Type.CONSUMABLE:
                    pass
                
                # GLOBAL_STOCK_PURCHASE: requires product, no order or supplier
                elif output_type == Output.Type.GLOBAL_STOCK_PURCHASE:
                    if not self.created_products:
                        continue
                    product = random.choice(self.created_products)
                
                # CLIENT_STOCK_USAGE: requires order + product, no supplier
                elif output_type == Output.Type.CLIENT_STOCK_USAGE:
                    if not self.created_orders or not self.created_products:
                        continue
                    order = random.choice(self.created_orders)
                    product = random.choice(self.created_products)
                
                # OTHER_EXPENSE: order optional, no supplier or product
                elif output_type == Output.Type.OTHER_EXPENSE:
                    if self.created_orders and random.random() > 0.5:
                        order = random.choice(self.created_orders)
                
                output = Output.objects.create(
                    type=output_type,
                    amount=amount,
                    date=output_date,
                    source_input=source_input,
                    order=order,
                    supplier=supplier,
                    product=product,
                    created_by=user,
                    description=''
                )
                self.created_outputs.append(output)
                
                # OPTIMIZATION: Update cached balance immediately (no DB query needed)
                input_balances[source_input.id] -= amount
                
                created += 1
                
                if created % 100 == 0:
                    self.log(f"Created {created}/{count} outputs...")
                    
            except Exception as e:
                # If creation fails, restore the balance
                input_balances[source_input.id] += amount
                continue
        
        print(f" Created {len(self.created_outputs)} outputs\n")
    
    def create_stock_movements(self, count=200):
        print(f"\n Creating {count} stock movements...")
        
        if not self.created_products:
            print("No products available")
            return
        
        created = 0
        for i in range(count):
            product = random.choice(self.created_products)
            movement_type = random.choice([StockMovement.MovementType.IN, StockMovement.MovementType.OUT])
            user = random.choice(self.created_users)
            
            days_ago = random.randint(0, 180)
            movement_date = timezone.now() - timedelta(days=days_ago)
            
            quantity = Decimal(random.randint(1, 100))
            price = Decimal(random.randint(100, 10000))
            
            # CONSTRAINT: OUT requires order, IN must NOT have order
            order = None
            created_by_output = None
            
            if movement_type == StockMovement.MovementType.OUT:
                if not self.created_orders:
                    continue
                order = random.choice(self.created_orders)
                if self.created_outputs and random.random() > 0.5:
                    created_by_output = random.choice(self.created_outputs)
            
            try:
                movement = StockMovement.objects.create(
                    product=product,
                    movement_type=movement_type,
                    quantity=quantity,
                    price=price,
                    date=movement_date,
                    order=order,
                    created_by=user,
                    created_by_output=created_by_output
                )
                created += 1
                
                if created % 500 == 0:
                    self.log(f"Created {created} stock movements...")
                    
            except Exception as e:
                continue
        
        print(f" Created {created} stock movements\n")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate test data for Madira database')
    parser.add_argument('--clear', action='store_true', help='Clear all data first')
    parser.add_argument('--small', action='store_true', help='~1K rows')
    parser.add_argument('--medium', action='store_true', help='~5K rows')
    parser.add_argument('--large', action='store_true', help='~20K rows')
    parser.add_argument('--xlarge', action='store_true', help='~1M rows')
    parser.add_argument('--balanced10k', action='store_true', help='Each model has 10K+ rows (~80K total)')
    parser.add_argument('--custom20k', action='store_true', help='Exactly ~20K rows total')
    parser.add_argument('--quiet', action='store_true', help='Minimal output')
    
    # Custom count arguments
    parser.add_argument('--users', type=int, help='Number of users')
    parser.add_argument('--clients', type=int, help='Number of clients')
    parser.add_argument('--suppliers', type=int, help='Number of suppliers')
    parser.add_argument('--products', type=int, help='Number of products')
    parser.add_argument('--orders', type=int, help='Number of orders')
    parser.add_argument('--inputs', type=int, help='Number of inputs')
    parser.add_argument('--outputs', type=int, help='Number of outputs')
    parser.add_argument('--movements', type=int, help='Number of stock movements')
    
    args = parser.parse_args()
    
    if args.small:
        counts = {'users': 3, 'clients': 20, 'suppliers': 10, 'products': 15,
                  'orders': 50, 'inputs': 100, 'outputs': 150, 'movements': 100}
    elif args.medium:
        counts = {'users': 5, 'clients': 50, 'suppliers': 20, 'products': 30,
                  'orders': 200, 'inputs': 400, 'outputs': 600, 'movements': 400}
    elif args.large:
        counts = {'users': 10, 'clients': 100, 'suppliers': 40, 'products': 50,
                  'orders': 1000, 'inputs': 2000, 'outputs': 3000, 'movements': 2000}
    elif args.balanced10k:
        # Each model gets at least 10,000 rows - BALANCED DISTRIBUTION
        # Total: ~80,000 rows
        counts = {
            'users': 100,           # 100 users (small but sufficient)
            'clients': 10000,       # 10K clients
            'suppliers': 10000,     # 10K suppliers  
            'products': 10000,      # 10K products
            'orders': 15000,        # 15K orders (needs to support inputs)
            'inputs': 15000,        # 15K inputs (needs to fund outputs)
            'outputs': 10000,       # 10K outputs (limited by input balance)
            'movements': 10000      # 10K stock movements
        }
    elif args.custom20k:
        # Updated: Each major model has 10K+ rows
        # Total: ~75K rows
        counts = {
            'users': 50,
            'clients': 10000,
            'suppliers': 10000,
            'products': 10000,
            'orders': 15000,
            'inputs': 15000,
            'outputs': 10000,
            'movements': 10000
        }
    elif args.xlarge:
        counts = {'users': 50, 'clients': 5000, 'suppliers': 500, 'products': 200,
                  'orders': 100000, 'inputs': 200000, 'outputs': 400000, 'movements': 300000}
    else:
        # Use custom arguments if provided
        counts = {
            'users': args.users or 5,
            'clients': args.clients or 50,
            'suppliers': args.suppliers or 20,
            'products': args.products or 30,
            'orders': args.orders or 100,
            'inputs': args.inputs or 200,
            'outputs': args.outputs or 300,
            'movements': args.movements or 200
        }
    
    print("\n" + "="*60)
    print(" MADIRA DATABASE - CONSTRAINT-AWARE DATA GENERATOR")
    print("="*60)
    print(f"\n Generation Plan: ~{sum(counts.values())} rows")
    for key, val in counts.items():
        print(f"   {key.title()}: {val}")
    print("="*60)
    
    if not args.quiet:
        confirm = input("\n️  Proceed? (y/n): ")
        if confirm.lower() != 'y':
            print(" Cancelled.")
            return
    
    generator = DataGenerator(verbose=not args.quiet)
    start_time = datetime.now()
    print(f"\n⏰ Started: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        if args.clear:
            generator.clear_all_data()
        
        generator.create_users(counts['users'])
        generator.create_clients(counts['clients'])
        generator.create_suppliers(counts['suppliers'])
        generator.create_products(counts['products'])
        generator.create_orders(counts['orders'])
        generator.create_inputs(counts['inputs'])
        generator.create_outputs(counts['outputs'])
        generator.create_stock_movements(counts['movements'])
        
        duration = (datetime.now() - start_time).total_seconds()
        
        print("\n" + "="*60)
        print(" COMPLETED!")
        print("="*60)
        print(f"⏱️  Duration: {duration:.2f} seconds")
        print(f" Created:")
        print(f"   Users: {len(generator.created_users)}")
        print(f"   Clients: {len(generator.created_clients)}")
        print(f"   Suppliers: {len(generator.created_suppliers)}")
        print(f"   Products: {len(generator.created_products)}")
        print(f"   Orders: {len(generator.created_orders)}")
        print(f"   Inputs: {len(generator.created_inputs)}")
        print(f"   Outputs: {len(generator.created_outputs)}")
        print("="*60 + "\n")
        
    except Exception as e:
        print(f"\n Error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
