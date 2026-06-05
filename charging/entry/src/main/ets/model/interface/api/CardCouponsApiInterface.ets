export interface VoucherListVO {
  currentPage: number,
  pageSize: number,
}

export interface VoucherCountVO {
  data: number
}

export interface VoucherAddVO {
  voucherId: string
}

export interface VoucherListReturning {
  total: number,
  list: Array<VoucherListItem>
}

export interface VoucherListItem {
  voucherId: string,
  voucherType: string,
  usedNum: number,
  totalNum: number,
  voucherValue: number
}

export interface VoucherCountReturning {
  data: number
}