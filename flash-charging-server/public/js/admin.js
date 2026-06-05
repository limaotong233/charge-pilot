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
  const item = map[status] || { text: '-', cls: 'badge-info' }
  return `<span class="badge ${item.cls}">${item.text}</span>`
}

const ORDER_STATUS = { 0: { text: '进行中', cls: 'badge-info' }, 1: { text: '待支付', cls: 'badge-warning' }, 2: { text: '已完成', cls: 'badge-success' } }
const PORT_STATUS = { 0: { text: '空闲', cls: 'badge-success' }, 1: { text: '已预约', cls: 'badge-warning' }, 2: { text: '充电中', cls: 'badge-danger' } }
const RES_STATUS = { 0: { text: '进行中', cls: 'badge-info' }, 1: { text: '已完成', cls: 'badge-success' }, 2: { text: '已取消', cls: 'badge-danger' } }

function paginate(total) {
  const pages = Math.ceil(total / pagination.size) || 1
  return `<div class="pagination">
    <button ${pagination.page<=1?'disabled':''} onclick="goPage(${pagination.page-1})">上一页</button>
    <span class="page-info">${pagination.page} / ${pages}，共 ${total} 条</span>
    <button ${pagination.page>=pages?'disabled':''} onclick="goPage(${pagination.page+1})">下一页</button>
  </div>`
}

function goPage(p) { pagination.page = p; loadPage(currentPage) }
function openModal(title, body, footer) {
  document.getElementById('modalTitle').textContent = title
  document.getElementById('modalBody').innerHTML = body
  document.getElementById('modalFooter').innerHTML = footer || ''
  document.getElementById('modalOverlay').style.display = 'flex'
}
function closeModal() { document.getElementById('modalOverlay').style.display = 'none' }
function logout() { window.location.reload() }

// ============ 菜单 ============
document.querySelectorAll('.menu-item').forEach(item => {
  item.addEventListener('click', e => {
    e.preventDefault()
    document.querySelectorAll('.menu-item').forEach(i => i.classList.remove('active'))
    item.classList.add('active')
    currentPage = item.dataset.page
    pagination.page = 1
    loadPage(currentPage)
  })
})

// ============ 图表工具函数 ============
function barChart(data, maxVal) {
  const max = maxVal || Math.max(...data.map(d => d.value), 1)
  return `<div class="bar-chart">${data.map(d => {
    const h = Math.max(4, (d.value / max) * 140)
    return `<div class="bar-group">
      <div class="bar-value">${d.value}</div>
      <div class="bar" style="height:${h}px;background:${d.color || '#1a1a1a'}"></div>
      <div class="bar-label">${d.label}</div>
    </div>`
  }).join('')}</div>`
}

function donutChart(segments, centerNum, centerTxt) {
  const r = 50, c = 2 * Math.PI * r
  let offset = 0
  const circles = segments.map(s => {
    const len = (s.pct / 100) * c
    const dash = `${len} ${c - len}`
    const el = `<circle cx="60" cy="60" r="${r}" stroke="${s.color}" stroke-dasharray="${dash}" stroke-dashoffset="${-offset}"/>`
    offset += len
    return el
  }).join('')
  const legend = segments.map(s => `<div class="legend-item"><span class="legend-dot" style="background:${s.color}"></span>${s.label}: ${s.value}</div>`).join('')
  return `<div class="donut-chart">
    <div class="donut-wrap">
      <svg viewBox="0 0 120 120"><circle cx="60" cy="60" r="${r}" stroke="#f0f0f0" stroke-width="10"/>${circles}</svg>
      <div class="donut-center"><div class="num">${centerNum}</div><div class="txt">${centerTxt}</div></div>
    </div>
    <div class="donut-legend">${legend}</div>
  </div>`
}

function miniSparkline(values, color) {
  if (!values.length) return ''
  const w = 200, h = 36, max = Math.max(...values, 1), min = Math.min(...values, 0)
  const range = max - min || 1
  const points = values.map((v, i) => `${(i / (values.length - 1)) * w},${h - ((v - min) / range) * (h - 4) - 2}`).join(' ')
  const area = `0,${h} ${points} ${w},${h}`
  return `<svg viewBox="0 0 ${w} ${h}" style="width:100%;height:${h}px">
    <polygon points="${area}" fill="${color}10"/>
    <polyline points="${points}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>`
}

