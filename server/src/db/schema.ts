import {
  boolean,
  date,
  integer,
  jsonb,
  numeric,
  pgTable,
  primaryKey,
  text,
  time,
  timestamp
} from 'drizzle-orm/pg-core'

const timestampsColumns = {
  fechaCreacion: timestamp('fecha_creacion', {
    mode: 'date',
    withTimezone: false
  })
    .notNull()
    .defaultNow(),
  fechaActualizacion: timestamp('fecha_actualizacion', {
    mode: 'date',
    withTimezone: false
  })
    .notNull()
    .defaultNow()
}

export const sucursalesTable = pgTable('sucursales', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  direccion: text('direccion'),
  sucursalCentral: boolean('sucursal_central').notNull(),
  ...timestampsColumns
})

// Productos

export const categoriasTable = pgTable('categorias', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion')
})

export const marcasTable = pgTable('marcas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion')
})

export const coloresTable = pgTable('colores', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique()
})

export const productosTable = pgTable('productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  // sku: text('sku').notNull().unique(),
  nombre: text('nombre').notNull(),
  descripcion: text('descripcion'),
  maxDiasSinReabastecer: integer('max_dias_sin_reabastecer'),
  stockMinimo: integer('stock_minimo'),
  cantidadMinimaDescuento: integer('cantidad_minima_descuento'),
  cantidadGratisDescuento: integer('cantidad_gratis_descuento'),
  porcentajeDescuento: integer('porcentaje_descuento'),
  colorId: integer('color_id')
    .notNull()
    .references(() => coloresTable.id),
  categoriaId: integer('categoria_id')
    .notNull()
    .references(() => categoriasTable.id),
  marcaId: integer('marca_id')
    .notNull()
    .references(() => marcasTable.id),
  ...timestampsColumns
})

export const detallesProductoTable = pgTable('detalles_producto', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  precioCompra: numeric('precio_compra', { precision: 7, scale: 2 }),
  precioVenta: numeric('precio_venta', { precision: 7, scale: 2 }),
  precioOferta: numeric('precio_oferta', { precision: 7, scale: 2 }),
  stock: integer('stock').notNull().default(0),
  stockBajo: boolean('stock_bajo').notNull().default(false),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const fotosProductosTable = pgTable('fotos_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  path: text('path').notNull(),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  ...timestampsColumns
})

// Inventarios

export const entradasInventariosTable = pgTable('entradas_inventarios', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const estadosTransferenciasInventarios = pgTable(
  'estados_transferencias_inventarios',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    nombre: text('nombre').notNull().unique(),
    codigo: text('codigo').notNull().unique()
  }
)

export const transferenciasInventariosTable = pgTable(
  'transferencias_inventarios',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    solicitanteId: integer('empleado_id')
      .notNull()
      .references(() => empleadosTable.id),
    proveedorId: integer('proveedor_id')
      .notNull()
      .references(() => empleadosTable.id),
    estadoTransferenciaId: integer('estado_transferencia_id')
      .notNull()
      .references(() => estadosTransferenciasInventarios.id),
    sucursalOrigenId: integer('sucursal_origen_id')
      .notNull()
      .references(() => sucursalesTable.id),
    sucursalDestinoId: integer('sucursal_destino_id')
      .notNull()
      .references(() => sucursalesTable.id),
    salidaOrigen: timestamp('salida_origen', {
      mode: 'date',
      withTimezone: false
    })
      .notNull()
      .defaultNow(),
    llegadaDestino: timestamp('llegada_destino', {
      mode: 'date',
      withTimezone: false
    })
      .notNull()
      .defaultNow(),
    ...timestampsColumns
  }
)

export const detallesTransferenciaInventarioTable = pgTable(
  'detalles_transferencia_inventario',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
    cantidad: integer('cantidad').notNull().default(1),
    productoId: integer('producto_id')
      .notNull()
      .references(() => productosTable.id),
    transferenciaInventarioId: integer('transferencia_inventario_id')
      .notNull()
      .references(() => transferenciasInventariosTable.id)
  }
)

// Empleados y clientes

