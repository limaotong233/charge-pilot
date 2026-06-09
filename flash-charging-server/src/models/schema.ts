import {
  pgTable, uuid, varchar, decimal, integer, smallint,
  timestamp, uniqueIndex, index, check
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

// ============ 用户表 ============
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  account: varchar('account', { length: 64 }).notNull().unique(),
  passwordHash: varchar('password_hash', { length: 255 }).notNull(),
  userName: varchar('user_name', { length: 128 }),
  // 外键: files(id) — 由于 users/files 存在循环引用，外键通过 SQL migration 添加
  avatarFileId: uuid('avatar_file_id'),
  role: varchar('role', { length: 20 }).notNull().default('user'), // user=普通用户, admin=管理员
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
  delFlag: smallint('del_flag').notNull().default(0), // 0=正常, 1=已删除
}, (t) => [
  index('idx_users_account').on(t.account).where(sql`${t.delFlag} = 0`),
])

// ============ 文件表 ============
export const files = pgTable('files', {
  id: uuid('id').primaryKey().defaultRandom(),
  fileName: varchar('file_name', { length: 255 }).notNull(),
  filePath: varchar('file_path', { length: 512 }).notNull(),
  fileType: varchar('file_type', { length: 64 }),
  fileSize: integer('file_size'),
  fileCode: varchar('file_code', { length: 128 }).notNull().unique(),
  // 外键: users(id) — 由于 users/files 存在循环引用，外键通过 SQL migration 添加
  uploaderId: uuid('uploader_id'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  index('idx_files_code').on(t.fileCode),
])

// ============ 充电站表 ============
export const stations = pgTable('stations', {
  id: uuid('id').primaryKey().defaultRandom(),
  stationName: varchar('station_name', { length: 256 }).notNull(),
  stationType: smallint('station_type').notNull().default(0),
  latitude: decimal('latitude', { precision: 10, scale: 7 }).notNull(),
  longitude: decimal('longitude', { precision: 10, scale: 7 }).notNull(),
  chargeType: smallint('charge_type').notNull().default(0), // 0=慢充, 1=快充
  portCount: integer('port_count').notNull().default(0),
  chargeFee: decimal('charge_fee', { precision: 8, scale: 2 }).notNull().default('0'),
  chargePower: decimal('charge_power', { precision: 8, scale: 2 }).notNull().default('0'),
  usedCount: integer('used_count').notNull().default(0),
  serviceProvider: varchar('service_provider', { length: 256 }),
  openTime: varchar('open_time', { length: 64 }),
  invoiceType: varchar('invoice_type', { length: 64 }),
  paymentMethod: varchar('payment_method', { length: 128 }),
  fileCode: varchar('file_code', { length: 128 }),
  delFlag: smallint('del_flag').notNull().default(1), // 1=有效, 0=已删除（兼容客户端）
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
}, (t) => [
  index('idx_stations_name').on(t.stationName).where(sql`${t.delFlag} = 1`),
  index('idx_stations_type').on(t.chargeType).where(sql`${t.delFlag} = 1`),
  index('idx_stations_geo').on(t.latitude, t.longitude).where(sql`${t.delFlag} = 1`),
])

// ============ 充电桩口表 ============
export const ports = pgTable('ports', {
  id: uuid('id').primaryKey().defaultRandom(),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  portName: varchar('port_name', { length: 128 }).notNull(),
  chargeFee: decimal('charge_fee', { precision: 8, scale: 2 }).notNull().default('0'),
  chargePower: decimal('charge_power', { precision: 8, scale: 2 }).notNull().default('0'),
  serviceProvider: varchar('service_provider', { length: 256 }),
  openTime: varchar('open_time', { length: 64 }),
  invoiceType: varchar('invoice_type', { length: 64 }),
  paymentMethod: varchar('payment_method', { length: 128 }),
  portStatus: smallint('port_status').notNull().default(0), // 0=空闲, 1=已预约, 2=充电中
  reserveTime: timestamp('reserve_time'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
}, (t) => [
  index('idx_ports_station').on(t.stationId),
  index('idx_ports_status').on(t.portStatus),
])

// ============ 订单表 ============
export const orders = pgTable('orders', {
  id: uuid('id').primaryKey().defaultRandom(),
  orderNo: varchar('order_no', { length: 64 }).notNull().unique(),
  userId: uuid('user_id').notNull().references(() => users.id),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  stationName: varchar('station_name', { length: 256 }).notNull(),
  portId: uuid('port_id').notNull().references(() => ports.id),
  portName: varchar('port_name', { length: 128 }).notNull(),
  isReserve: smallint('is_reserve').notNull().default(0), // 0=直接充电, 1=预约充电
  orderStatus: smallint('order_status').notNull().default(0), // 0=进行中, 1=待支付, 2=已支付
  orderAmount: decimal('order_amount', { precision: 10, scale: 2 }).default('0'),
  chargeCapacity: decimal('charge_capacity', { precision: 10, scale: 4 }).default('0'), // kWh
  chargePower: decimal('charge_power', { precision: 8, scale: 2 }).default('0'),
  chargeFee: decimal('charge_fee', { precision: 8, scale: 2 }).default('0'),
  chargeTime: integer('charge_time').default(0), // 秒
  soc: integer('soc').default(0), // 当前SOC百分比
  initialValue: integer('initial_value').default(0), // 起始SOC百分比
  paymentMethod: varchar('payment_method', { length: 128 }),
  userName: varchar('user_name', { length: 128 }),
  startTime: timestamp('start_time'),
  endTime: timestamp('end_time'),
  payTime: timestamp('pay_time'),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
}, (t) => [
  index('idx_orders_user').on(t.userId),
  index('idx_orders_user_status').on(t.userId, t.orderStatus),
  index('idx_orders_station').on(t.stationId),
  index('idx_orders_no').on(t.orderNo),
])

// ============ 预约表 ============
export const reservations = pgTable('reservations', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  portId: uuid('port_id').notNull().references(() => ports.id),
  stationName: varchar('station_name', { length: 256 }).notNull(),
  portName: varchar('port_name', { length: 128 }).notNull(),
  startTime: timestamp('start_time').notNull(),
  endTime: timestamp('end_time').notNull(),
  socValue: integer('soc_value').default(0),
  status: smallint('status').notNull().default(0), // 0=进行中, 1=已完成, 2=已取消
  deferTime: integer('defer_time'), // 延迟分钟数
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
}, (t) => [
  index('idx_reservations_user').on(t.userId).where(sql`${t.status} = 0`),
  index('idx_reservations_port').on(t.portId, t.startTime, t.endTime).where(sql`${t.status} = 0`),
  check('chk_time_order', sql`${t.endTime} > ${t.startTime}`),
])

// ============ 代金券表 ============
export const vouchers = pgTable('vouchers', {
  id: uuid('id').primaryKey().defaultRandom(),
  voucherType: varchar('voucher_type', { length: 64 }).notNull(),
  voucherValue: decimal('voucher_value', { precision: 8, scale: 2 }).notNull(),
  totalNum: integer('total_num').notNull().default(1),
  usedNum: integer('used_num').notNull().default(0),
  stationId: uuid('station_id').references(() => stations.id), // null=通用券
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
})

// ============ 用户代金券关联表 ============
export const userVouchers = pgTable('user_vouchers', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  voucherId: uuid('voucher_id').notNull().references(() => vouchers.id),
  isUsed: smallint('is_used').notNull().default(0), // 0=未使用, 1=已使用
  claimedAt: timestamp('claimed_at').notNull().defaultNow(),
  usedAt: timestamp('used_at'),
}, (t) => [
  uniqueIndex('idx_user_vouchers_unique').on(t.userId, t.voucherId),
  index('idx_user_vouchers_user').on(t.userId).where(sql`${t.isUsed} = 0`),
  index('idx_user_vouchers_voucher').on(t.voucherId),
])

