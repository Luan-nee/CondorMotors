import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.dart';
import '../../main.dart' show api;
import 'widgets/ventas_pendientes_widget.dart';
import 'widgets/form_sales_computer.dart' show NumericKeypad, ProcessingDialog, DebugPrint;

/// Clase utilitaria para operaciones con ventas y formateo de montos
/// 
/// Esta clase centraliza todas las operaciones de cálculo y formateo
/// relacionadas con ventas, precios y montos, lo que ayuda a mantener
/// la consistencia en toda la aplicación.
class VentasUtils {
  /// Calcula el subtotal para un producto (precio * cantidad)
  /// 
  /// Parámetros:
  /// - producto: Mapa con datos del producto que debe incluir 'precio' y 'cantidad'
  /// 
  /// Retorna el subtotal formateado a 2 decimales
  static double calcularSubtotal(Map<String, dynamic> producto) {
    final precio = producto['precio'] as double;
    final cantidad = producto['cantidad'] as int;
    return formatearMonto(precio * cantidad);
  }
  
  /// Calcula el total para una venta completa sumando los subtotales de todos sus productos
  /// 
  /// Parámetros:
  /// - productos: Lista de productos, cada uno debe contener 'precio' y 'cantidad'
  /// 
  /// Retorna el total formateado a 2 decimales
  static double calcularTotalVenta(List<dynamic> productos) {
    double total = 0;
    for (var producto in productos) {
      total += calcularSubtotal(producto);
    }
    return formatearMonto(total);
  }
  
  /// Formatea un monto a 2 decimales, evitando problemas de precisión
  static double formatearMonto(double monto) {
    return double.parse(monto.toStringAsFixed(2));
  }
  
  /// Formatea un monto como texto para mostrar, incluyendo el símbolo de moneda
  static String formatearMontoTexto(double monto) {
    return 'S/ ${monto.toStringAsFixed(2)}';
  }
}

// Definición de la clase Venta para manejar los datos
class Venta {
  final String id;
  final DateTime? fechaCreacion;
  final String estado;
  final double subtotal;
  final double igv;
  final double total;
  final double? descuentoTotal;
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    this.fechaCreacion,
    required this.estado,
    required this.subtotal,
    required this.igv,
    required this.total,
    this.descuentoTotal,
    required this.detalles,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] ?? '',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      estado: json['estado'] ?? 'PENDIENTE',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      igv: (json['igv'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      descuentoTotal: json['descuento_total'] != null 
          ? (json['descuento_total']).toDouble() 
          : null,
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((detalle) => DetalleVenta.fromJson(detalle))
          .toList() ?? [],
    );
  }
}

class DetalleVenta {
  final String productoId;
  final int cantidad;
  final double subtotal;