export const empleadosTable = pgTable('empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull(),
  apellidos: text('apellidos').notNull(),
  activo: boolean('activo').notNull().default(true),
  dni: text('dni').notNull().unique(),
  pathFoto: text('path_foto'),
  celular: text('celular'),
  horaInicioJornada: time('hora_inicio_jornada'),
  horaFinJornada: time('hora_fin_jornada'),
  fechaContratacion: date('fecha_contratacion', {
    mode: 'string'
  }),
  sueldo: numeric('sueldo', {
    precision: 7,
    scale: 2
  }),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const tiposPersonasTable = pgTable('tipos_personas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigo: text('codigo').notNull().unique(),
  nombre: text('nombre').notNull().unique()
})

export const clientesTable = pgTable('clientes', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombresApellidos: text('nombres_apellidos'),
  dni: text('dni'),
  razonSocial: text('razon_social'),
  ruc: text('ruc'),
  telefono: text('telefono'),
  correo: text('correo'),
  tipoPersonaId: integer('tipo_persona_id')
    .notNull()
    .references(() => tiposPersonasTable.id),
  ...timestampsColumns
})

// Usuarios

export const permisosTable = pgTable('permisos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigoPermiso: text('codigo_permiso').notNull().unique(),
  nombrePermiso: text('nombre_permiso').notNull().unique()
})

export const rolesCuentasEmpleadosTable = pgTable('roles_cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigo: text('codigo').notNull().unique(),
  nombreRol: text('nombre_rol').notNull().unique()
})

export const cuentasEmpleadosTable = pgTable('cuentas_empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  usuario: text('usuario').notNull().unique(),
  clave: text('clave').notNull(),
  secret: text('secret').notNull(),
  rolCuentaEmpleadoId: integer('rol_cuenta_empleado_id')
    .notNull()
    .references(() => rolesCuentasEmpleadosTable.id),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  ...timestampsColumns
})

export const rolesPermisosTable = pgTable(
  'roles_permisos',
  {
    rolId: integer('rol_id')
      .notNull()
      .references(() => rolesCuentasEmpleadosTable.id),
    permisoId: integer('permiso_id')
      .notNull()
      .references(() => permisosTable.id)
  },
  (table) => [primaryKey({ columns: [table.rolId, table.permisoId] })]
)

// Ventas

export const metodosPagoTable = pgTable('metodos_pago', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  codigo: text('codigo').notNull().unique(),
  activado: boolean('activado').notNull()
})

export const ventasTable = pgTable('ventas', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  total: numeric('total', { precision: 8, scale: 2 }).notNull(),
  observaciones: text('observaciones'),
  metodoPagoId: integer('metodo_pago_id')
    .notNull()
    .references(() => metodosPagoTable.id),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const detallesTable = pgTable('detalles', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  subtotal: numeric('subtotal', { precision: 7, scale: 2 }).notNull(),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const devolucionesTable = pgTable('devoluciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  motivo: text('motivo').notNull(),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const descuentosTable = pgTable('descuentos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  monto: numeric('monto', { precision: 7, scale: 2 }).notNull(),
  descripcion: text('descripcion'),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const proformasVentaTable = pgTable('proformas_venta', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre'),
  total: numeric('total', { precision: 8, scale: 2 }).notNull(),
  detalles: jsonb('detalles').notNull().$type<
    Array<{
      productoId: number
      nombre: string
      cantidad: number
      subtotal: number
    }>
  >(),
  empleadoId: integer('empleado_id')
    .notNull()
    .references(() => empleadosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const reservasProductosTable = pgTable('reservas_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  descripcion: text('descripcion'),
  detallesReserva: jsonb('detalles_reserva').notNull().$type<{
    nombreProducto: number
    precioCompra: number
    precioVenta: number
    cantidad: number
    total: number
  }>(),
  montoAdelantado: numeric('monto_adelantado', {
    precision: 7,
    scale: 2
  }).notNull(),
  fechaContratacion: date('fecha_contratacion', {
    mode: 'string'
  }),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  sucursalId: integer('sucursal_id').references(() => sucursalesTable.id),
  ...timestampsColumns
})

// Extras

export const notificacionesTable = pgTable('notificaciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  titulo: text('titulo').notNull(),
  descripcion: text('descripcion'),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})
