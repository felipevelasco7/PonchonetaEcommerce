const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('ecommerce', 'root', '', {
  host: 'ecommerce-db.c0pjtanm6hnq.us-east-1.rds.amazonaws.com',
  dialect: 'mysql'
});

module.exports = sequelize;
