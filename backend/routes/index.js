const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const User = require('../models/User');
const bcrypt = require('bcrypt');

// Obtener productos
router.get('/products', async (req, res) => {
  const products = await Product.findAll();
  res.json(products);
});

// Registrar usuario
router.post('/register', async (req, res) => {
  const { username, password } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  try {
    const user = await User.create({ username, password: hashed });
    res.status(201).json(user);
  } catch (err) {
    res.status(400).json({ error: 'Nombre de usuario ya registrado.' });
  }
});

module.exports = router;
