import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Get API URLs from environment or use defaults
const MACHINE1_IP = process.env.REACT_APP_MACHINE1_IP || window.location.hostname;
const MACHINE2_IP = process.env.REACT_APP_MACHINE2_IP || 'localhost';

const USER_API = `http://${MACHINE1_IP}:3001/api/users`;
const PRODUCT_API = `http://${MACHINE1_IP}:3002/api/products`;
const ORDER_API = `http://${MACHINE2_IP}:3003/api/orders`;

function App() {
  const [users, setUsers] = useState([]);
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Form states
  const [showUserForm, setShowUserForm] = useState(false);
  const [showProductForm, setShowProductForm] = useState(false);
  const [showOrderForm, setShowOrderForm] = useState(false);
  
  const [newUser, setNewUser] = useState({ name: '', email: '', age: '' });
  const [newProduct, setNewProduct] = useState({ name: '', description: '', price: '', stock: '' });
  const [newOrder, setNewOrder] = useState({ userId: '', productId: '', quantity: '', totalAmount: '' });

  // Fetch all data
  const fetchData = async () => {
    try {
      setLoading(true);
      const [usersRes, productsRes, ordersRes] = await Promise.all([
        axios.get(USER_API).catch(() => ({ data: [] })),
        axios.get(PRODUCT_API).catch(() => ({ data: [] })),
        axios.get(ORDER_API).catch(() => ({ data: [] })),
      ]);
      
      setUsers(usersRes.data);
      setProducts(productsRes.data);
      setOrders(ordersRes.data);
      setError(null);
    } catch (err) {
      setError('Failed to fetch data');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 5000); // Refresh every 5 seconds
    return () => clearInterval(interval);
  }, []);

  // Create user
  const handleCreateUser = async (e) => {
    e.preventDefault();
    try {
      await axios.post(USER_API, { ...newUser, age: parseInt(newUser.age) });
      setNewUser({ name: '', email: '', age: '' });
      setShowUserForm(false);
      fetchData();
    } catch (err) {
      alert('Failed to create user: ' + err.message);
    }
  };

  // Create product
  const handleCreateProduct = async (e) => {
    e.preventDefault();
    try {
      await axios.post(PRODUCT_API, {
        ...newProduct,
        price: parseFloat(newProduct.price),
        stock: parseInt(newProduct.stock)
      });
      setNewProduct({ name: '', description: '', price: '', stock: '' });
      setShowProductForm(false);
      fetchData();
    } catch (err) {
      alert('Failed to create product: ' + err.message);
    }
  };

  // Create order
  const handleCreateOrder = async (e) => {
    e.preventDefault();
    try {
      await axios.post(ORDER_API, {
        userId: parseInt(newOrder.userId),
        productId: parseInt(newOrder.productId),
        quantity: parseInt(newOrder.quantity),
        totalAmount: parseFloat(newOrder.totalAmount)
      });
      setNewOrder({ userId: '', productId: '', quantity: '', totalAmount: '' });
      setShowOrderForm(false);
      fetchData();
      alert('Order created! Check email worker logs for notification.');
    } catch (err) {
      alert('Failed to create order: ' + err.message);
    }
  };

  if (loading && users.length === 0) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="App">
      <header className="header">
        <h1>🚀 Microservices Demo Application</h1>
        <p>3 API Services • 2 Background Workers • Distributed Across 2 Machines</p>
      </header>

      {error && <div className="error">{error}</div>}

      <div className="dashboard">
        <div className="stat-card">
          <h3>👥 Users</h3>
          <div className="stat-number">{users.length}</div>
          <small>Machine 1 - Port 3001</small>
        </div>
        <div className="stat-card">
          <h3>📦 Products</h3>
          <div className="stat-number">{products.length}</div>
          <small>Machine 1 - Port 3002</small>
        </div>
        <div className="stat-card">
          <h3>🛒 Orders</h3>
          <div className="stat-number">{orders.length}</div>
          <small>Machine 2 - Port 3003</small>
        </div>
      </div>

      <div className="content">
        {/* Users Section */}
        <section className="section">
          <div className="section-header">
            <h2>👥 Users</h2>
            <button className="btn-add" onClick={() => setShowUserForm(!showUserForm)}>
              {showUserForm ? '✕ Cancel' : '+ Add User'}
            </button>
          </div>
          
          {showUserForm && (
            <form className="form" onSubmit={handleCreateUser}>
              <input
                type="text"
                placeholder="Name"
                value={newUser.name}
                onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                required
              />
              <input
                type="email"
                placeholder="Email"
                value={newUser.email}
                onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                required
              />
              <input
                type="number"
                placeholder="Age"
                value={newUser.age}
                onChange={(e) => setNewUser({ ...newUser, age: e.target.value })}
                required
              />
              <button type="submit" className="btn-submit">Create User</button>
            </form>
          )}

          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Age</th>
                </tr>
              </thead>
              <tbody>
                {users.map(user => (
                  <tr key={user.id}>
                    <td>{user.id}</td>
                    <td>{user.name}</td>
                    <td>{user.email}</td>
                    <td>{user.age}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {users.length === 0 && <p className="empty">No users yet</p>}
          </div>
        </section>

        {/* Products Section */}
        <section className="section">
          <div className="section-header">
            <h2>📦 Products</h2>
            <button className="btn-add" onClick={() => setShowProductForm(!showProductForm)}>
              {showProductForm ? '✕ Cancel' : '+ Add Product'}
            </button>
          </div>

          {showProductForm && (
            <form className="form" onSubmit={handleCreateProduct}>
              <input
                type="text"
                placeholder="Product Name"
                value={newProduct.name}
                onChange={(e) => setNewProduct({ ...newProduct, name: e.target.value })}
                required
              />
              <input
                type="text"
                placeholder="Description"
                value={newProduct.description}
                onChange={(e) => setNewProduct({ ...newProduct, description: e.target.value })}
              />
              <input
                type="number"
                step="0.01"
                placeholder="Price"
                value={newProduct.price}
                onChange={(e) => setNewProduct({ ...newProduct, price: e.target.value })}
                required
              />
              <input
                type="number"
                placeholder="Stock"
                value={newProduct.stock}
                onChange={(e) => setNewProduct({ ...newProduct, stock: e.target.value })}
                required
              />
              <button type="submit" className="btn-submit">Create Product</button>
            </form>
          )}

          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Description</th>
                  <th>Price</th>
                  <th>Stock</th>
                </tr>
              </thead>
              <tbody>
                {products.map(product => (
                  <tr key={product.id}>
                    <td>{product.id}</td>
                    <td>{product.name}</td>
                    <td>{product.description}</td>
                    <td>${parseFloat(product.price).toFixed(2)}</td>
                    <td>{product.stock}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {products.length === 0 && <p className="empty">No products yet</p>}
          </div>
        </section>

        {/* Orders Section */}
        <section className="section">
          <div className="section-header">
            <h2>🛒 Orders</h2>
            <button className="btn-add" onClick={() => setShowOrderForm(!showOrderForm)}>
              {showOrderForm ? '✕ Cancel' : '+ Add Order'}
            </button>
          </div>

          {showOrderForm && (
            <form className="form" onSubmit={handleCreateOrder}>
              <input
                type="number"
                placeholder="User ID"
                value={newOrder.userId}
                onChange={(e) => setNewOrder({ ...newOrder, userId: e.target.value })}
                required
              />
              <input
                type="number"
                placeholder="Product ID"
                value={newOrder.productId}
                onChange={(e) => setNewOrder({ ...newOrder, productId: e.target.value })}
                required
              />
              <input
                type="number"
                placeholder="Quantity"
                value={newOrder.quantity}
                onChange={(e) => setNewOrder({ ...newOrder, quantity: e.target.value })}
                required
              />
              <input
                type="number"
                step="0.01"
                placeholder="Total Amount"
                value={newOrder.totalAmount}
                onChange={(e) => setNewOrder({ ...newOrder, totalAmount: e.target.value })}
                required
              />
              <button type="submit" className="btn-submit">Create Order</button>
            </form>
          )}

          <div className="table-container">
            <table>
              <thead>
                <tr>
                  <th>ID</th>
                  <th>User ID</th>
                  <th>Product ID</th>
                  <th>Quantity</th>
                  <th>Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {orders.map(order => (
                  <tr key={order.id}>
                    <td>{order.id}</td>
                    <td>{order.user_id}</td>
                    <td>{order.product_id}</td>
                    <td>{order.quantity}</td>
                    <td>${parseFloat(order.total_amount).toFixed(2)}</td>
                    <td><span className={`status status-${order.status}`}>{order.status}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
            {orders.length === 0 && <p className="empty">No orders yet</p>}
          </div>
        </section>
      </div>

      <footer className="footer">
        <p>Auto-refreshing every 5 seconds • Machine 1: {MACHINE1_IP} • Machine 2: {MACHINE2_IP}</p>
      </footer>
    </div>
  );
}

export default App;