// ============ 页面加载 ============
async function loadPage(page) {
  const el = document.getElementById('content')
  el.innerHTML = '<div class="loading">加载中...</div>'
  try {
    switch (page) {
      case 'dashboard': await renderDashboard(el); break
      case 'users': await renderUsers(el); break
      case 'stations': await renderStations(el); break
      case 'orders': await renderOrders(el); break
      case 'reservations': await renderReservations(el); break
      case 'vouchers': await renderVouchers(el); break
      case 'collections': await renderCollections(el); break
    }
  } catch (err) { el.innerHTML = `<div class="empty">加载失败: ${err.message}</div>` }
}

// ============ 仪表盘 ============
async function renderDashboard(el) {
  const d = await API.getDashboard()
  const avgAmount = d.completedOrderCount > 0 ? (d.totalAmount / d.completedOrderCount).toFixed(2) : '0.00'
  const avgCapacity = d.completedOrderCount > 0 ? (d.totalCapacity / d.completedOrderCount).toFixed(1) : '0.0'

  // 模拟月度趋势数据（可替换为真实 API 数据）
  const months = ['1月','2月','3月','4月','5月','6月']
  const trendData = [12, 28, 45, 38, 56, d.totalCapacity || 0]

  // 订单状态分布
  const orderData = [
    { label: '已完成', value: d.completedOrderCount, pct: d.orderCount ? (d.completedOrderCount / d.orderCount * 100) : 0, color: '#4f6ef7' },
    { label: '进行中', value: Math.max(0, d.orderCount - d.completedOrderCount), pct: d.orderCount ? ((d.orderCount - d.completedOrderCount) / d.orderCount * 100) : 0, color: '#e5e7eb' },
  ]

  // 柱状图渐变色
  const barColors = ['#c7d2fe', '#a5b4fc', '#818cf8', '#6366f1', '#4f6ef7', '#4338ca']

  el.innerHTML = `
    <div class="page-title">数据概览</div>
    <div class="stats">
      <div class="stat-card"><div class="label">注册用户</div><div class="value">${d.userCount}</div></div>
      <div class="stat-card"><div class="label">充电站</div><div class="value">${d.stationCount}</div></div>
      <div class="stat-card"><div class="label">完成订单</div><div class="value">${d.completedOrderCount}</div><div class="sub">共 ${d.totalCapacity} kWh</div></div>
      <div class="stat-card"><div class="label">总收入</div><div class="value">${d.totalAmount.toFixed(2)}<span style="font-size:14px;font-weight:400;color:#9ca3af;margin-left:2px">元</span></div></div>
    </div>

    <div class="chart-row">
      <div class="chart-card">
        <div class="chart-title">充电量趋势（近6月）</div>
        ${barChart(months.map((m, i) => ({ label: m, value: trendData[i], color: barColors[i] })))}
        <div class="mini-chart">${miniSparkline(trendData, '#4f6ef7')}</div>
      </div>
      <div class="chart-card">
        <div class="chart-title">订单状态</div>
        ${donutChart(orderData, d.orderCount, '总订单')}
      </div>
    </div>

    <div class="chart-row">
      <div class="chart-card">
        <div class="chart-title">关键指标</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;padding:8px 0">
          <div><div style="font-size:12px;color:#999;margin-bottom:4px">平均充电量</div><div style="font-size:20px;font-weight:600">${avgCapacity} kWh</div></div>
          <div><div style="font-size:12px;color:#999;margin-bottom:4px">平均订单金额</div><div style="font-size:20px;font-weight:600">${avgAmount} 元</div></div>
          <div><div style="font-size:12px;color:#999;margin-bottom:4px">碳减排量</div><div style="font-size:20px;font-weight:600">${(d.totalCapacity * 0.785).toFixed(1)} kg</div></div>
          <div><div style="font-size:12px;color:#999;margin-bottom:4px">站点利用率</div><div style="font-size:20px;font-weight:600">${d.stationCount > 0 ? Math.round(d.completedOrderCount / d.stationCount * 10) / 10 : 0} 次/站</div></div>
        </div>
      </div>
      <div class="chart-card">
        <div class="chart-title">站点规模</div>
        <div class="donut-chart">
          <div class="donut-wrap">
            <svg viewBox="0 0 120 120">
              <circle cx="60" cy="60" r="50" stroke="#f3f4f6" stroke-width="10" fill="none"/>
              <circle cx="60" cy="60" r="50" stroke="#22c55e" stroke-width="10" fill="none"
                stroke-dasharray="${Math.min(d.stationCount * 10, 314)} ${314 - Math.min(d.stationCount * 10, 314)}"
                transform="rotate(-90 60 60)"/>
            </svg>
            <div class="donut-center"><div class="num">${d.stationCount}</div><div class="txt">充电站</div></div>
          </div>
        </div>
      </div>
    </div>
  `
}

