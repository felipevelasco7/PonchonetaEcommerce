require('dotenv').config(); // Carga .env al inicio de todo
const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./config/database'); // Importa la configuración de la BD y modelos

const app = express();

// Middlewares
app.use(cors()); // Permite solicitudes de diferentes orígenes
app.use(express.json()); // Para parsear JSON en el body de las requests
app.use(express.urlencoded({ extended: true })); // Para parsear bodies x-www-form-urlencoded

// Rutas de API
const authRoutes = require('./routes/auth.routes');
const productRoutes = require('./routes/product.routes'); // Ejemplo
// ... importa otras rutas aquí

app.use('/', authRoutes); // Monta rutas de autenticación en la raíz (ej: /register, /login)
app.use('/api', productRoutes); // Monta rutas de productos bajo /api (ej: /api/products)
// ... app.use('/api', otrasRutas);

// Endpoint de Health Check para el ALB
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Servir archivos estáticos del frontend
// Asegúrate que la ruta a la carpeta 'frontend' sea correcta relativa a 'backend'
const frontendPath = path.join(__dirname, '../frontend');
app.use(express.static(frontendPath));

// Cualquier otra solicitud GET que no sea API, servir index.html (para SPA o recarga de páginas)
app.get('*', (req, res) => {
  if (!req.path.startsWith('/api') && !req.path.startsWith('/health') && req.method === 'GET') {
    res.sendFile(path.join(frontendPath, 'index.html'));
  } else {
    // Si no es una ruta de frontend y no la maneja la API, es un 404
    // Esto es un fallback, pero usualmente las rutas API ya manejarían sus propios 404
    if (!res.headersSent) { // Evitar error "Cannot set headers after they are sent to the client"
        res.status(404).json({ error: "Ruta no encontrada" });
    }
  }
});


// Sincronizar base de datos y arrancar servidor
const PORT = process.env.PORT || 3000;

db.sequelize.sync() // { force: true } para desarrollo si quieres recrear tablas (borra datos!)
  .then(() => {
    console.log("Base de datos sincronizada.");
    app.listen(PORT, () => {
      console.log(`Servidor corriendo en el puerto ${PORT}`);
      console.log(`Accede al frontend en http://localhost:${PORT}`);
      console.log(`API disponible, ej: http://localhost:${PORT}/api/products`);
    });
  })
  .catch(err => {
    console.error("Error al sincronizar la base de datos:", err);
  });