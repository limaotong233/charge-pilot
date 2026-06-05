// 全局状态
let currentPage = 'dashboard'
let pagination = { page: 1, size: 20, total: 0 }

// ============ 工具函数 ============
function toast(msg, type = 'success') {
  const el = document.createElement('div')
  el.className = `toast toast-${type}`
  el.textContent = msg
  document.body.appendChild(el)
  setTimeout(() => el.remove(), 2500)
}

function formatTime(t) {
  if (!t) return '-'
  const d = new Date(t)
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')} ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
}

function statusBadge(status, map) {
  const item = map[status] || { text: '未知', cls: 'badge-info' }
  return `<span class="badge ${item.cls}">${item.text}</span>`
}

const ORDER_STATUS = { 0: { text: '进行中', cls: 'badge-info' }, 1: { text: '待支付', cls: 'badge-warning' }, 2: { text: '已完成', cls: 'badge-success' } }
const PORT_STATUS = { 0: { text: '空闲', cls: 'badge-success' }, 1: { text: '已预约', cls: 'badge-warning' }, 2: { text: '充电中', cls: 'badge-danger' } }
const RES_STATUS = { 0: { text: '进行中', cls: 'badge-info' }, 1: { text: '已完成', cls: 'badge-success' }, 2: { text: '已取消', cls: 'badge-danger' } }

function paginate(total) {
  const pages = Math.ceil(total / pagination.size)
  let html = '<div class="pagination">'
  html += `<button ${pagination.page<=1?'disabled':''} onclick="goPage(${pagination.page-1})">上一页</button>`
  html += `<span class="page-info">第 ${pagination.page} / ${pages || 1} 页，共 ${total} 条</span>`
  html += `<button ${pagination.page>=pages?'disabled':''} onclick="goPage(${pagination.page+1})">下一页</button>`
  html += '</div>'
  return html
}

function goPage(p) { pagination.page = p; loadPage(currentPage) }

function openModal(title, bodyHtml, footerHtml) {
  document.getElementById('modalTitle').textContent = title
  document.getElementById('modalBody').innerHTML = bodyHtml
  document.getElementById('modalFooter').innerHTML = footerHtml || ''
  document.getElementById('modalOverlay').style.display = 'flex'
}

function closeModal() { document.getElementById('modalOverlay').style.display = 'none' }

function logout() { window.location.reload() }

// ============ 菜单切换 ============
document.querySelectorAll('.menu-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault()
    document.querySelectorAll('.menu-item').forEach(i => i.classList.remove('active'))
    item.classList.add('active')
    currentPage = item.dataset.page
    pagination.page = 1
    loadPage(currentPage)
  })
})

// ============ 页面加载 ============
async function loadPage(page) {
  const content = document.getElementById('content')
  content.innerHTML = '<div class="loading">加载中...</div>'
  try {
    switch (page) {
      case 'dashboard': await renderDashboard(content); break
      case 'users': await renderUsers(content); break
      case 'stations': await renderStations(content); break
      case 'orders': await renderOrders(content); break
      case 'reservations': await renderReservations(content); break
      case 'vouchers': await renderVouchers(content); break
      case 'collections': await renderCollections(content); break
    }
  } catch (err) {
    content.innerHTML = `<div class="empty">加载失败: ${err.message}</div>`
  }
}

// ============ 仪表盘 ============
async function renderDashboard(el) {
  const d = await API.getDashboard()
  el.innerHTML = `
    <h2 style="margin-bottom:20px">📊 数据概览</h2>
    <div class="stats">
      <div class="stat-card"><div class="label">注册用户</div><div class="value">${d.userCount}</div></div>
      <div class="stat-card"><div class="label">充电站数量</div><div class="value">${d.stationCount}</div></div>
      <div class="stat-card"><div class="label">总订单数</div><div class="value">${d.orderCount}</div></div>
      <div class="stat-card"><div class="label">已完成订单</div><div class="value">${d.completedOrderCount}</div></div>
      <div class="stat-card"><div class="label">总充电量</div><div class="value">${d.totalCapacity}<span class="unit">kWh</span></div></div>
      <div class="stat-card"><div class="label">总收入</div><div class="value">¥${d.totalAmount.toFixed(2)}</div></div>
    </div>
  `
}

