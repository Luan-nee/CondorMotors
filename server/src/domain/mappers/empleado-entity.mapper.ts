import { CustomError } from '@/core/errors/custom.error'
import type { EmpleadoEntity } from '@/types/schemas'

export class EmpleadoEntityMapper {
  static empleadoEntityFromObject(input: any): EmpleadoEntity {
    const {
      id,
      nombre,
      apellidos,
      ubicacionFoto,
      edad,
      dni,
      horaInicioJornada,
      horaFinJornada,
      fechaContratacion,
      sueldo,
      sucursalId,
      fechaCreacion,
      fechaActualizacion
    } = input

    if (id === undefined) {
      throw CustomError.badRequest('Missing id')
    }
    if (nombre === undefined) {
      throw CustomError.badRequest('Missing nombre')
    }
    if (apellidos === undefined) {
      throw CustomError.badRequest('Missing apellidos')
    }
    if (sucursalId === undefined) {
      throw CustomError.badRequest('Missing sucursalId')
    }
    if (fechaCreacion === undefined) {
      throw CustomError.badRequest('Missing fechaCreacion')
    }
    if (fechaActualizacion === undefined) {
      throw CustomError.badRequest('Missing fechaActualizacion')
    }

    const parsedSueldo =
      typeof sueldo === 'string' ? parseFloat(sueldo) : sueldo

    return {
      id,
      nombre,
      apellidos,
      ubicacionFoto,
      edad,
      dni,
      horaInicioJornada,
      horaFinJornada,
      fechaContratacion,
      sueldo: parsedSueldo,
      sucursalId,
      fechaCreacion,
      fechaActualizacion
    }
  }
}
