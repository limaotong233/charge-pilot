// API 封装
const API = {
  base: '/admin/api',
  token: localStorage.getItem('admin_token') || '',

  setToken(token) {
    this.token = token
    localStorage.setItem('admin_token', token)
  },

  clearToken() {
    this.token = ''
    localStorage.removeItem('admin_token')
  },

  async request(method, path, body) {
    const opts = { method, headers: { 'Content-Type': 'application/json' } }
    if (this.token) opts.headers['Authorization'] = `Bearer ${this.token}`
    if (body && method !== 'GET') opts.body = JSON.stringify(body)
    const res = await fetch(this.base + path, opts)
    const data = await res.json()
    if (data.code === 'EDU99999' || data.code === 'EDU30021') {
      this.clearToken()
      window.location.reload()
      throw new Error('登录已过期')
    }
    if (data.code !== 'EDU00000') throw new Error(data.msg || '请求失败')
    return data.data
  },

  get(path) { return this.request('GET', path) },
  post(path, body) { return this.request('POST', path, body) },
  put(path, body) { return this.request('PUT', path, body) },
  del(path) { return this.request('DELETE', path) },

  // 登录
  async login(account, password) {
    const data = await this.post('/login', { account, password })
    this.setToken(data.accessToken)
    return data
  },

  // 仪表盘
  getDashboard() { return this.get('/dashboard') },

  // 用户
  getUsers(page, size, keyword) { return this.get(`/users?page=${page}&size=${size}&keyword=${keyword || ''}`) },
  createUser(data) { return this.post('/users', data) },
  updateUser(id, data) { return this.put(`/users/${id}`, data) },

  // 充电站
  getStations(page, size, keyword) { return this.get(`/stations?page=${page}&size=${size}&keyword=${keyword || ''}`) },
  createStation(data) { return this.post('/stations', data) },
  updateStation(id, data) { return this.put(`/stations/${id}`, data) },
  deleteStation(id) { return this.del(`/stations/${id}`) },

  // 桩口
  getPorts(stationId) { return this.get(`/stations/${stationId}/ports`) },
  createPort(data) { return this.post('/ports', data) },
  updatePort(id, data) { return this.put(`/ports/${id}`, data) },
  deletePort(id) { return this.del(`/ports/${id}`) },

  // 订单
  getOrders(page, size, status) { return this.get(`/orders?page=${page}&size=${size}&status=${status || ''}`) },

  // 预约
  getReservations(page, size) { return this.get(`/reservations?page=${page}&size=${size}`) },
  cancelReservation(id) { return this.del(`/reservations/${id}`) },

  // 代金券
  getVouchers(page, size) { return this.get(`/vouchers?page=${page}&size=${size}`) },
  createVoucher(data) { return this.post('/vouchers', data) },
  updateVoucher(id, data) { return this.put(`/vouchers/${id}`, data) },
  deleteVoucher(id) { return this.del(`/vouchers/${id}`) },

  // 收藏
  getCollections(page, size) { return this.get(`/collections?page=${page}&size=${size}`) },
}
