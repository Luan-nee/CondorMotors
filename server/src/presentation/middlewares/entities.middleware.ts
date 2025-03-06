import { CustomResponse } from '@/core/responses/custom.response'
import { paramsSucursalIdValidator } from '@/domain/validators/query-params/query-params.validator'
import type { NextFunction, Request, Response } from 'express'

export class EntitiesMiddleware {
  static readonly soloSucursal = (
    req: Request,
    res: Response,
    next: NextFunction
  ) => {
    const result = paramsSucursalIdValidator(req.params)

    if (!result.success) {
      CustomResponse.badRequest({ res, error: 'Id de sucursal inválido' })
      return
    }

    const {
      data: { sucursalId }
    } = result

    req.sucursalId = sucursalId

    next()
  }
}
