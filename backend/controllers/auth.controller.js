const db = require('../config/database');
const User = db.User; // Acceder al modelo User desde el objeto db

// No necesitas importar bcrypt aquí si el hook del modelo ya lo maneja al crear
// const bcrypt = require('bcryptjs'); 
// const jwt = require('jsonwebtoken'); // Descomentar si implementas JWT

exports.register = async (req, res) => {
  try {
    const { fullName, email, username, password, phone } = req.body;

    // Validaciones básicas
    if (!fullName || !email || !username || !password) {
      return res.status(400).json({ error: "Todos los campos obligatorios (nombre completo, email, usuario, contraseña) son requeridos." });
    }

    // Verificar si el email o username ya existen
    const existingUserByEmail = await User.findOne({ where: { email: email } });
    if (existingUserByEmail) {
      return res.status(400).json({ error: "El correo electrónico ya está registrado." });
    }
    const existingUserByUsername = await User.findOne({ where: { username: username } });
    if (existingUserByUsername) {
      return res.status(400).json({ error: "El nombre de usuario ya existe." });
    }

    // Crear usuario (la contraseña se hasheará automáticamente por el hook del modelo)
    const newUser = await User.create({
      fullName,
      email,
      username,
      password,
      phone
    });

    // No enviar la contraseña hasheada en la respuesta
    const userResponse = { ...newUser.toJSON() };
    delete userResponse.password;

    res.status(201).json({ message: "Usuario registrado exitosamente.", user: userResponse });

  } catch (error) {
    console.error("Error en el registro:", error);
    if (error.name === 'SequelizeValidationError') {
        return res.status(400).json({ error: error.errors.map(e => e.message).join(', ') });
    }
    res.status(500).json({ error: "Error interno del servidor al registrar el usuario." });
  }
};

exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: "Nombre de usuario y contraseña son requeridos." });
    }

    const user = await User.findOne({ where: { username: username } });
    if (!user) {
      return res.status(401).json({ error: "Credenciales inválidas (usuario no encontrado)." });
    }

    const isMatch = await user.isValidPassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: "Credenciales inválidas (contraseña incorrecta)." });
    }

    // Aquí generarías y enviarías un JWT en una aplicación real
    // const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '1h' });

    // No enviar la contraseña hasheada
    const userResponse = { ...user.toJSON() };
    delete userResponse.password;
    
    // Por ahora, solo confirmamos el login exitoso y devolvemos datos del usuario (sin contraseña)
    res.status(200).json({ 
        message: "Inicio de sesión exitoso.", 
        user: userResponse
        // token: token // Descomentar si implementas JWT
    });

  } catch (error) {
    console.error("Error en el inicio de sesión:", error);
    res.status(500).json({ error: "Error interno del servidor al iniciar sesión." });
  }
};