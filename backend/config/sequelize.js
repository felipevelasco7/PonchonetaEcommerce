const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('ecommerce', 'root', '', {
  host: 'ponchoneta-db.cmbn2jnrhzmq.us-east-1.rds.amazonaws.com',
  dialect: 'mysql'
});

module.exports = sequelize;