// ============ 用户管理 ============
async function renderUsers(el) {
  const keyword = el._keyword || ''
  const data = await API.getUsers(pagination.page, pagination.size, keyword)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">👥 用户管理</h2>
    <div class="toolbar">
      <div class="search-box">
        <input id="userSearch" placeholder="搜索账号..." value="${keyword}" onkeydown="if(event.key==='Enter'){document.getElementById('content')._keyword=this.value;pagination.page=1;loadPage('users')}">
        <button class="btn btn-primary" onclick="document.getElementById('content')._keyword=document.getElementById('userSearch').value;pagination.page=1;loadPage('users')">搜索</button>
      </div>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>账号</th><th>用户名</th><th>注册时间</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(u => `<tr>
        <td>${u.account}</td><td>${u.userName||'-'}</td><td>${formatTime(u.createdAt)}</td>
        <td>${u.delFlag===0?'<span class="badge badge-success">正常</span>':'<span class="badge badge-danger">已删除</span>'}</td>
        <td><div class="actions"><button class="btn btn-sm btn-primary" onclick="editUser('${u.id}','${u.userName||''}')">编辑</button></div></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

function editUser(id, name) {
  openModal('编辑用户', `
    <div class="form-group"><label>用户名</label><input id="editUserName" value="${name}"></div>
    <div class="form-group"><label>重置密码（留空不修改）</label><input id="editUserPwd" type="password" placeholder="新密码"></div>
  `, `<button class="btn btn-primary" onclick="saveUser('${id}')">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveUser(id) {
  const data = {}
  const name = document.getElementById('editUserName').value
  const pwd = document.getElementById('editUserPwd').value
  if (name) data.userName = name
  if (pwd) data.password = pwd
  await API.updateUser(id, data)
  toast('保存成功')
  closeModal()
  loadPage('users')
}

// ============ 充电站管理 ============
async function renderStations(el) {
  const keyword = el._keyword || ''
  const data = await API.getStations(pagination.page, pagination.size, keyword)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">🔋 充电站管理</h2>
    <div class="toolbar">
      <div class="search-box">
        <input id="stationSearch" placeholder="搜索站点名..." value="${keyword}" onkeydown="if(event.key==='Enter'){document.getElementById('content')._keyword=this.value;pagination.page=1;loadPage('stations')}">
        <button class="btn btn-primary" onclick="document.getElementById('content')._keyword=document.getElementById('stationSearch').value;pagination.page=1;loadPage('stations')">搜索</button>
      </div>
      <button class="btn btn-add" onclick="addStation()">+ 新增充电站</button>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>站点名称</th><th>类型</th><th>电费(元/度)</th><th>功率(kW)</th><th>桩口数</th><th>服务商</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(s => `<tr>
        <td>${s.stationName}</td><td>${s.chargeType===1?'快充':'慢充'}</td><td>${s.chargeFee}</td><td>${s.chargePower}</td><td>${s.portCount}</td><td>${s.serviceProvider||'-'}</td>
        <td><div class="actions">
          <button class="btn btn-sm btn-primary" onclick="editStation('${s.id}')">编辑</button>
          <button class="btn btn-sm btn-success" onclick="viewPorts('${s.id}','${s.stationName}')">桩口</button>
          <button class="btn btn-sm btn-danger" onclick="deleteStationConfirm('${s.id}')">删除</button>
        </div></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

function addStation() {
  openModal('新增充电站', `
    <div class="form-group"><label>站点名称</label><input id="sName"></div>
    <div class="form-group"><label>类型</label><select id="sType"><option value="0">普通站</option><option value="1">快充站</option></select></div>
    <div class="form-group"><label>充电类型</label><select id="sChargeType"><option value="0">慢充</option><option value="1">快充</option></select></div>
    <div class="form-group"><label>电费(元/度)</label><input id="sFee" type="number" step="0.01" value="1.00"></div>
    <div class="form-group"><label>功率(kW)</label><input id="sPower" type="number" step="0.01" value="120"></div>
    <div class="form-group"><label>桩口数</label><input id="sPorts" type="number" value="4"></div>
    <div class="form-group"><label>纬度</label><input id="sLat" type="number" step="0.0001" value="45.75"></div>
    <div class="form-group"><label>经度</label><input id="sLng" type="number" step="0.0001" value="126.65"></div>
    <div class="form-group"><label>服务商</label><input id="sProvider" value="国网充电"></div>
    <div class="form-group"><label>营业时间</label><input id="sOpenTime" value="00:00-24:00"></div>
  `, `<button class="btn btn-primary" onclick="saveNewStation()">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewStation() {
  await API.createStation({
    stationName: document.getElementById('sName').value,
    stationType: Number(document.getElementById('sType').value),
    chargeType: Number(document.getElementById('sChargeType').value),
    chargeFee: document.getElementById('sFee').value,
    chargePower: document.getElementById('sPower').value,
    portCount: Number(document.getElementById('sPorts').value),
    latitude: document.getElementById('sLat').value,
    longitude: document.getElementById('sLng').value,
    serviceProvider: document.getElementById('sProvider').value,
    openTime: document.getElementById('sOpenTime').value,
  })
  toast('创建成功')
  closeModal()
  loadPage('stations')
}

async function editStation(id) {
  const data = await API.getStations(1, 1000, '')
  const s = data.list.find(x => x.id === id)
  if (!s) return
  openModal('编辑充电站', `
    <div class="form-group"><label>站点名称</label><input id="sName" value="${s.stationName}"></div>
    <div class="form-group"><label>电费(元/度)</label><input id="sFee" type="number" step="0.01" value="${s.chargeFee}"></div>
    <div class="form-group"><label>功率(kW)</label><input id="sPower" type="number" step="0.01" value="${s.chargePower}"></div>
    <div class="form-group"><label>服务商</label><input id="sProvider" value="${s.serviceProvider||''}"></div>
    <div class="form-group"><label>营业时间</label><input id="sOpenTime" value="${s.openTime||''}"></div>
  `, `<button class="btn btn-primary" onclick="saveEditStation('${id}')">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveEditStation(id) {
  await API.updateStation(id, {
    stationName: document.getElementById('sName').value,
    chargeFee: document.getElementById('sFee').value,
    chargePower: document.getElementById('sPower').value,
    serviceProvider: document.getElementById('sProvider').value,
    openTime: document.getElementById('sOpenTime').value,
  })
  toast('保存成功')
  closeModal()
  loadPage('stations')
}

async function deleteStationConfirm(id) {
  if (!confirm('确定删除此充电站？')) return
  await API.deleteStation(id)
  toast('删除成功')
  loadPage('stations')
}

async function viewPorts(stationId, stationName) {
  const ports = await API.getPorts(stationId)
  openModal(`${stationName} - 桩口管理`, `
    <div style="margin-bottom:12px"><button class="btn btn-add btn-sm" onclick="addPort('${stationId}')">+ 新增桩口</button></div>
    <div class="table-wrap"><table>
      <thead><tr><th>桩口名称</th><th>电费</th><th>功率</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${ports.map(p => `<tr>
        <td>${p.portName}</td><td>${p.chargeFee}元/度</td><td>${p.chargePower}kW</td>
        <td>${statusBadge(p.portStatus, PORT_STATUS)}</td>
        <td><div class="actions"><button class="btn btn-sm btn-danger" onclick="deletePortConfirm('${p.id}','${stationId}','${stationName}')">删除</button></div></td>
      </tr>`).join('') || '<tr><td colspan="5" class="empty">暂无桩口</td></tr>'}</tbody>
    </table></div>
  `)
}

async function addPort(stationId) {
  openModal('新增桩口', `
    <div class="form-group"><label>桩口名称</label><input id="pName" value="1号桩"></div>
    <div class="form-group"><label>电费(元/度)</label><input id="pFee" type="number" step="0.01" value="1.20"></div>
    <div class="form-group"><label>功率(kW)</label><input id="pPower" type="number" step="0.01" value="120"></div>
  `, `<button class="btn btn-primary" onclick="saveNewPort('${stationId}')">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewPort(stationId) {
  await API.createPort({ stationId, portName: document.getElementById('pName').value, chargeFee: document.getElementById('pFee').value, chargePower: document.getElementById('pPower').value })
  toast('创建成功')
  viewPorts(stationId, '')
}

async function deletePortConfirm(id, stationId, stationName) {
  if (!confirm('确定删除此桩口？')) return
  await API.deletePort(id)
  toast('删除成功')
  viewPorts(stationId, stationName)
}

// ============ 订单管理 ============
async function renderOrders(el) {
  const status = el._status || ''
  const data = await API.getOrders(pagination.page, pagination.size, status)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">📋 订单管理</h2>
    <div class="toolbar">
      <div class="filter-bar">
        <select onchange="document.getElementById('content')._status=this.value;pagination.page=1;loadPage('orders')">
          <option value="" ${status===''?'selected':''}>全部</option>
          <option value="0" ${status==='0'?'selected':''}>进行中</option>
          <option value="1" ${status==='1'?'selected':''}>待支付</option>
          <option value="2" ${status==='2'?'selected':''}>已完成</option>
        </select>
      </div>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>订单号</th><th>充电站</th><th>桩口</th><th>电量(kWh)</th><th>金额(元)</th><th>状态</th><th>创建时间</th></tr></thead>
      <tbody>${data.list.map(o => `<tr>
        <td style="font-size:12px">${o.orderNo||o.id.substring(0,8)}</td><td>${o.stationName}</td><td>${o.portName}</td>
        <td>${Number(o.chargeCapacity||0).toFixed(2)}</td><td>${Number(o.orderAmount||0).toFixed(2)}</td>
        <td>${statusBadge(o.orderStatus, ORDER_STATUS)}</td><td>${formatTime(o.createdAt)}</td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

// ============ 预约管理 ============
async function renderReservations(el) {
  const data = await API.getReservations(pagination.page, pagination.size)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">📅 预约管理</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>充电站</th><th>桩口</th><th>开始时间</th><th>结束时间</th><th>SOC目标</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(r => `<tr>
        <td>${r.stationName}</td><td>${r.portName}</td><td>${formatTime(r.startTime)}</td><td>${formatTime(r.endTime)}</td>
        <td>${r.socValue||0}%</td><td>${statusBadge(r.status, RES_STATUS)}</td>
        <td>${r.status===0?`<button class="btn btn-sm btn-danger" onclick="cancelRes('${r.id}')">取消</button>`:''}</td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

async function cancelRes(id) {
  if (!confirm('确定取消此预约？')) return
  await API.cancelReservation(id)
  toast('已取消')
  loadPage('reservations')
}

// ============ 代金券管理 ============
async function renderVouchers(el) {
  const data = await API.getVouchers(pagination.page, pagination.size)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">🎫 代金券管理</h2>
    <div class="toolbar"><div></div><button class="btn btn-add" onclick="addVoucher()">+ 新增代金券</button></div>
    <div class="table-wrap"><table>
      <thead><tr><th>类型</th><th>面值(元)</th><th>总量</th><th>已领</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(v => `<tr>
        <td>${v.voucherType}</td><td>${Number(v.voucherValue).toFixed(2)}</td><td>${v.totalNum}</td><td>${v.usedNum}</td>
        <td><div class="actions">
          <button class="btn btn-sm btn-danger" onclick="deleteVoucherConfirm('${v.id}')">删除</button>
        </div></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

function addVoucher() {
  openModal('新增代金券', `
    <div class="form-group"><label>类型名称</label><input id="vType" value="新用户专享"></div>
    <div class="form-group"><label>面值(元)</label><input id="vValue" type="number" step="0.01" value="10.00"></div>
    <div class="form-group"><label>发放总量</label><input id="vTotal" type="number" value="100"></div>
  `, `<button class="btn btn-primary" onclick="saveNewVoucher()">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewVoucher() {
  await API.createVoucher({ voucherType: document.getElementById('vType').value, voucherValue: document.getElementById('vValue').value, totalNum: Number(document.getElementById('vTotal').value) })
  toast('创建成功')
  closeModal()
  loadPage('vouchers')
}

async function deleteVoucherConfirm(id) {
  if (!confirm('确定删除此代金券？')) return
  await API.deleteVoucher(id)
  toast('删除成功')
  loadPage('vouchers')
}

// ============ 收藏管理 ============
async function renderCollections(el) {
  const data = await API.getCollections(pagination.page, pagination.size)
  el.innerHTML = `
    <h2 style="margin-bottom:16px">⭐ 收藏管理</h2>
    <div class="table-wrap"><table>
      <thead><tr><th>用户</th><th>充电站</th><th>收藏时间</th></tr></thead>
      <tbody>${data.list.map(c => `<tr>
        <td>${c.userName||c.userId.substring(0,8)}</td><td>${c.stationName||c.stationId.substring(0,8)}</td><td>${formatTime(c.createdAt)}</td>
      </tr>`).join('') || '<tr><td colspan="3" class="empty">暂无收藏记录</td></tr>'}</tbody>
    </table></div>
    ${paginate(data.total)}
  `
}

// ============ 初始化 ============
loadPage('dashboard')
