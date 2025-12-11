// Create databases for microservices
db = db.getSiblingDB('product');
db.createCollection('products');
print('Created product database');

db = db.getSiblingDB('logdb');
db.createCollection('logs');
print('Created logdb database');

db = db.getSiblingDB('admin');
print('MongoDB initialization completed');
