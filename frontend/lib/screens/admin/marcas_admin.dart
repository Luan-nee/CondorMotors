import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/marca.model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MarcasAdminScreen extends StatefulWidget {
  const MarcasAdminScreen({super.key});

  @override
  State<MarcasAdminScreen> createState() => _MarcasAdminScreenState();
}

class _MarcasAdminScreenState extends State<MarcasAdminScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  List<Marca> _marcas = <Marca>[];
  Map<int, int> _productosPorMarca = <int, int>{};

  @override
  void initState() {
    super.initState();
    _cargarMarcas();
  }

  Future<void> _cargarMarcas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Obtenemos las marcas directamente como objetos Marca
      final List<Marca> marcas = await api.marcas.getMarcas();

      // Crear mapa de totalProductos usando el valor real que viene en el modelo
      final Map<int, int> tempProductosPorMarca = <int, int>{};
      for (Marca marca in marcas) {
        tempProductosPorMarca[marca.id] = marca.totalProductos;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _marcas = marcas;
        _productosPorMarca = tempProductosPorMarca;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar marcas: $e';
      });

      // Manejar errores de autenticación
      if (e is ApiException && e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        await Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _guardarMarca([Marca? marca]) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final Map<String, String> marcaData = <String, String>{
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
      };

      if (marca != null) {
        // Actualizar marca existente
        await api.marcas.updateMarca(marca.id.toString(), marcaData);
      } else {
        // Crear nueva marca
        await api.marcas.createMarca(marcaData);
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(marca == null
              ? 'Marca creada correctamente'
              : 'Marca actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarMarcas(); // Recargar la lista
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar marca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarFormularioMarca([Marca? marca]) {
    _nombreController.text = marca?.nombre ?? '';
    _descripcionController.text = marca?.descripcion ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.trademark,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      marca == null ? 'Crear nueva marca' : 'Editar marca',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la marca',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading ? null : () => _guardarMarca(marca),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.tags,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'marcas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.plus,
                      size: 16, color: Colors.white),
                  label: const Text('Nueva Marca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed:
                      _isLoading ? null : () => _mostrarFormularioMarca(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tabla de marcas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE31E24),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _cargarMarcas,
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          )
                        : _marcas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay marcas registradas',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    // Encabezado de la tabla
                                    Container(
                                      color: const Color(0xFF2D2D2D),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 20),
                                      child: const Row(
                                        children: <Widget>[
                                          // Marca (35% del ancho)
                                          Expanded(
                                            flex: 35,
                                            child: Text(
                                              'Marca',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Descripción (45% del ancho)
                                          Expanded(
                                            flex: 45,
                                            child: Text(
                                              'Descripción',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Cant. de productos (10% del ancho)
                                          Expanded(
                                            flex: 10,
                                            child: Text(
                                              'Productos',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Acciones (10% del ancho)
                                          Expanded(
                                            flex: 10,
                                            child: Text(
                                              'Acciones',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Filas de marcas
                                    ..._marcas.map((Marca marca) => Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                          child: Row(
                                            children: <Widget>[
                                              // Marca
                                              Expanded(
                                                flex: 35,
                                                child: Row(
                                                  children: <Widget>[
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF2D2D2D),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Center(
                                                        child: FaIcon(
                                                          FontAwesomeIcons.tag,
                                                          color:
                                                              Color(0xFFE31E24),
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      marca.nombre,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Descripción
                                              Expanded(
                                                flex: 45,
                                                child: Text(
                                                  marca.descripcion ??
                                                      'Sin descripción',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              // Cant. de productos
                                              Expanded(
                                                flex: 10,
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFE31E24)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      _productosPorMarca[
                                                                  marca.id]
                                                              ?.toString() ??
                                                          '0',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFE31E24),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Acciones
                                              Expanded(
                                                flex: 10,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    IconButton(
                                                      icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .penToSquare,
                                                        color: Colors.white54,
                                                        size: 16,
                                                      ),
                                                      onPressed: () =>
                                                          _mostrarFormularioMarca(
                                                              marca),
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 30,
                                                        minHeight: 30,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
