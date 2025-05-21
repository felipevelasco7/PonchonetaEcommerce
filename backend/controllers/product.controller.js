const db = require('../config/database');
const Product = db.Product;
const { Op } = require('sequelize'); // Para operadores como LIKE

// Crear un nuevo producto (ejemplo, requeriría autenticación de admin en app real)
exports.createProduct = async (req, res) => {
    try {
        const { name, description, price, category, availability, teamType, leagueOrCountry, imageUrl } = req.body;
        if (!name || !price) {
            return res.status(400).json({ error: "Nombre y precio son requeridos." });
        }
        const newProduct = await Product.create({ name, description, price, category, availability, teamType, leagueOrCountry, imageUrl });
        res.status(201).json(newProduct);
    } catch (error) {
        console.error("Error creando producto:", error);
        res.status(500).json({ error: "Error interno del servidor." });
    }
};

// Obtener todos los productos con filtros opcionales
exports.getAllProducts = async (req, res) => {
    try {
        const { search, category, availability, teamType, league } = req.query;
        let whereClause = {};

        if (search) {
            whereClause.name = { [Op.like]: `%${search}%` }; // Búsqueda por nombre
        }
        if (category) {
            whereClause.category = category;
        }
        if (availability) {
            whereClause.availability = availability;
        }
        if (teamType) {
            whereClause.teamType = teamType;
        }
        if (league) {
            whereClause.leagueOrCountry = league;
        }
        // Puedes añadir más filtros aquí

        const products = await Product.findAll({ where: whereClause });
        res.status(200).json(products);
    } catch (error) {
        console.error("Error obteniendo productos:", error);
        res.status(500).json({ error: "Error interno del servidor." });
    }
};

// Obtener un producto por ID
exports.getProductById = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) {
            return res.status(404).json({ error: "Producto no encontrado." });
        }
        res.status(200).json(product);
    } catch (error) {
        console.error("Error obteniendo producto por ID:", error);
        res.status(500).json({ error: "Error interno del servidor." });
    }
};

// Actualizar un producto (ejemplo)
exports.updateProduct = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) {
            return res.status(404).json({ error: "Producto no encontrado." });
        }
        await product.update(req.body);
        res.status(200).json(product);
    } catch (error) {
        console.error("Error actualizando producto:", error);
        res.status(500).json({ error: "Error interno del servidor." });
    }
};

// Eliminar un producto (ejemplo)
exports.deleteProduct = async (req, res) => {
    try {
        const product = await Product.findByPk(req.params.id);
        if (!product) {
            return res.status(404).json({ error: "Producto no encontrado." });
        }
        await product.destroy();
        res.status(200).json({ message: "Producto eliminado exitosamente." });
    } catch (error) {
        console.error("Error eliminando producto:", error);
        res.status(500).json({ error: "Error interno del servidor." });
    }
};