import 'dotenv/config'
import { sql } from 'drizzle-orm'
import { db } from './config/database'
import { pool } from './config/database'
import {
  users, files, stations, ports, vouchers,
} from './models/schema'
import { hashPassword } from './utils/password'

async function seed() {
  console.log('开始填充种子数据...')

  // ============ 0. 清空旧数据（按外键依赖顺序） ============
  await db.execute(sql`TRUNCATE TABLE user_vouchers, vouchers, collections, reservations, orders, station_access_records, port_bindings, ports, stations, files, users RESTART IDENTITY CASCADE`)
  console.log('旧数据已清空')

  // ============ 1. 创建测试用户 ============
  const passwordHash = await hashPassword('123456')

  const [user1] = await db.insert(users).values({
    account: 'admin',
    passwordHash,
    userName: '管理员',
  }).returning({ id: users.id })

  const [user2] = await db.insert(users).values({
    account: 'test',
    passwordHash,
    userName: '测试用户',
  }).returning({ id: users.id })

  console.log(`创建用户: admin, test (密码: 123456)`)

  // ============ 2. 创建充电站 ============
  const stationData = [
    { stationName: '哈尔滨市道里区中央大街充电站', stationType: 1, latitude: '45.7680', longitude: '126.6170', chargeType: 1, portCount: 8, chargeFee: '1.20', chargePower: '120.00', usedCount: 156, serviceProvider: '国网充电', openTime: '00:00-24:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝' },
    { stationName: '哈尔滨市南岗区哈工大充电站', stationType: 1, latitude: '45.7490', longitude: '126.6780', chargeType: 1, portCount: 6, chargeFee: '1.50', chargePower: '180.00', usedCount: 89, serviceProvider: '特来电', openTime: '06:00-23:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝' },
    { stationName: '哈尔滨市道外区慢充站', stationType: 0, latitude: '45.7920', longitude: '126.6480', chargeType: 0, portCount: 12, chargeFee: '0.80', chargePower: '7.00', usedCount: 234, serviceProvider: '星星充电', openTime: '00:00-24:00', invoiceType: '纸质发票', paymentMethod: '微信支付' },
    { stationName: '哈尔滨市松北区超级充电站', stationType: 1, latitude: '45.8020', longitude: '126.5480', chargeType: 1, portCount: 10, chargeFee: '1.80', chargePower: '250.00', usedCount: 312, serviceProvider: '特斯拉超充', openTime: '00:00-24:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝,银联' },
    { stationName: '哈尔滨市香坊区公共充电站', stationType: 0, latitude: '45.7230', longitude: '126.6820', chargeType: 0, portCount: 4, chargeFee: '0.60', chargePower: '7.00', usedCount: 67, serviceProvider: '国家电网', openTime: '08:00-20:00', invoiceType: '电子发票', paymentMethod: '支付宝' },
    { stationName: '哈尔滨市道里区群力充电站', stationType: 1, latitude: '45.7450', longitude: '126.5950', chargeType: 1, portCount: 6, chargeFee: '1.30', chargePower: '120.00', usedCount: 198, serviceProvider: '小桔充电', openTime: '00:00-24:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝' },
    { stationName: '哈尔滨市呼兰区快充站', stationType: 1, latitude: '45.8880', longitude: '126.5950', chargeType: 1, portCount: 4, chargeFee: '1.10', chargePower: '60.00', usedCount: 45, serviceProvider: '万马爱充', openTime: '06:00-22:00', invoiceType: '电子发票', paymentMethod: '微信支付' },
    { stationName: '哈尔滨市阿城区充电站', stationType: 0, latitude: '45.5480', longitude: '126.9680', chargeType: 0, portCount: 8, chargeFee: '0.70', chargePower: '7.00', usedCount: 123, serviceProvider: '星星充电', openTime: '00:00-24:00', invoiceType: '纸质发票', paymentMethod: '微信支付,支付宝' },
    { stationName: '哈尔滨市南岗区会展中心充电站', stationType: 1, latitude: '45.7370', longitude: '126.6530', chargeType: 1, portCount: 10, chargeFee: '1.40', chargePower: '150.00', usedCount: 267, serviceProvider: '特来电', openTime: '00:00-24:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝,银联' },
    { stationName: '哈尔滨市松北区冰雪大世界充电站', stationType: 0, latitude: '45.7800', longitude: '126.5200', chargeType: 0, portCount: 6, chargeFee: '1.00', chargePower: '7.00', usedCount: 89, serviceProvider: '国家电网', openTime: '07:00-21:00', invoiceType: '电子发票', paymentMethod: '支付宝' },
    { stationName: '哈尔滨市平房区新疆大街充电站', stationType: 1, latitude: '45.6050', longitude: '126.6320', chargeType: 1, portCount: 6, chargeFee: '1.20', chargePower: '120.00', usedCount: 56, serviceProvider: '国网充电', openTime: '00:00-24:00', invoiceType: '电子发票', paymentMethod: '微信支付,支付宝' },
  ]

  const insertedStations = await db.insert(stations).values(stationData).returning({
    id: stations.id, stationName: stations.stationName, portCount: stations.portCount,
  })
  console.log(`创建 ${insertedStations.length} 个充电站`)

  // ============ 3. 创建充电桩 ============
  const portData: Array<{
    stationId: string; portName: string; chargeFee: string; chargePower: string;
    serviceProvider: string; openTime: string; invoiceType: string; paymentMethod: string;
    portStatus: number;
  }> = []

  for (const station of insertedStations) {
    for (let i = 1; i <= Math.min(station.portCount, 3); i++) {
      const stationInfo = stationData.find(s => s.stationName === station.stationName)!
      portData.push({
        stationId: station.id,
        portName: `${i}号桩`,
        chargeFee: stationInfo.chargeFee,
        chargePower: stationInfo.chargePower,
        serviceProvider: stationInfo.serviceProvider,
        openTime: stationInfo.openTime,
        invoiceType: stationInfo.invoiceType,
        paymentMethod: stationInfo.paymentMethod,
        portStatus: 0,
      })
    }
  }

  await db.insert(ports).values(portData)
  console.log(`创建 ${portData.length} 个充电桩`)

  // ============ 4. 创建代金券 ============
  const voucherData = [
    { voucherType: '新用户专享', voucherValue: '10.00', totalNum: 100, usedNum: 23 },
    { voucherType: '满50减5', voucherValue: '5.00', totalNum: 200, usedNum: 89 },
    { voucherType: '快充优惠', voucherValue: '8.00', totalNum: 50, usedNum: 12 },
    { voucherType: '周末特惠', voucherValue: '15.00', totalNum: 30, usedNum: 5 },
    { voucherType: '节假日优惠', voucherValue: '20.00', totalNum: 20, usedNum: 3 },
  ]

  await db.insert(vouchers).values(voucherData)
  console.log(`创建 ${voucherData.length} 个代金券`)

  console.log('种子数据填充完成!')
  await pool.end()
}

seed().catch((err) => {
  console.error('种子数据填充失败:', err)
  process.exit(1)
})
