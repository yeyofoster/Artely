import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  final txtCorreo = TextEditingController();
  final txtContra = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final maxHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Colors.blue[200],
                Colors.blue[50],
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              stops: [0.1, 0.6],
              tileMode: TileMode.clamp),
        ),
        padding: EdgeInsets.symmetric(
          vertical: maxHeight * 0.08,
          horizontal: maxWidth * 0.04,
        ),
        //color: Colors.yellow[100],
        child: ListView(
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.person_pin,
                    color: Colors.blue,
                    size: 250.0,
                  ),
                  TextFormField(
                    validator: (input) {
                      if (input.isEmpty) {
                        return 'Falta correo';
                      } else if (input.isNotEmpty) {
                        RegExp correoRegExp = RegExp(
                            r'^([a-zA-Z0-9_\-\.]+)@[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+$');
                        if (correoRegExp.hasMatch(input)) {
                          return null;
                        }
                      }
                      return 'El correo no tiene un formato valido';
                    },
                    controller: txtCorreo,
                    decoration: InputDecoration(
                      hintText: 'Correo/Telefono',
                      suffixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 25.0,
                  ),
                  TextFormField(
                    validator: (input) {
                      if (input.isEmpty) {
                        return 'Falta contraseña';
                      } else if (input.isNotEmpty) {
                        if (input.length <= 8) {
                          return 'La contraseña debe ser mayor a 8 caracteres';
                        } else {
                          RegExp contraRegExp = RegExp(
                              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])');
                          if (contraRegExp.hasMatch(input)) {
                            return null;
                          }
                        }
                      }
                      return 'Se necesita al menos un caracter especial, mayuscula, numero y minuscula en la contraseña';
                    },
                    controller: txtContra,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      suffixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: InkWell(
                      child: Text('¿No tienes una cuenta? Registrate aquì!'),
                      onTap: () => Navigator.pushNamed(context, 'registro'),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.height * 0.50,
                    height: 50.0,
                    child: FlatButton(
                      onPressed: () => validaLogin(context),
                      color: Colors.blue,
                      textTheme: ButtonTextTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text('Ingresar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> validaLogin(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      try {
        FirebaseAuth auth = FirebaseAuth.instance;
        AuthResult result = await auth.signInWithEmailAndPassword(
            email: txtCorreo.text, password: txtContra.text);
        FirebaseUser user = result.user;
        if (user != null) {
          Navigator.pushNamed(context, 'mapa');
        } else {
          print('No se encontró al usuario');
        }
      } catch (error) {
        String errormessage;
        switch (error.code) {
          case "ERROR_INVALID_EMAIL":
            errormessage = "Su correo no tiene un formato valido.";
            break;
          case "ERROR_WRONG_PASSWORD":
            errormessage = "Su contraseña está mal.";
            break;
          case "ERROR_USER_NOT_FOUND":
            errormessage =
                "No existe ningún usuario registrado con ese correo.";
            break;
          case "ERROR_USER_DISABLED":
            errormessage = "Este usuario ha sido deshabilitado.";
            break;
          case "ERROR_TOO_MANY_REQUESTS":
            errormessage = "Error. Intente más tarde.";
            break;
          case "ERROR_OPERATION_NOT_ALLOWED":
            errormessage = "No está habilitado este tipo de login.";
            break;
          default:
            errormessage = "Error desconocido";
        }
        mostrarAlerta(context, 'Error', errormessage);
      }
    }
  }

  void mostrarAlerta(BuildContext context, String titulo, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(mensaje),
              SizedBox(
                height: 15.0,
              ),
              FlutterLogo(
                size: 70.0,
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
