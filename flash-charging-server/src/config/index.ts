import 'dotenv/config'

export const config = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),

  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    name: process.env.DB_NAME || 'flash_charging',
    user: process.env.DB_USER || 'charging_app',
    password: process.env.DB_PASSWORD || '',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'change-me-in-production',
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '2h',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },

  file: {
    storagePath: process.env.FILE_STORAGE_PATH || './uploads',
    maxSize: parseInt(process.env.FILE_MAX_SIZE || '10485760', 10), // 10MB
  },

  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),
}

export function getDatabaseUrl(): string {
  const { host, port, name, user, password } = config.db
  return `postgresql://${user}:${password}@${host}:${port}/${name}`
}
