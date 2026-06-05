export interface OrderPayVO {
  orderId: string
}

export interface OrderPayPrice {
  price: string
}

export interface OrderPayQRcode {
  QRCode: string
}

export interface OrderCreateVO {
  stationId: string,
  stationName: string,
  portId: string,
  portName: string,
  isReserve: number // 0非预约 1预约
}

export interface OrderCreateReturning {
  number: number,
  seconds: number,
  orderId: string
}

export interface OrderListVO {
  currentPage: number,
  pageSize: number,
  orderStatus: number | null // 0进行中 1待支付 2已支付
}

export interface OrderListReturning {
  total: number,
  list: Array<OrderListItem>
}

export interface OrderListItem {
  orderId: string,
  stationName: string,
  portName: string,
  orderAmount: string,
  startTime: string, // 充电时间
  endTime: string, //充电结束时间
  orderNo: string //订单编号
  portId: string,
  orderStatus: number // 0 进行中 1待支付 2 已支付
  payTime: Date, //支付时间
  chargeCapacity: number, //
  userName: string
}

export interface OrderDetailReturning {
  orderId: string,
  stationName: string,
  portName: string,
  orderAmount: number, //订单金额
  startTime: string, // 充电时间
  endTime: string, //充电结束时间
  orderNo: string //订单编号
  portId: string,
  orderStatus: number // 0 进行中 1待支付 2 已支付
  payTime: Date, //支付时间
  chargeCapacity: number //充电量
  chargePower: number //功率
  chargeFee: number //费用,
  userName: string,
  initialValue: number // soc初始值
  paymentMethod: string // 代金券,
  chargeTime: number //充电时间
  soc: number
}