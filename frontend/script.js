let allProducts = [];
let cart = [];

function saveCart() {
  localStorage.setItem('cart', JSON.stringify(cart));
}

function loadCart() {
  const saved = localStorage.getItem('cart');
  cart = saved ? JSON.parse(saved) : [];
  document.getElementById('cart-count').textContent = cart.length;
}

async function fetchProducts() {
  const res = await fetch('http://localhost:3000/products');
  allProducts = await res.json();
  renderProducts(allProducts);
}

function renderProducts(products) {
  const container = document.getElementById('product-list');
  container.innerHTML = '';
  products.forEach(p => {
    const div = document.createElement('div');
    div.className = 'product';
    div.innerHTML = `
      <h3>${p.name}</h3>
      <p>${p.description}</p>
      <p><strong>$${p.price}</strong></p>
      <p><em>${p.category} - ${p.tipo_equipo} (${p.liga})</em></p>
      <button onclick='addToCart(${JSON.stringify(p)})'>Agregar al carrito</button>
    `;
    container.appendChild(div);
  });
}

function filterBy(seccion) {
  const filtered = allProducts.filter(p => p.seccion === seccion);
  renderProducts(filtered);
}

function filterByCategory(cat) {
  const filtered = allProducts.filter(p => p.category.includes(cat));
  renderProducts(filtered);
}

function applyFilters() {
  const tipoEquipo = document.getElementById('tipo-equipo').value;
  const liga = document.getElementById('liga').value;
  const filtered = allProducts.filter(p =>
    (!tipoEquipo || p.tipo_equipo === tipoEquipo) &&
    (!liga || p.liga === liga)
  );
  renderProducts(filtered);
}

function searchProducts() {
  const term = document.getElementById('search').value.toLowerCase();
  const filtered = allProducts.filter(p => p.name.toLowerCase().includes(term));
  renderProducts(filtered);
}

function addToCart(product) {
  if (!cart.find(p => p.id === product.id)) {
    cart.push(product);
    saveCart();
    document.getElementById('cart-count').textContent = cart.length;
  } else {
    alert("Este producto ya está en el carrito.");
  }
}

loadCart();
fetchProducts();
