import { CustomError } from '@/core/errors/custom.error'
import { formatFileName } from '@/core/lib/format-values'
import { Validator } from '@/domain/validators/validator'
import multer from 'multer'
import path from 'node:path'

const privateDiskStorage = multer.diskStorage({
  destination: function (_req, _file, callback) {
    callback(null, 'storage/private')
  },
  filename: function (_req, file, callback) {
    if (!Validator.isValidFileName(file.originalname)) {
      callback(CustomError.badRequest('El nombre del archivo es inválido'), '')
    }

    const extension = path.extname(file.originalname).toLowerCase()
    const formattedName = formatFileName(file.originalname)

    callback(null, `${Date.now().toString(16)}-${formattedName}${extension}`)
  }
})

export class FilesMiddleware {
  static readonly image = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const allowedTypes = /jpeg|jpg|png|webp/

      const extName = allowedTypes.test(
        path.extname(file.originalname).toLowerCase()
      )

      const mimeType = allowedTypes.test(file.mimetype)

      if (extName && mimeType) {
        callback(null, true)
        return
      }

      callback(
        CustomError.badRequest(
          'Invalid file type. Only JPEG, JPG, and PNG are allowed'
        )
      )
    }
  })

  static readonly apk = multer({
    storage: privateDiskStorage,
    limits: { fileSize: 500 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const extName = path
        .extname(file.originalname)
        .toLowerCase()
        .includes('apk')

      const mimeType =
        file.mimetype === 'application/vnd.android.package-archive'

      if (extName && mimeType) {
        callback(null, true)
        return
      }

      callback(
        CustomError.badRequest('Invalid file type. Only APK files are allowed')
      )
    }
  })
}
