# Crear venta

## Método: POST

## Endpoint

{{base_url}}/api/{{sucursalId}}/ventas

## Explicación de los permisos

El rol `administrador` es capaz de crear una venta en cualquier sucursal
El rol `vendedor` es capaz de crear ventas pero solo en la sucursal a la que pertenece
El rol `computadora` es capaz de crear ventas pero solo en la sucursal a la que pertenece

## Request

### Body (request)

```json
{
  "observaciones": "Observaciones acerca de la venta", // opcional
  "tipoDocumentoId": 6,
  "detalles": [
    // Cada item puede ser un producto existente:
    // Para ser considerado como producto existente la propiedad productoId debe tener un valor
    {
      "productoId": 335,
      "cantidad": 4,
      "tipoTaxId": 30,
      "aplicarOferta": false
    },
    {
      "productoId": 68,
      "cantidad": 1,
      "tipoTaxId": 8,
      "aplicarOferta": true
    },
    // También se pueden incluir productos que no existen
    // Para ser considerados como producto no existente la propiedad productoId debe ser null
    {
      "productoId": null,
      "cantidad": 4,
      "tipoTaxId": 7,
      "nombre": "Producto especial",
      "precio": 100
    },
    {
      "productoId": null,
      "cantidad": 10,
      "tipoTaxId": 9,
      "nombre": "Producto especial 2",
      "precio": 100
    }
  ],
  "clienteId": 12,
  "empleadoId": 28,
  "fechaEmision": "2025-03-25", // opcional
  "horaEmision": "16:57:42" // opcional
}
```

## Response (success 200)

### Body (success 200 response)

```json
{
  "status": "success",
  "data": {
    "id": 20 // Id de la venta creada
  }
}
```

## Response (fail 400)

### Body (fail 400 response)

```json
{
  "status": "fail",
  "error": "El tipo de documento que intentó asignar no existe" // el mensaje de error varía dependiendo del tipo de error
}
```
