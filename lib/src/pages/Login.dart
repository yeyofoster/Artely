import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController correoController = TextEditingController();
  final TextEditingController contraController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool invisible;
  Widget iconVisible;

  @override
  void initState() {
    super.initState();
    invisible = true;
    iconVisible = Icon(Icons.visibility_off, color: Colors.blueGrey);
  }

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
                  _txtCorreo(),
                  SizedBox(
                    height: 25.0,
                  ),
                  _txtContrasenia(),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: InkWell(
                      child: Text(
                        '¿No tienes una cuenta? Registrate aquí!',
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, 'registro');
                      },
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

  Widget _txtContrasenia() {
    return TextFormField(
      controller: contraController,
      obscureText: invisible,
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
        return 'Se necesita al menos un caracter especial, \nmayuscula, numero y minuscula en la contraseña';
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        hintText: 'Contraseña',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: IconButton(
          icon: iconVisible,
          onPressed: () {
            if (invisible) {
              setState(() {
                invisible = false;
                iconVisible = Icon(Icons.visibility, color: Colors.blue);
                print('Ahora soy visible: $invisible');
              });
            } else {
              setState(() {
                invisible = true;
                iconVisible =
                    Icon(Icons.visibility_off, color: Colors.blueGrey);
                print('Ahora soy invisible: $invisible');
              });
            }
          },
        ),
      ),
    );
  }

  Widget _txtCorreo() {
    return TextFormField(
      controller: correoController,
      keyboardType: TextInputType.emailAddress,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta correo';
        } else if (input.isNotEmpty) {
          RegExp correoRegExp =
              RegExp(r'^([a-zA-Z0-9_\-\.]+)@[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+$');
          if (correoRegExp.hasMatch(input)) {
            return null;
          }
        }
        return 'El correo no tiene un formato valido';
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        hintText: 'Correo electrónico',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: Icon(
          Icons.email,
          color: Colors.blue,
        ),
      ),
    );
  }

  Future<void> validaLogin(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      try {
        FirebaseAuth auth = FirebaseAuth.instance;
        AuthResult result = await auth.signInWithEmailAndPassword(
            email: correoController.text, password: contraController.text);
        FirebaseUser user = result.user;
        if (user != null) {
          Navigator.pushNamed(context, 'mapa');
          PreferenciasUsuario preferencias = new PreferenciasUsuario();
          preferencias.userID = user.uid;
          print(
              'Se ha guardado el user ID en las preferencias: ${preferencias.userID}');
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
