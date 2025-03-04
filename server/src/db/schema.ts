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

export const unidadesTable = pgTable('unidades', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion')
})

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

export const sucursalesTable = pgTable('sucursales', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  direccion: text('direccion'),
  sucursalCentral: boolean('sucursal_central').notNull(),
  ...timestampsColumns
})

export const notificacionesTable = pgTable('notificaciones', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  titulo: text('titulo').notNull(),
  descripcion: text('descripcion'),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const productosTable = pgTable('productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  sku: text('sku').notNull().unique(),
  nombre: text('nombre').notNull().unique(),
  descripcion: text('descripcion'),
  maxDiasSinReabastecer: integer('max_dias_sin_reabastecer'),
  unidadId: integer('unidad_id')
    .notNull()
    .references(() => unidadesTable.id),
  categoriaId: integer('categoria_id')
    .notNull()
    .references(() => categoriasTable.id),
  marcaId: integer('marca_id')
    .notNull()
    .references(() => marcasTable.id),
  ...timestampsColumns
})

// Se requiere esta tabla?
export const gruposProductosTable = pgTable('grupos_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull().unique(),
  cantidadGrupo: integer('cantidad_grupo').notNull().default(2),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  ...timestampsColumns
})

export const fotosProductosTable = pgTable('fotos_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  ubicacion: text('ubicacion').notNull(),
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  ),
  ...timestampsColumns
})

export const preciosProductosTable = pgTable('precios_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  precioBase: numeric('precio_base', { precision: 7, scale: 2 }),
  precioMayorista: numeric('precio_mayorista', { precision: 7, scale: 2 }),
  precioOferta: numeric('precio_oferta', { precision: 7, scale: 2 }),
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  ),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id)
})

export const inventariosTable = pgTable('inventarios', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  stock: integer('stock').notNull().default(0),
  productoId: integer('producto_id')
    .notNull()
    .references(() => productosTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})

export const empleadosTable = pgTable('empleados', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre').notNull(),
  apellidos: text('apellidos').notNull(),
  ubicacionFoto: text('ubicacion_foto'),
  edad: integer('edad'),
  dni: text('dni'),
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

export const permisosTable = pgTable('permisos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  codigoPermiso: text('codigo_permiso').notNull().unique(),
  nombrePermiso: text('nombre_permiso').notNull().unique()
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

export const proformasVentaTable = pgTable('proformas_venta', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  nombre: text('nombre'),
  total: numeric('total', { precision: 8, scale: 2 }).notNull(),
  detalles: jsonb('detalles').notNull().$type<
    Array<{
      productoId: number
      grupoProductoId: number
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
  productoId: integer('producto_id').references(() => productosTable.id),
  grupoProductoId: integer('grupo_producto_id').references(
    () => gruposProductosTable.id
  ),
  ventaId: integer('venta_id')
    .notNull()
    .references(() => ventasTable.id)
})

export const descuentosTable = pgTable('descuentos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  monto: numeric('monto', { precision: 7, scale: 2 }).notNull(),
  descripcion: text('descripcion'),
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
    cantidad: integer('cantidad').notNull().default(1),
    estadoTransferenciaId: integer('estado_transferencia_id')
      .notNull()
      .references(() => estadosTransferenciasInventarios.id),
    productoId: integer('producto_id')
      .notNull()
      .references(() => productosTable.id),
    sucursalOrigenId: integer('sucursal_origen_id')
      .notNull()
      .references(() => sucursalesTable.id),
    sucursalDestinoId: integer('sucursal_destino_id')
      .notNull()
      .references(() => sucursalesTable.id),
    ...timestampsColumns
  }
)

export const reservasProductosTable = pgTable('reservas_productos', {
  id: integer('id').primaryKey().generatedAlwaysAsIdentity(),
  cantidad: integer('cantidad').notNull().default(1),
  total: numeric('total', { precision: 7, scale: 2 }).notNull(),
  montoAdelantado: numeric('monto_adelantado', {
    precision: 7,
    scale: 2
  }).notNull(),
  clienteId: integer('cliente_id')
    .notNull()
    .references(() => clientesTable.id),
  sucursalId: integer('sucursal_id')
    .notNull()
    .references(() => sucursalesTable.id),
  ...timestampsColumns
})
