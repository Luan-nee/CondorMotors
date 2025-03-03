import { SucursalesRoutes } from '@presentation/entities/sucursales/routes'
import { EmpleadosRoutes } from '@presentation/entities/empleados/routes'
import { MarcasRoutes } from '@presentation/entities/marcas/routes'
import { AuthMiddleware } from '@presentation/middlewares/auth.middleware'
import { Router } from 'express'

export class EntitiesRoutes {
  static get routes() {
    const router = Router()

    router.use('/sucursales', AuthMiddleware.requests, SucursalesRoutes.routes)
    router.use('/empleados', AuthMiddleware.requests, EmpleadosRoutes.routes)
    router.use('/marcas', AuthMiddleware.requests, MarcasRoutes.routes)
    return router
  }
}
