# Session 3 - PostgreSQL Operational E-Commerce Data

## Start
```powershell
.\scripts\session\02-START-POSTGRES.ps1
```

## Connect
```powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

## Explore
```sql
\dt
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM order_items;
```

## CDC preparation exercise
```sql
INSERT INTO orders(order_id,customer_id,product_id,quantity,amount,status) VALUES ('LAB01','C001','P002',1,30000,'CREATED');
UPDATE orders SET status='PAID' WHERE order_id='LAB01';
DELETE FROM orders WHERE order_id='LAB01';
```

Remember these three operations. They will be observed through Debezium in Session 6.
