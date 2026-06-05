import { Request } from 'express'

// 扩展 Express Request 类型，添加用户信息
export interface AuthRequest extends Request {
  user?: {
    userId: string
    account: string
  }
}

// 分页请求参数
export interface PaginatedBody {
  currentPage: number
  pageSize: number
}

// ============ 认证相关 ============
export interface LoginForm {
  account: string
  password: string
}

export interface LoginResult {
  accessToken: string
  refreshToken: string
}

export interface UserInfoResult {
  account: string
  userName: string
  avatar: {
    fileAccessUrl: string
  }
}

// ============ 充电站相关 ============
export interface StationListBody extends PaginatedBody {
  stationName: string
  chargeType: number | null
}

export interface StationDetailBody {
  stationId: string
}

export interface StationListItem {
  stationId: string
  stationName: string
  latitude: number
  longitude: number
  chargeType: number
  portCount: number
  chargeFee: number
  chargePower: number
  usedCount: number
  isCollect: number
  distance: number
  fileCode: string
  delFlag: number
}

export interface StationDetailItem {
  stationId: string
  stationName: string
  stationType: number
  latitude: number
  longitude: number
  chargeType: number
  portCount: number
  chargeFee: number
  chargePower: number
  usedCount: number
  serviceProvider: string
  openTime: string
  invoiceType: string
  paymentMethod: string
  isCollect: number
  distance: number
  fileCode: string
}

export interface StationPortItem {
  portId: string
  portName: string
  stationId: string
  stationName: string
  chargeFee: number
  chargePower: number
  serviceProvider: string
  openTime: string
  invoiceType: string
  paymentMethod: string
  reserveTime: string | null
  portStatus: number
}

// ============ 进站记录相关 ============
export interface EnterDetailItem {
  id: string
  portId: string
  portName: string
  stationId: string
  stationName: string
  chargeFee: number
  chargePower: number
  chargeType: number
  enterTime: Date
  latitude: number
  longitude: number
}

// ============ 订单相关 ============
export interface OrderCreateBody {
  stationId: string
  stationName: string
  portId: string
  portName: string
  isReserve: number
}

export interface OrderCreateResult {
  number: string
  seconds: number
  orderId: string
}

export interface OrderPayBody {
  orderId: string
}

export interface OrderListBody extends PaginatedBody {
  orderStatus: number | null
}

export interface OrderListItem {
  orderId: string
  stationName: string
  portName: string
  orderAmount: number
  orderStatus: number
  startTime: string
  endTime: string
  chargeCapacity: number
}

export interface OrderDetailItem {
  orderId: string
  stationName: string
  portName: string
  orderAmount: number
  startTime: string
  endTime: string
  orderNo: string
  portId: string
  orderStatus: number
  payTime: string
  chargeCapacity: number
  chargePower: number
  chargeFee: number
  userName: string
  initialValue: number
  paymentMethod: string
  chargeTime: number
  soc: number
}

export interface OrderPayPrice {
  price: number
}

// ============ 预约相关 ============
export interface BindBody {
  stationName: string
  portName: string
}

export interface UnbindBody {
  id: string
}

export interface BindDetailItem {
  id: string
  userId: string
  stationId: string
  portId: string
  stationName: string
  portName: string
}

export interface ReserveAddBody {
  stationId: string
  portId: string
  startTime: string
  endTime: string
  socValue: number
}

export interface ReserveCancelBody {
  reserveId: string
}

export interface ReserveDetailItem {
  reserveId: string
  stationId: string
  portId: string
  stationName: string
  portName: string
  startTime: string
  endTime: string
  createdTime: string
  portStatus: number
  defferTime: number | null
}

export interface StationNameListBody extends PaginatedBody {
  stationName: string
}

export interface PortNameListBody {
  stationId: string
}

export interface StationNameItem {
  stationId: string
  stationName: string
}

export interface PortNameItem {
  portId: string
  portName: string
}

// ============ 代金券相关 ============
export interface VoucherListBody extends PaginatedBody {}

export interface VoucherAddBody {
  voucherId: string
}

export interface VoucherListItem {
  voucherId: string
  voucherType: string
  usedNum: number
  totalNum: number
  voucherValue: number
}

export interface VoucherCountResult {
  data: number
}

// ============ 收藏相关 ============
export interface CollectionListBody extends PaginatedBody {
  stationName: string
}

export interface AddCollectBody {
  stationId: string
}

export interface CollectionListItem {
  id: string
  stationId: string
  stationName: string
  stationType: number
  chargeType: number
  latitude: number
  longitude: number
  chargeFee: number
  portCount: number
  chargePower: number
  usedCount: number
  distance: number
  isCollect: number
  delFlag: number
  fileCode: string
}

// ============ 文件下载 ============
export interface DownloadFileBody {
  fileCode: string
}

// ============ 数据分析 ============
export interface TopStationItem {
  stationName: string
  count: number
}

export interface MonthlyTrendItem {
  month: string
  capacity: number
  amount: number
}

export interface AnalyticsOverview {
  totalOrders: number
  totalCapacity: number
  totalAmount: number
  avgCapacity: number
  avgAmount: number
  co2Reduction: number
  topStations: TopStationItem[]
  monthlyTrend: MonthlyTrendItem[]
}
