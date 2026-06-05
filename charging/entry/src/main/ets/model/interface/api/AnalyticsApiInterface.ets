export interface TopStationItem {
  stationName: string,
  count: number
}

export interface MonthlyTrendItem {
  month: string,
  capacity: number,
  amount: number
}

export interface AnalyticsOverview {
  totalOrders: number,
  totalCapacity: number,
  totalAmount: number,
  avgCapacity: number,
  avgAmount: number,
  co2Reduction: number,
  topStations: TopStationItem[],
  monthlyTrend: MonthlyTrendItem[]
}
