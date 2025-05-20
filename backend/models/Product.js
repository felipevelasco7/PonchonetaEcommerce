const { DataTypes } = require('sequelize');
const sequelize = require('../config/sequelize');

const Product = sequelize.define('Product', {
  name: DataTypes.STRING,
  description: DataTypes.TEXT,
  price: DataTypes.DECIMAL(10, 2),
  category: DataTypes.STRING,
  tipo_equipo: DataTypes.ENUM('Club', 'Selección'),
  liga: DataTypes.STRING,
  seccion: DataTypes.ENUM('Entrega Inmediata', 'Por Encargo')
});

module.exports = Product;
