import { permissionCodes } from '@/consts'
import { AccessControl } from '@/core/access-control/access-control'
import { CustomError } from '@/core/errors/custom.error'
import { db } from '@/db/connection'
import { tiposDocFacturacionTable, ventasTable } from '@/db/schema'
import type { CancelDocumentDto } from '@/domain/dtos/entities/facturacion/cancel-document.dto'
import type { BillingService } from '@/types/interfaces'
import type { SucursalIdType } from '@/types/schemas'
import { and, eq } from 'drizzle-orm'

export class CancelDocument {
  private readonly authPayload: AuthPayload
  private readonly billingService: BillingService
  private readonly permissionAny = permissionCodes.facturacion.cancelAny
  private readonly permissionRelated = permissionCodes.facturacion.cancelRelated

  constructor(authPayload: AuthPayload, billingService: BillingService) {
    this.authPayload = authPayload
    this.billingService = billingService
  }

  async getDocument(
    cancelDocumentDto: CancelDocumentDto,
    sucursalId: SucursalIdType
  ) {
    const ventas = await db
      .select({
        serie: ventasTable.serieDocumento,
        numero: ventasTable.numeroDocumento,
        anulada: ventasTable.anulada,
        motivoAnulado: ventasTable.motivoAnulado,
        tipo_documento: tiposDocFacturacionTable.codigoSunat
      })
      .from(ventasTable)
      .innerJoin(
        tiposDocFacturacionTable,
        eq(ventasTable.tipoDocumentoId, tiposDocFacturacionTable.id)
      )
      .where(
        and(
          eq(ventasTable.id, cancelDocumentDto.ventaId),
          eq(ventasTable.sucursalId, sucursalId)
        )
      )

    if (ventas.length < 1) {
      throw CustomError.notFound(
        `No se encontró la venta con id ${cancelDocumentDto.ventaId} en la sucursal especificada`
      )
    }

    const [venta] = ventas

    if (venta.anulada) {
      throw CustomError.notFound(
        `Esta venta no puede ser anulada (Ya ha sido anulada con anterioridad)`
      )
    }

    const { motivoAnulado: motivo } = venta

    if (motivo === null) {
      throw CustomError.notFound(
        `No se pudo anular el documento de facturación, no se especificó un motivo de anulación`
      )
    }

    return {
      serie: venta.serie,
      numero: venta.numero,
      motivo,
      tipo_documento: venta.tipo_documento
    }
  }

  async cancelDocument(
    cancelDocument: CancelDocumentDto,
    cancelDoc: CancelDoc
  ) {
    const { data: documentDataResponse, error } =
      await this.billingService.cancelDocument({
        document: cancelDoc
      })

    return {
      documentDataResponse,
      error
    }

    // if (error !== null) {
    //   throw CustomError.badGateway(error.message)
    // }

    // const estados = await db
    //   .select({
    //     id: estadosDocFacturacionTable.id,
    //     codigoSunat: estadosDocFacturacionTable.codigoSunat
    //   })
    //   .from(estadosDocFacturacionTable)
    //   .where(
    //     eq(
    //       estadosDocFacturacionTable.codigoSunat,
    //       documentDataResponse.data.state_type_id
    //     )
    //   )

    // const estado = estados.find(
    //   (e) => e.codigoSunat === documentDataResponse.data.state_type_id
    // )

    // const estadoId = estado != null ? estado.id : null

    // return await db.transaction(async (tx) => {
    //   const [documento] = await tx
    //     .update(docsFacturacionTable)
    //     .set({
    //       factproFilename: documentDataResponse.data.filename,
    //       factproDocumentId: documentDataResponse.data.external_id,
    //       hash: documentDataResponse.data.hash,
    //       qr: documentDataResponse.data.qr,
    //       linkXml: documentDataResponse.links.xml,
    //       linkPdf: documentDataResponse.links.pdf,
    //       linkCdr: documentDataResponse.links.cdr,
    //       estadoRawId: documentDataResponse.data.state_type_id,
    //       estadoId,
    //       informacionSunat: documentDataResponse.sunat_information
    //     })
    //     .where(eq(docsFacturacionTable.ventaId, cancelDocument.ventaId))
    //     .returning({ id: docsFacturacionTable.id })

    //   const updatedResults = await tx
    //     .update(ventasTable)
    //     .set({ declarada: true })
    //     .where(eq(ventasTable.id, cancelDocument.ventaId))
    //     .returning({ id: ventasTable.id })

    //   if (updatedResults.length < 1) {
    //     throw CustomError.internalServer(
    //       'Ha ocurrido un problema al intentar sincronizar el estado de la venta (Contacte a soporte técnico para resolver este problema)'
    //     )
    //   }

    //   return documento
    // })
  }

  private async validatePermissions(sucursalId: SucursalIdType) {
    const validPermissions = await AccessControl.verifyPermissions(
      this.authPayload,
      [this.permissionAny, this.permissionRelated]
    )

    let hasPermissionAny = false
    let hasPermissionRelated = false
    let isSameSucursal = false

    for (const permission of validPermissions) {
      if (permission.codigoPermiso === this.permissionAny) {
        hasPermissionAny = true
      }
      if (permission.codigoPermiso === this.permissionRelated) {
        hasPermissionRelated = true
      }
      if (permission.sucursalId === sucursalId) {
        isSameSucursal = true
      }

      if (hasPermissionAny || (hasPermissionRelated && isSameSucursal)) {
        return
      }
    }

    throw CustomError.forbidden()
  }

  async execute(
    cancelDocumentDto: CancelDocumentDto,
    sucursalId: SucursalIdType
  ) {
    await this.validatePermissions(sucursalId)

    const document = await this.getDocument(cancelDocumentDto, sucursalId)

    const result = await this.cancelDocument(cancelDocumentDto, document)

    return result
  }
}
