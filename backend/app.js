const express = require('express');
const cors = require('cors');
const sequelize = require('./config/sequelize');
const Product = require('./models/Product');
const User = require('./models/User');
const routes = require('./routes/index');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use('/', routes);

sequelize.sync().then(() => {
  app.listen(port, () => console.log(`Servidor corriendo en http://localhost:${port}`));
});
