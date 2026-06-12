/**
 * 数据库迁移脚本：为预约表添加 GiST 排他约束
 *
 * 核心原理：
 * - tsrange(start_time, end_time) 将两个时间戳转成时间区间
 * - && 操作符判断两个区间是否有重叠
 * - EXCLUDE 约束在插入/更新时自动检查，若重叠则拒绝写入
 * - WHERE status = 0 表示只对"进行中"的预约生效，已取消/已完成的预约不参与冲突检测
 *
 * 优势：
 * - 原子操作，不需要应用层加锁
 * - 天然防并发，即使两个请求同时到达也只有一个能成功
 * - 比应用层 SELECT FOR UPDATE 更简单、更可靠
 */

import 'dotenv/config'
import { sql } from 'drizzle-orm'
import { db, pool } from './config/database'

async function migrate() {
  console.log('开始执行迁移：添加预约排他约束...')

  try {
    // 1. 先删除可能存在的旧约束（幂等）
    await db.execute(sql`
      DO $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM pg_constraint WHERE conname = 'reservations_tsrange_exclusion'
        ) THEN
          ALTER TABLE reservations DROP CONSTRAINT reservations_tsrange_exclusion;
          RAISE NOTICE '已移除旧排他约束';
        END IF;
      END
      $$;
    `)

    // 2. 创建排他约束
    await db.execute(sql`
      ALTER TABLE reservations
      ADD CONSTRAINT reservations_tsrange_exclusion
      EXCLUDE USING gist (
        port_id WITH =,
        tsrange(start_time, end_time) WITH &&
      ) WHERE (status = 0);
    `)

    console.log('排他约束创建成功!')
    console.log('约束名: reservations_tsrange_exclusion')
    console.log('规则: 同一充电桩(port_id)的进行中(status=0)预约时段不能重叠')

  } catch (err) {
    console.error('迁移失败:', err)
    process.exit(1)
  }

  await pool.end()
}

migrate()
