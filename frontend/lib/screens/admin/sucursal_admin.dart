import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// La clase Sucursal ha sido reemplazada por la importación de '../../models/sucursal.model.dart'

// Clase para la solicitud de creación/actualización de sucursal
class SucursalRequest {
  final String nombre;
  final String direccion;
  final bool sucursalCentral;

  SucursalRequest({
    required this.nombre,
    required this.direccion,
    required this.sucursalCentral,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'direccion': direccion,
      'sucursalCentral': sucursalCentral,
    };
  }
}

class SucursalAdminScreen extends StatefulWidget {
  const SucursalAdminScreen({super.key});

  @override
  State<SucursalAdminScreen> createState() => _SucursalAdminScreenState();
}

class _SucursalAdminScreenState extends State<SucursalAdminScreen> {
  bool _isLoading = false;
  List<Sucursal> _sucursales = <Sucursal>[];
  String _errorMessage = '';
  List<Sucursal> _todasLasSucursales = <Sucursal>[];
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final List<Sucursal> sucursales = await api.sucursales.getSucursales();

      if (!mounted) {
        return;
      }
      setState(() {
        _todasLasSucursales = sucursales;
        _aplicarFiltroBusqueda();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Error al cargar sucursales: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _aplicarFiltroBusqueda() {
    if (_terminoBusqueda.isEmpty) {
      _sucursales = List.from(_todasLasSucursales);
      return;
    }

    final String termino = _terminoBusqueda.toLowerCase();
    _sucursales = _todasLasSucursales.where((Sucursal sucursal) {
      final bool nombreMatch = sucursal.nombre.toLowerCase().contains(termino);
      final bool direccionMatch = sucursal.direccion?.toLowerCase().contains(termino) ?? false;
      return nombreMatch || direccionMatch;
    }).toList();
  }

  Future<void> _guardarSucursal(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      final SucursalRequest request = SucursalRequest(
        nombre: data['nombre'],
        direccion: data['direccion'] ?? '',
        sucursalCentral: data['sucursalCentral'] ?? false,
      );

      if (data['id'] != null) {
        await api.sucursales
            .updateSucursal(data['id'].toString(), request.toJson());
      } else {
        await api.sucursales.createSucursal(request.toJson());
      }

      if (!mounted) {
        return;
      }
      
      await _cargarSucursales();
      
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sucursal guardada exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar sucursal: $e'),
          backgroundColor: const Color(0xFFE31E24),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSucursalDialog([Sucursal? sucursal]) {
    showDialog(
      context: context,
      builder: (BuildContext context) => SucursalFormDialog(
        sucursal: sucursal,
        onSave: _guardarSucursal,
      ),
    );
  }

  // Agrupar sucursales por tipo (central/no central)
  Map<String, List<Sucursal>> _agruparSucursales() {
    final Map<String, List<Sucursal>> grupos = <String, List<Sucursal>>{
      'centrales': <Sucursal>[],
      'noCentrales': <Sucursal>[],
    };

    for (final Sucursal sucursal in _sucursales) {
      if (sucursal.sucursalCentral) {
        grupos['centrales']!.add(sucursal);
      } else {
        grupos['noCentrales']!.add(sucursal);
      }
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Sucursal>> gruposSucursales = _agruparSucursales();
    final List<Sucursal> sucursalesCentrales = gruposSucursales['centrales'] ?? <Sucursal>[];
    final List<Sucursal> sucursalesNoCentrales = gruposSucursales['noCentrales'] ?? <Sucursal>[];
    final int totalSucursales = _sucursales.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Gestión de Sucursales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Administre las sucursales y locales de la empresa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: _cargarSucursales,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar nueva sucursal',
            onPressed: () => _showSucursalDialog(),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Encabezado con estadísticas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF212121),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar sucursal',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String value) {
                      setState(() {
                        _terminoBusqueda = value;
                        _aplicarFiltroBusqueda();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const FaIcon(
                        FontAwesomeIcons.buildingUser,
                        color: Color(0xFFE31E24),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: $totalSucursales sucursales',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading && _sucursales.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando sucursales...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.circleExclamation,
                              color: Color(0xFFE31E24),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _cargarSucursales,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _sucursales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const FaIcon(
                                  FontAwesomeIcons.building,
                                  color: Colors.white24,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _terminoBusqueda.isEmpty
                                      ? 'No hay sucursales para mostrar'
                                      : 'No se encontraron sucursales con "$_terminoBusqueda"',
                                  style: const TextStyle(color: Colors.white54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                if (_terminoBusqueda.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _terminoBusqueda = '';
                                        _aplicarFiltroBusqueda();
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Limpiar búsqueda'),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE31E24),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _showSucursalDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Agregar sucursal'),
                                  ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Sucursales Centrales
                                if (sucursalesCentrales.isNotEmpty) ...<Widget>[
                                  Container(
                                    color: const Color(0xFF2D2D2D),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    child: Row(
                                      children: <Widget>[
                                        const FaIcon(
                                          FontAwesomeIcons.building,
                                          color: Color(0xFFE31E24),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sucursales Centrales (${sucursalesCentrales.length})',
                                          style: const TextStyle(
                                            color: Color(0xFFE31E24),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...sucursalesCentrales.map((Sucursal sucursal) =>
                                      _buildSucursalRow(sucursal)),
                                ],

                                // Sucursales No Centrales
                                if (sucursalesNoCentrales.isNotEmpty) ...<Widget>[
                                  Container(
                                    color: const Color(0xFF2D2D2D),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    child: Row(
                                      children: <Widget>[
                                        const FaIcon(
                                          FontAwesomeIcons.store,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sucursales (${sucursalesNoCentrales.length})',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...sucursalesNoCentrales.map((Sucursal sucursal) =>
                                      _buildSucursalRow(sucursal)),
                                ],
                              ],
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE31E24),
        foregroundColor: Colors.white,
        onPressed: () => _showSucursalDialog(),
        tooltip: 'Agregar sucursal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSucursalRow(Sucursal sucursal) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: ListTile(
        title: Text(
          sucursal.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          sucursal.direccion ?? 'Sin dirección registrada',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontStyle: sucursal.direccion != null ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sucursal.sucursalCentral
                    ? const Color(0xFFE31E24).withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sucursal.sucursalCentral ? 'Central' : 'Local',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sucursal.sucursalCentral
                      ? const Color(0xFFE31E24)
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.penToSquare,
                color: Colors.white70,
                size: 18,
              ),
              tooltip: 'Editar sucursal',
              onPressed: () => _showSucursalDialog(sucursal),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Eliminar sucursal',
              onPressed: () => _confirmarEliminarSucursal(sucursal),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarSucursal(Sucursal sucursal) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de eliminar la sucursal "${sucursal.nombre}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (confirm == true) {
      try {
        await api.sucursales.deleteSucursal(sucursal.id.toString());
        await _cargarSucursales();
        
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sucursal "${sucursal.nombre}" eliminada correctamente'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar sucursal: $e'),
            backgroundColor: const Color(0xFFE31E24),
          ),
        );
      }
    }
  }
}

class SucursalFormDialog extends StatefulWidget {
  final Sucursal? sucursal;
  final Function(Map<String, dynamic>) onSave;

  const SucursalFormDialog({
    super.key,
    this.sucursal,
    required this.onSave,
  });

  @override
  State<SucursalFormDialog> createState() => _SucursalFormDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal?>('sucursal', sucursal))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has('onSave', onSave));
  }
}

class _SucursalFormDialogState extends State<SucursalFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  bool _sucursalCentral = false;

  @override
  void initState() {
    super.initState();
    if (widget.sucursal != null) {
      _nombreController.text = widget.sucursal!.nombre;
      _direccionController.text = widget.sucursal!.direccion ?? '';
      _sucursalCentral = widget.sucursal!.sucursalCentral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esNuevaSucursal = widget.sucursal == null;

    return AlertDialog(
      title: Text(
        esNuevaSucursal ? 'Nueva Sucursal' : 'Editar Sucursal',
        style: const TextStyle(
          color: Color(0xFFE31E24),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Sucursal Principal',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Ej: Av. Principal 123',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Sucursal Central'),
                subtitle: const Text(
                    'Las sucursales centrales tienen permisos especiales'),
                value: _sucursalCentral,
                activeColor: const Color(0xFFE31E24),
                onChanged: (bool value) => setState(() => _sucursalCentral = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final Map<String, Object> data = <String, Object>{
                if (widget.sucursal != null) 'id': widget.sucursal!.id,
                'nombre': _nombreController.text,
                'direccion': _direccionController.text,
                'sucursalCentral': _sucursalCentral,
              };
              widget.onSave(data);
              Navigator.pop(context);
            }
          },
          icon: Icon(esNuevaSucursal ? Icons.add : Icons.save),
          label: Text(esNuevaSucursal ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