  DetalleVenta({
    required this.productoId,
    required this.cantidad,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      productoId: json['producto_id'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }
}

// Constantes para los estados de venta
class EstadosVenta {
  static const String pendiente = 'PENDIENTE';
  static const String completada = 'COMPLETADA';
  static const String anulada = 'ANULADA';
}

class SalesComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const SalesComputerScreen({
    super.key,
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  State<SalesComputerScreen> createState() => _SalesComputerScreenState();
}

class _SalesComputerScreenState extends State<SalesComputerScreen> {
  late final VentasApi _ventasApi;
  bool _isLoading = false;
  List<Venta> _ventas = [];
  
  // Datos de prueba para productos

  // Datos de prueba para clientes

  // Datos de prueba para ventas pendientes
  final List<Map<String, dynamic>> _ventasPendientes = [
    {
      'id': 'V001',
      'cliente': {
        'id': 1,
        'nombre': 'Juan Pérez',
        'documento': '12345678',
        'telefono': '987654321',
      },
      'productos': [
        {
          'id': 1,
          'nombre': 'Casco MT Thunder 3',
          'precio': 299.99,
          'cantidad': 1,
        },
        {
          'id': 2,
          'nombre': 'Aceite Motul 5100 4T',
          'precio': 89.99,
          'cantidad': 2,
        },
      ],
      'total': 479.97,
      'fecha': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      'estado': 'PENDIENTE',
    },
    {
      'id': 'V002',
      'cliente': {
        'id': 2,
        'nombre': 'María García',
        'documento': '87654321',
        'telefono': '123456789',
      },
      'productos': [
        {
          'id': 3,
          'nombre': 'Kit de Frenos Brembo',
          'precio': 850.00,
          'cantidad': 1,
        },
      ],
      'total': 850.00,
      'fecha': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      'estado': 'PENDIENTE',
    },
  ];

  // Variables para el procesamiento de ventas pendientes
  Map<String, dynamic>? _ventaSeleccionada;
  String _montoIngresado = '';
  String _nombreCliente = '';
  String _tipoDocumento = 'Boleta';
  bool _procesandoPago = false;
  final FocusNode _montoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ventasApi = api.ventas;
    _cargarVentas();
  }

  @override
  void dispose() {
    _montoFocusNode.dispose();
    super.dispose();
  }

  // Método para manejar la entrada de teclas
  void _handleKeyPress(String key) {
    setState(() {
      if (key == '00') {
        _montoIngresado += '00';
      } else if (_montoIngresado == '0') {
        _montoIngresado = key;
      } else {
        _montoIngresado += key;
      }
    });
  }

  // Método para limpiar el monto
  void _clearAmount() {
    setState(() {
      if (_montoIngresado.isNotEmpty) {
        _montoIngresado = _montoIngresado.substring(0, _montoIngresado.length - 1);
      }
    });
  }

  // Método para cambiar el tipo de documento
  void _changeDocumentType(String type) {
    setState(() {
      _tipoDocumento = type;
    });
  }

  // Método para cambiar el nombre del cliente
  void _changeCustomerName(String name) {
    setState(() {
      _nombreCliente = name;
    });
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      final ventasResponse = await _ventasApi.getVentas(
        sucursalId: widget.sucursalId?.toString(),
      );
      
      if (!mounted) return;
      
      final List<Venta> ventasList = [];
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        for (var item in ventasResponse['data']) {
          ventasList.add(Venta.fromJson(item));
        }
      }
      
      setState(() {
        _ventas = ventasList;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _anularVenta(Venta venta) async {
    try {
      await _ventasApi.anularVenta(
        venta.id,
        'Anulado por el usuario',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta anulada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _cargarVentas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al anular venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método para seleccionar una venta pendiente para procesar
  void _seleccionarVenta(Map<String, dynamic> venta) {
    // Crear una copia profunda para evitar referencias compartidas
    final ventaCopia = _crearCopiaVenta(venta);
    
    // Guardar el total original para mostrar si hay cambios
    ventaCopia['total_original'] = ventaCopia['total'];
    
    setState(() {
      _ventaSeleccionada = ventaCopia;
      _montoIngresado = '';
      _nombreCliente = ventaCopia['cliente']['nombre'];
      _tipoDocumento = 'Boleta'; // Por defecto
    });
    
    // Mostrar el formulario como popup
    _mostrarFormularioVenta(ventaCopia);
  }
  
  // Método para crear una copia profunda de una venta
  Map<String, dynamic> _crearCopiaVenta(Map<String, dynamic> original) {
    final copia = Map<String, dynamic>.from(original);
    
    // Copiar profundamente los productos
    if (copia.containsKey('productos') && copia['productos'] is List) {
      copia['productos'] = (copia['productos'] as List).map((producto) {
        return Map<String, dynamic>.from(producto);
      }).toList();
    }
    
    // Copiar profundamente el cliente
    if (copia.containsKey('cliente') && copia['cliente'] is Map) {
      copia['cliente'] = Map<String, dynamic>.from(copia['cliente']);
    }
    
    return copia;
  }
  
  // Método para mostrar el formulario de ventas como un popup
  void _mostrarFormularioVenta(Map<String, dynamic> venta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Cabecera del popup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.fileInvoiceDollar,
                      color: Color(0xFFE31E24),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Procesar Venta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelarProcesamiento();
                      },
                    ),
                  ],
                ),
              ),
              
              // Cuerpo del popup (detalles de la venta y formulario)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna izquierda: Detalles de la venta
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF4CAF50),
                                    child: FaIcon(
                                      FontAwesomeIcons.user,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          venta['cliente']['nombre'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Doc: ${venta['cliente']['documento']}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE31E24).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      VentasUtils.formatearMontoTexto(venta['total']),
                                      key: ValueKey('header-total-${venta['total']}'),
                                      style: const TextStyle(
                                        color: Color(0xFFE31E24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                              
                              // Etiqueta de Productos
                              const Text(
                                'PRODUCTOS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Lista de productos
                              Expanded(
                                child: ListView.builder(
                                  itemCount: (venta['productos'] as List<dynamic>).length,
                                  itemBuilder: (context, index) {
                                    final producto = venta['productos'][index];
                                    final subtotal = VentasUtils.calcularSubtotal(producto);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Row(
                                          children: [
                                            // Icono del producto
                                            Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.box,
                                                  color: Color(0xFF4CAF50),
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                            // Información del producto
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      producto['nombre'] as String,
                                                      style: const TextStyle(
                                                        color: Colors.white, 
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Precio: S/ ${(producto['precio'] as double).toStringAsFixed(2)}',
                                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'x${producto['cantidad']}',
                                                            style: const TextStyle(
                                                              color: Color(0xFF4CAF50),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Control de cantidad
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Row(
                                                children: [
                                                  // Botón disminuir
                                                  _buildQuantityButton(
                                                    icon: Icons.remove,
                                                    onPressed: () => _actualizarCantidadProducto(venta, index, -1),
                                                    enabled: producto['cantidad'] > 1,
                                                  ),
                                                  // Mostrar cantidad
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2D2D2D),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${producto['cantidad']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  // Botón aumentar
                                                  _buildQuantityButton(
                                                    icon: Icons.add,
                                                    onPressed: () => _actualizarCantidadProducto(venta, index, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Subtotal
                                            Container(
                                              width: 80,
                                              padding: const EdgeInsets.all(8.0),
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                VentasUtils.formatearMontoTexto(subtotal),
                                                key: ValueKey('subtotal-$index-$subtotal'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const Divider(color: Colors.white24),
                              
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        VentasUtils.formatearMontoTexto(venta['total']),
                                        key: ValueKey('total-${venta['total']}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (_ventaSeleccionada != null && 
                                          _ventaSeleccionada!['total_original'] != null && 
                                          _ventaSeleccionada!['total_original'] != _ventaSeleccionada!['total'])
                                        Text(
                                          'Monto original: ${VentasUtils.formatearMontoTexto(_ventaSeleccionada!['total_original'])}',
                                          style: TextStyle(
                                            color: Colors.orange.shade300,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Columna derecha: Teclado numérico y opciones de pago
                      Expanded(
                        flex: 4,
                        child: NumericKeypad(
                          onKeyPressed: _handleKeyPress,
                          onClear: _clearAmount,
                          onSubmit: () {
                            Navigator.pop(context);
                            _procesarPago();
                          },
                          currentAmount: venta['total'].toString(),
                          paymentAmount: _montoIngresado,
                          customerName: _nombreCliente,
                          documentType: _tipoDocumento,
                          onCustomerNameChanged: _changeCustomerName,
                          onDocumentTypeChanged: _changeDocumentType,
                          isProcessing: _procesandoPago,
                          minAmount: venta['total'],
                          onCharge: (monto) {
                            DebugPrint.log('Monto recibido para cobrar: $monto');
                            Navigator.pop(context);
                            _procesarPago();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Método para procesar el pago de una venta
  Future<void> _procesarPago() async {
    if (_ventaSeleccionada == null) return;
    
    DebugPrint.log('Procesando pago para venta: ${_ventaSeleccionada!['id']} con monto: $_montoIngresado');
    setState(() => _procesandoPago = true);
    
    try {
      // Primero actualizamos las cantidades de productos si hubo cambios
      await _actualizarProductosVenta();
      
      // Mostrar dialog de procesamiento
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ProcessingDialog(documentType: _tipoDocumento),
        );
      }
      
      // Simular procesamiento (aquí harías la llamada a la API)
      await Future.delayed(const Duration(seconds: 2));
      
      DebugPrint.log('Pago procesado exitosamente');
      DebugPrint.log('Marcando venta como procesada');
      
      // Cerrar dialog de procesamiento
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago procesado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reiniciar estado
      setState(() {
        _ventaSeleccionada = null;
        _montoIngresado = '';
        _nombreCliente = '';
        _tipoDocumento = 'Boleta';
        _procesandoPago = false;
      });
      
      // Recargar ventas
      await _cargarVentas();
    } catch (e) {
      DebugPrint.log('Error al procesar pago: $e');
      
      if (mounted) {
        // Cerrar dialog de procesamiento si está abierto
        Navigator.of(context, rootNavigator: true).popUntil(
          (route) => route.isFirst || route.settings.name == 'ventas_dialog'
        );
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() => _procesandoPago = false);
      }
    }
  }
  
  // Método para actualizar productos de la venta (cantidades modificadas)
  Future<void> _actualizarProductosVenta() async {
    if (_ventaSeleccionada == null) return;
    
    try {
      DebugPrint.log('Actualizando cantidades de productos para venta: ${_ventaSeleccionada!['id']}');
      
      // Crear estructura de datos para enviar a la API
      final Map<String, dynamic> ventaData = {
        'productos': _ventaSeleccionada!['productos'].map((producto) {
          return {
            'id': producto['id'],
            'cantidad': producto['cantidad'],
            'precio': producto['precio'],
          };
        }).toList(),
        'total': _ventaSeleccionada!['total'],
      };
      
      // Actualizar la venta en la API
      await _ventasApi.updateVenta(_ventaSeleccionada!['id'], ventaData);
      
      DebugPrint.log('Cantidades de productos actualizadas correctamente');
      
    } catch (e) {
      DebugPrint.log('Error al actualizar cantidades de productos: $e');
      throw Exception('No se pudieron actualizar las cantidades de productos: $e');
    }
  }

  // Método para cancelar procesamiento de venta
  void _cancelarProcesamiento() {
    setState(() {
      _ventaSeleccionada = null;
      _montoIngresado = '';
      _nombreCliente = '';
      _tipoDocumento = 'Boleta';
      _procesandoPago = false;
    });
  }

  // Método para actualizar la cantidad de un producto
  void _actualizarCantidadProducto(Map<String, dynamic> venta, int index, int cambio) {
    setState(() {
      final producto = venta['productos'][index];
      final cantidadActual = producto['cantidad'] as int;
      final nuevaCantidad = cantidadActual + cambio;
      
      // Asegurar que la cantidad no sea menor que 1
      if (nuevaCantidad >= 1) {
        producto['cantidad'] = nuevaCantidad;
        
        // Recalcular el total de la venta usando la clase utilitaria
        venta['total'] = VentasUtils.calcularTotalVenta(venta['productos']);
        
        // Si hay una venta seleccionada, actualizarla también
        if (_ventaSeleccionada != null && _ventaSeleccionada!['id'] == venta['id']) {
          _ventaSeleccionada = Map<String, dynamic>.from(venta);
        }
        
        DebugPrint.log('Cantidad actualizada para ${producto['nombre']}: $nuevaCantidad');
        DebugPrint.log('Nuevo total de la venta: ${venta['total']}');
      }
    });
    
    // Forzar una actualización más explícita
    // Usamos una variable local para capturar el estado actual
    final ventaSeleccionadaActual = _ventaSeleccionada;
    
    if (mounted) {
      Future.delayed(Duration.zero, () {
        // Verificar si el widget sigue montado después del delay
        if (!mounted) return;
        
        // Forzar una reconstrucción completa del widget actual
        setState(() {});
        
        // Forzar reconstrucción del diálogo si está abierto
        if (ventaSeleccionadaActual != null && mounted) {
          // Verificar si el contexto es válido antes de usarlo
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
            _mostrarFormularioVenta(ventaSeleccionadaActual);
          }
        }
      });
    }
  }
  // Modificar la referencia a _formatearMonto para usar la clase utilitaria
  double _formatearMonto(double monto) {
    return VentasUtils.formatearMonto(monto);
  }

  // Widget para botones de cantidad
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Material(
      color: enabled ? const Color(0xFF2D2D2D) : Colors.grey.withOpacity(0.3),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoImpresion() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.print,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Imprimir Comprobante',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Desea imprimir el comprobante de venta?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _imprimirComprobante();
                  },
                  icon: const FaIcon(FontAwesomeIcons.print),
                  label: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const FaIcon(FontAwesomeIcons.xmark),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _imprimirComprobante() async {
    // Simular generación de PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF2D2D2D),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            SizedBox(height: 16),
            Text(
              'Generando comprobante...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // Simular tiempo de generación
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cerrar diálogo de carga
    Navigator.pop(context);

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comprobante generado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.cashRegister,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sistema de Ventas - ${widget.nombreSucursal}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: Row(
        children: [
          // Panel izquierdo: Ventas pendientes
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PendingSalesWidget(
                onSaleSelected: _seleccionarVenta,
                ventasPendientes: _ventasPendientes,
              ),
            ),
          ),
          
          // Panel derecho: Historial de ventas
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HISTORIAL DE VENTAS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _ventas.length,
                          itemBuilder: (context, index) {
                            final venta = _ventas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: const Color(0xFF2D2D2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.white,
                                iconColor: Colors.white,
                                title: Text(
                                  'Venta #${venta.id}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha: ${_formatDateTime(venta.fechaCreacion)}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    Text(
                                      'Estado: ${venta.estado}',
                                      style: TextStyle(
                                        color: venta.estado == EstadosVenta.completada
                                            ? Colors.green
                                            : venta.estado == EstadosVenta.anulada
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Total: S/ ${VentasUtils.formatearMontoTexto(venta.total)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Detalles de la Venta',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...venta.detalles.map((detalle) => ListTile(
                                          title: Text(
                                            'Producto #${detalle.productoId}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            'Cantidad: ${detalle.cantidad}',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                          trailing: Text(
                                            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )),
                                        const Divider(color: Colors.white24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Subtotal:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.subtotal.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'IGV:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.igv.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        if (venta.descuentoTotal != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Descuento:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'S/ ${venta.descuentoTotal!.toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              VentasUtils.formatearMontoTexto(venta.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                // TODO: Implementar generación de boleta
                                              },
                                              icon: const Icon(Icons.receipt),
                                              label: const Text('Generar Boleta'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2196F3),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                // TODO: Implementar generación de factura
                                              },
                                              icon: const Icon(Icons.description),
                                              label: const Text('Generar Factura'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF9C27B0),
                                              ),
                                            ),
                                            if (venta.estado != EstadosVenta.anulada)
                                              ElevatedButton.icon(
                                                onPressed: () => _anularVenta(venta),
                                                icon: const Icon(Icons.cancel),
                                                label: const Text('Anular'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFE31E24),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'No disponible';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
} 