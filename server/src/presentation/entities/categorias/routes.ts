import { Router } from 'express'
import { CategoriasController } from './controller'

export class CategoriasRoutes {
  static get routes() {
    const router = Router()
    const categoriasController = new CategoriasController()
    
    // Obtener todas las categorías
    router.get('/', categoriasController.getAll)
    
    // Crear una nueva categoría
    router.post('/', categoriasController.create)

    return router
  }
}