// ============ 用户管理 ============
async function renderUsers(el) {
  const keyword = el._keyword || ''
  const data = await API.getUsers(pagination.page, pagination.size, keyword)
  el.innerHTML = `
    <div class="page-title">用户管理</div>
    <div class="toolbar">
      <div class="search-box">
        <input id="userSearch" placeholder="搜索账号..." value="${keyword}" onkeydown="if(event.key==='Enter'){document.getElementById('content')._keyword=this.value;p=1;loadPage('users')}">
        <button class="btn" onclick="document.getElementById('content')._keyword=document.getElementById('userSearch').value;p=1;loadPage('users')">搜索</button>
      </div>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>账号</th><th>用户名</th><th>注册时间</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(u => `<tr>
        <td>${u.account}</td><td>${u.userName||'-'}</td><td>${formatTime(u.createdAt)}</td>
        <td>${u.delFlag===0?'<span class="badge badge-success">正常</span>':'<span class="badge badge-danger">已删除</span>'}</td>
        <td><div class="actions"><button class="btn btn-sm" onclick="editUser('${u.id}','${(u.userName||'').replace(/'/g,"\\'")}')">编辑</button></div></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}`
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
    <div class="page-title">充电站管理</div>
    <div class="toolbar">
      <div class="search-box">
        <input id="stationSearch" placeholder="搜索站点名..." value="${keyword}" onkeydown="if(event.key==='Enter'){document.getElementById('content')._keyword=this.value;p=1;loadPage('stations')}">
        <button class="btn" onclick="document.getElementById('content')._keyword=document.getElementById('stationSearch').value;p=1;loadPage('stations')">搜索</button>
      </div>
      <button class="btn btn-add" onclick="addStation()">新增充电站</button>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>站点名称</th><th>类型</th><th>电费</th><th>功率</th><th>桩口</th><th>服务商</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(s => `<tr>
        <td>${s.stationName}</td><td>${s.chargeType===1?'快充':'慢充'}</td><td>${s.chargeFee}元/度</td><td>${s.chargePower}kW</td><td>${s.portCount}</td><td>${s.serviceProvider||'-'}</td>
        <td><div class="actions">
          <button class="btn btn-sm" onclick="editStation('${s.id}')">编辑</button>
          <button class="btn btn-sm" onclick="viewPorts('${s.id}','${s.stationName.replace(/'/g,"\\'")}')">桩口</button>
          <button class="btn btn-sm btn-danger" onclick="deleteStationConfirm('${s.id}')">删除</button>
        </div></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}`
}

