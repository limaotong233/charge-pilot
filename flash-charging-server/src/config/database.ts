import { drizzle } from 'drizzle-orm/node-postgres'
import { Pool } from 'pg'
import { config } from './index'
import * as schema from '../models/schema'

const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  database: config.db.name,
  user: config.db.user,
  password: config.db.password,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})

pool.on('error', (err) => {
  console.error('数据库连接池错误:', err)
})

export const db = drizzle(pool, { schema })
export { pool }
