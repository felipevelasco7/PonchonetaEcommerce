const express = require('express');
const router = express.Router();
const productController = require('../controllers/product.controller');
// const authMiddleware = require('../middlewares/authMiddleware'); // Ejemplo si necesitas proteger rutas

// Rutas de productos
// GET /products (o /api/products)
router.get('/products', productController.getAllProducts);
// POST /products (requeriría autenticación de admin en app real)
router.post('/products', productController.createProduct);

// GET /products/:id
router.get('/products/:id', productController.getProductById);
// PUT /products/:id (requeriría autenticación de admin)
router.put('/products/:id', productController.updateProduct);
// DELETE /products/:id (requeriría autenticación de admin)
router.delete('/products/:id', productController.deleteProduct);


module.exports = router;