function addStation() {
  openModal('新增充电站', `
    <div class="form-group"><label>站点名称</label><input id="sName"></div>
    <div class="form-group"><label>充电类型</label><select id="sChargeType"><option value="0">慢充</option><option value="1">快充</option></select></div>
    <div class="form-group"><label>电费（元/度）</label><input id="sFee" type="number" step="0.01" value="1.00"></div>
    <div class="form-group"><label>功率（kW）</label><input id="sPower" type="number" step="0.01" value="120"></div>
    <div class="form-group"><label>桩口数</label><input id="sPorts" type="number" value="4"></div>
    <div class="form-group"><label>纬度</label><input id="sLat" type="number" step="0.0001" value="45.75"></div>
    <div class="form-group"><label>经度</label><input id="sLng" type="number" step="0.0001" value="126.65"></div>
    <div class="form-group"><label>服务商</label><input id="sProvider" value="国网充电"></div>
    <div class="form-group"><label>营业时间</label><input id="sOpenTime" value="00:00-24:00"></div>
  `, `<button class="btn btn-primary" onclick="saveNewStation()">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewStation() {
  await API.createStation({
    stationName: document.getElementById('sName').value, stationType: 0,
    chargeType: Number(document.getElementById('sChargeType').value),
    chargeFee: document.getElementById('sFee').value, chargePower: document.getElementById('sPower').value,
    portCount: Number(document.getElementById('sPorts').value),
    latitude: document.getElementById('sLat').value, longitude: document.getElementById('sLng').value,
    serviceProvider: document.getElementById('sProvider').value, openTime: document.getElementById('sOpenTime').value,
  })
  toast('创建成功'); closeModal(); loadPage('stations')
}

async function editStation(id) {
  const data = await API.getStations(1, 1000, '')
  const s = data.list.find(x => x.id === id)
  if (!s) return
  openModal('编辑充电站', `
    <div class="form-group"><label>站点名称</label><input id="sName" value="${s.stationName}"></div>
    <div class="form-group"><label>电费（元/度）</label><input id="sFee" type="number" step="0.01" value="${s.chargeFee}"></div>
    <div class="form-group"><label>功率（kW）</label><input id="sPower" type="number" step="0.01" value="${s.chargePower}"></div>
    <div class="form-group"><label>服务商</label><input id="sProvider" value="${s.serviceProvider||''}"></div>
    <div class="form-group"><label>营业时间</label><input id="sOpenTime" value="${s.openTime||''}"></div>
  `, `<button class="btn btn-primary" onclick="saveEditStation('${id}')">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveEditStation(id) {
  await API.updateStation(id, {
    stationName: document.getElementById('sName').value, chargeFee: document.getElementById('sFee').value,
    chargePower: document.getElementById('sPower').value, serviceProvider: document.getElementById('sProvider').value,
    openTime: document.getElementById('sOpenTime').value,
  })
  toast('保存成功'); closeModal(); loadPage('stations')
}

async function deleteStationConfirm(id) { if (!confirm('确定删除此充电站？')) return; await API.deleteStation(id); toast('已删除'); loadPage('stations') }

async function viewPorts(stationId, stationName) {
  const ports = await API.getPorts(stationId)
  openModal(stationName + ' - 桩口', `
    <div style="margin-bottom:12px"><button class="btn btn-add btn-sm" onclick="addPort('${stationId}')">新增桩口</button></div>
    <div class="table-wrap"><table>
      <thead><tr><th>名称</th><th>电费</th><th>功率</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${ports.map(p => `<tr>
        <td>${p.portName}</td><td>${p.chargeFee}元/度</td><td>${p.chargePower}kW</td>
        <td>${statusBadge(p.portStatus, PORT_STATUS)}</td>
        <td><button class="btn btn-sm btn-danger" onclick="deletePortConfirm('${p.id}','${stationId}','${stationName.replace(/'/g,"\\'")}')">删除</button></td>
      </tr>`).join('') || '<tr><td colspan="5" class="empty">暂无桩口</td></tr>'}</tbody>
    </table></div>`)
}

async function addPort(stationId) {
  openModal('新增桩口', `
    <div class="form-group"><label>桩口名称</label><input id="pName" value="1号桩"></div>
    <div class="form-group"><label>电费（元/度）</label><input id="pFee" type="number" step="0.01" value="1.20"></div>
    <div class="form-group"><label>功率（kW）</label><input id="pPower" type="number" step="0.01" value="120"></div>
  `, `<button class="btn btn-primary" onclick="saveNewPort('${stationId}')">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewPort(stationId) {
  await API.createPort({ stationId, portName: document.getElementById('pName').value, chargeFee: document.getElementById('pFee').value, chargePower: document.getElementById('pPower').value })
  toast('创建成功'); closeModal(); viewPorts(stationId, '')
}

async function deletePortConfirm(id, sid, sname) { if (!confirm('确定删除？')) return; await API.deletePort(id); toast('已删除'); viewPorts(sid, sname) }

// ============ 订单 ============
async function renderOrders(el) {
  const status = el._status ?? ''
  const data = await API.getOrders(pagination.page, pagination.size, status)
  el.innerHTML = `
    <div class="page-title">订单管理</div>
    <div class="toolbar">
      <div class="filter-bar">
        <select onchange="document.getElementById('content')._status=this.value;p=1;loadPage('orders')">
          <option value="" ${status===''?'selected':''}>全部状态</option>
          <option value="0" ${status==='0'?'selected':''}>进行中</option>
          <option value="1" ${status==='1'?'selected':''}>待支付</option>
          <option value="2" ${status==='2'?'selected':''}>已完成</option>
        </select>
      </div>
    </div>
    <div class="table-wrap"><table>
      <thead><tr><th>订单号</th><th>充电站</th><th>桩口</th><th>电量</th><th>金额</th><th>状态</th><th>时间</th></tr></thead>
      <tbody>${data.list.map(o => `<tr>
        <td style="font-family:monospace;font-size:12px">${o.orderNo||o.id.substring(0,10)}</td>
        <td>${o.stationName}</td><td>${o.portName}</td>
        <td>${Number(o.chargeCapacity||0).toFixed(2)} kWh</td>
        <td>${Number(o.orderAmount||0).toFixed(2)} 元</td>
        <td>${statusBadge(o.orderStatus, ORDER_STATUS)}</td>
        <td>${formatTime(o.createdAt)}</td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}`
}

// ============ 预约 ============
async function renderReservations(el) {
  const data = await API.getReservations(pagination.page, pagination.size)
  el.innerHTML = `
    <div class="page-title">预约管理</div>
    <div class="table-wrap"><table>
      <thead><tr><th>充电站</th><th>桩口</th><th>开始</th><th>结束</th><th>SOC</th><th>状态</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(r => `<tr>
        <td>${r.stationName}</td><td>${r.portName}</td>
        <td>${formatTime(r.startTime)}</td><td>${formatTime(r.endTime)}</td>
        <td>${r.socValue||0}%</td>
        <td>${statusBadge(r.status, RES_STATUS)}</td>
        <td>${r.status===0?'<button class="btn btn-sm btn-danger" onclick="cancelRes(\''+r.id+'\')">取消</button>':''}</td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}`
}

async function cancelRes(id) { if (!confirm('确定取消？')) return; await API.cancelReservation(id); toast('已取消'); loadPage('reservations') }

// ============ 代金券 ============
async function renderVouchers(el) {
  const data = await API.getVouchers(pagination.page, pagination.size)
  el.innerHTML = `
    <div class="page-title">代金券管理</div>
    <div class="toolbar"><div></div><button class="btn btn-add" onclick="addVoucher()">新增代金券</button></div>
    <div class="table-wrap"><table>
      <thead><tr><th>类型</th><th>面值</th><th>总量</th><th>已领</th><th>操作</th></tr></thead>
      <tbody>${data.list.map(v => `<tr>
        <td>${v.voucherType}</td><td>${Number(v.voucherValue).toFixed(2)} 元</td><td>${v.totalNum}</td><td>${v.usedNum}</td>
        <td><button class="btn btn-sm btn-danger" onclick="deleteVoucherConfirm('${v.id}')">删除</button></td>
      </tr>`).join('')}</tbody>
    </table></div>
    ${paginate(data.total)}`
}

function addVoucher() {
  openModal('新增代金券', `
    <div class="form-group"><label>类型名称</label><input id="vType" value="新用户专享"></div>
    <div class="form-group"><label>面值（元）</label><input id="vValue" type="number" step="0.01" value="10.00"></div>
    <div class="form-group"><label>发放总量</label><input id="vTotal" type="number" value="100"></div>
  `, `<button class="btn btn-primary" onclick="saveNewVoucher()">保存</button><button class="btn" onclick="closeModal()">取消</button>`)
}

async function saveNewVoucher() {
  await API.createVoucher({ voucherType: document.getElementById('vType').value, voucherValue: document.getElementById('vValue').value, totalNum: Number(document.getElementById('vTotal').value) })
  toast('创建成功'); closeModal(); loadPage('vouchers')
}

async function deleteVoucherConfirm(id) { if (!confirm('确定删除？')) return; await API.deleteVoucher(id); toast('已删除'); loadPage('vouchers') }

// ============ 收藏 ============
async function renderCollections(el) {
  const data = await API.getCollections(pagination.page, pagination.size)
  el.innerHTML = `
    <div class="page-title">收藏管理</div>
    <div class="table-wrap"><table>
      <thead><tr><th>用户</th><th>充电站</th><th>时间</th></tr></thead>
      <tbody>${data.list.map(c => `<tr>
        <td>${c.userName||c.userId.substring(0,8)}</td>
        <td>${c.stationName||c.stationId.substring(0,8)}</td>
        <td>${formatTime(c.createdAt)}</td>
      </tr>`).join('') || '<tr><td colspan="3" class="empty">暂无数据</td></tr>'}</tbody>
    </table></div>
    ${paginate(data.total)}`
}

// 初始化
loadPage('dashboard')
