const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

// Ruta para el registro de usuarios
// POST /register (o /api/auth/register si prefieres prefijo)
router.post('/register', authController.register);

// Ruta para el inicio de sesión de usuarios
// POST /login (o /api/auth/login)
router.post('/login', authController.login);

module.exports = router;