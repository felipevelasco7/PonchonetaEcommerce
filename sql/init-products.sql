CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  description TEXT,
  price DECIMAL(10,2),
  category VARCHAR(50),
  tipo_equipo ENUM('Club', 'Selección'),
  liga VARCHAR(50),
  seccion ENUM('Entrega Inmediata', 'Por Encargo')
);

INSERT INTO products (name, description, price, category, tipo_equipo, liga, seccion) VALUES
('Camiseta Retro Colombia 98', 'Versión clásica selección Colombia 1998', 159900, 'Retro', 'Selección', 'Colombia', 'Por Encargo'),
('Camiseta Liverpool 23/24', 'Versión jugador local', 229900, 'Jugador', 'Club', 'Inglaterra', 'Entrega Inmediata'),
('Mystery Shirt', 'Caja sorpresa con camiseta de club europeo', 189900, 'Mystery', 'Club', 'Otros', 'Entrega Inmediata'),
('Medias Real Madrid', 'Medias oficiales temporada actual', 49900, 'Medias', 'Club', 'España', 'Entrega Inmediata'),
('Camiseta AC Milan Retro 2003', 'Retro de la Champions ganada por el Milan', 179900, 'Retro', 'Club', 'Italia', 'Por Encargo'),
('Camiseta Selección Argentina 2022', 'Versión campeón del mundo', 239900, 'Jugador', 'Selección', 'Argentina', 'Entrega Inmediata');
