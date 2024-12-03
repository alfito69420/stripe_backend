import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:stripe/stripe.dart';

void main() async {
  // Configura la clave secreta de Stripe
  final stripe = Stripe(
      'sk_test_51QRMHTBUKCGrTpw3MRJIFqXFq3VcbOmu9nZQ5lM1O64zfk1DlxLbIjxLIjno53WtOicKMF1WUZrDuR0U7G7vkEnq00ABNY588y');

  // Define las rutas del backend
  final router = Router()
    ..post('/create-payment-intent', (Request request) async {
      // Lee el cuerpo de la solicitud
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final amount = data['amount']; // Monto en centavos
      final currency = data['currency'];

      try {
        // Crea el Payment Intent
        final paymentIntent = await stripe.paymentIntent.create(
          CreatePaymentIntentRequest(
            amount: amount,
            currency: currency,
            paymentMethodTypes: {
              PaymentMethodType.card
            }, // Métodos de pago permitidos
          ),
        );

        return Response.ok(jsonEncode(paymentIntent));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}));
      }
    });

  // Inicia el servidor
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Servidor iniciado en http://${InternetAddress.anyIPv4}:8080');
}
