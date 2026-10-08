CREATE TABLE IF NOT EXISTS customers(customer_id VARCHAR(20) PRIMARY KEY,name VARCHAR(100),city VARCHAR(100));
CREATE TABLE IF NOT EXISTS products(product_id VARCHAR(20) PRIMARY KEY,product_name VARCHAR(100),category VARCHAR(100),price NUMERIC(12,2));
CREATE TABLE IF NOT EXISTS orders(order_id VARCHAR(20) PRIMARY KEY,customer_id VARCHAR(20),product_id VARCHAR(20),quantity INT,amount NUMERIC(12,2),status VARCHAR(30),created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS order_items(order_item_id VARCHAR(20) PRIMARY KEY,order_id VARCHAR(20) REFERENCES orders(order_id),product_id VARCHAR(20) REFERENCES products(product_id),quantity INT,unit_price NUMERIC(12,2));
INSERT INTO customers VALUES ('C001','Arun','Chennai'),('C002','Priya','Bangalore'),('C003','Rahul','Hyderabad') ON CONFLICT DO NOTHING;
INSERT INTO products VALUES ('P001','Laptop','Electronics',65000),('P002','Smartphone','Electronics',30000),('P003','Headphones','Accessories',2500) ON CONFLICT DO NOTHING;
INSERT INTO orders(order_id,customer_id,product_id,quantity,amount,status) VALUES ('O001','C001','P001',1,65000,'PAID'),('O002','C002','P002',2,60000,'CREATED'),('O003','C003','P003',1,2500,'SHIPPED') ON CONFLICT DO NOTHING;
INSERT INTO order_items VALUES ('OI001','O001','P001',1,65000),('OI002','O002','P002',2,30000),('OI003','O003','P003',1,2500) ON CONFLICT DO NOTHING;
