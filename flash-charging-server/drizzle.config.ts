import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  schema: './src/models/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    url: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER || 'charging_app'}:${process.env.DB_PASSWORD || ''}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME || 'flash_charging'}`,
  },
})
