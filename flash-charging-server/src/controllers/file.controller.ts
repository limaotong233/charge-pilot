import { Response, NextFunction } from 'express'
import path from 'path'
import fs from 'fs'
import { fileService } from '../services/file.service'
import { AuthRequest } from '../types'

export async function downloadFile(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const fileCode = req.query.fileCode as string
    if (!fileCode) {
      res.status(400).send('Missing fileCode')
      return
    }

    const file = await fileService.getFileByCode(fileCode)
    if (!file) {
      res.status(404).send('File not found')
      return
    }

    res.setHeader('Content-Type', file.fileType)
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(file.fileName)}"`)
    fs.createReadStream(file.filePath).pipe(res)
  } catch (err) {
    next(err)
  }
}
