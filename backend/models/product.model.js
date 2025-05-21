module.exports = (sequelize, DataTypes) => {
  const Product = sequelize.define("Product", {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false
    },
    category: {
      type: DataTypes.STRING,
      allowNull: true
    },
    availability: { // 'Entrega Inmediata', 'Por Encargo'
      type: DataTypes.STRING,
      allowNull: true
    },
    teamType: { // 'Club', 'Selección'
        type: DataTypes.STRING,
        allowNull: true
    },
    leagueOrCountry: {
        type: DataTypes.STRING,
        allowNull: true
    },
    imageUrl: {
        type: DataTypes.STRING,
        allowNull: true
    }
    // ... más campos según necesites
  }, {
    tableName: 'products',
    timestamps: true
  });

  return Product;
};