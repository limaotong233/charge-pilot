export interface PaginationParams {
  currentPage: number
  pageSize: number
}

export interface PaginatedResult<T> {
  total: number
  list: T[]
}

export function getPagination(params: PaginationParams) {
  const page = Math.max(1, params.currentPage)
  const size = Math.min(Math.max(1, params.pageSize), 1000)
  const offset = (page - 1) * size
  return { offset, limit: size, page, size }
}
