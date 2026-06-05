import path from 'path'
import fs from 'fs'
import { db } from '../config/database'
import { files } from '../models/schema'
import { eq } from 'drizzle-orm'
import { config } from '../config'

export class FileService {
  async getFileByCode(fileCode: string) {
    const [file] = await db
      .select()
      .from(files)
      .where(eq(files.fileCode, fileCode))
      .limit(1)

    if (!file) {
      return null
    }

    const filePath = path.resolve(file.filePath)
    if (!fs.existsSync(filePath)) {
      return null
    }

    return {
      filePath,
      fileName: file.fileName,
      fileType: file.fileType || 'application/octet-stream',
    }
  }

  async saveFile(file: Express.Multer.File, uploaderId?: string): Promise<string> {
    const fileCode = `FC${Date.now()}${Math.random().toString(36).substring(2, 8).toUpperCase()}`

    await db.insert(files).values({
      fileName: file.originalname,
      filePath: file.path,
      fileType: file.mimetype,
      fileSize: file.size,
      fileCode,
      uploaderId,
    })

    return fileCode
  }
}

export const fileService = new FileService()