// ============ 收藏表 ============
export const collections = pgTable('collections', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  createdAt: timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  uniqueIndex('idx_collections_unique').on(t.userId, t.stationId),
  index('idx_collections_user').on(t.userId),
  index('idx_collections_station').on(t.stationId),
])

// ============ 进站记录表 ============
export const stationAccessRecords = pgTable('station_access_records', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  portId: uuid('port_id').references(() => ports.id),
  stationName: varchar('station_name', { length: 256 }),
  portName: varchar('port_name', { length: 128 }),
  chargeFee: decimal('charge_fee', { precision: 8, scale: 2 }),
  chargePower: decimal('charge_power', { precision: 8, scale: 2 }),
  chargeType: smallint('charge_type'),
  latitude: decimal('latitude', { precision: 10, scale: 7 }),
  longitude: decimal('longitude', { precision: 10, scale: 7 }),
  enterTime: timestamp('enter_time').notNull().defaultNow(),
  leaveTime: timestamp('leave_time'),
  status: smallint('status').notNull().default(0), // 0=在站内, 1=已离开
}, (t) => [
  index('idx_access_user').on(t.userId).where(sql`${t.status} = 0`),
  index('idx_access_station').on(t.stationId),
])

// ============ 有序桩绑定表 ============
export const portBindings = pgTable('port_bindings', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id),
  stationId: uuid('station_id').notNull().references(() => stations.id),
  portId: uuid('port_id').notNull().references(() => ports.id),
  stationName: varchar('station_name', { length: 256 }).notNull(),
  portName: varchar('port_name', { length: 128 }).notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
}, (t) => [
  index('idx_port_bindings_user').on(t.userId),
])
