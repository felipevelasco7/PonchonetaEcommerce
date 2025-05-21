require('dotenv').config(); // Carga variables de .env al inicio
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(
  process.env.DB_NAME,
  process.env.DB_USER,
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST,
    dialect: process.env.DB_DIALECT || 'mysql', // Default a mysql si no está en .env
    logging: false, // Cambia a console.log para ver las queries SQL
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Verificar conexión (opcional pero bueno para depurar)
sequelize.authenticate()
  .then(() => {
    console.log('Conexión a la base de datos establecida exitosamente.');
  })
  .catch(err => {
    console.error('No se pudo conectar a la base de datos:', err);
  });

const db = {};
db.Sequelize = Sequelize;
db.sequelize = sequelize;

// Importar modelos (se definirán más abajo)
db.User = require('../models/user.model.js')(sequelize, Sequelize);
db.Product = require('../models/product.model.js')(sequelize, Sequelize); // Ejemplo
// ... importa otros modelos aquí

// Definir relaciones entre modelos si existen
// Ejemplo:
// db.User.hasMany(db.Order);
// db.Order.belongsTo(db.User);

module.exports = db;