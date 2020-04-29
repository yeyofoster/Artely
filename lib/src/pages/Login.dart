import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';

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
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            width: maxWidth,
            height: maxHeight,
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
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: maxHeight * 0.08),
                    child: Icon(
                      Icons.person_pin,
                      color: Colors.blue,
                      size: 250.0,
                    ),
                  ),
                  getFormulario(maxHeight, maxWidth),
                ],
              ),
              // child: Form(
              //   key: _formKey,
              //   child:
              //       Container(
              //         width: MediaQuery.of(context).size.height * 0.50,
              //         height: 50.0,
              //         child: FlatButton(
              //           onPressed: () => validaLogin(context),
              //           color: Colors.blue,
              //           textTheme: ButtonTextTheme.primary,
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(20.0),
              //           ),
              //           child: Text('Ingresar'),
              //         ),
              //       ),

              // ),
            ),
          ),
        ),
      ),
    );
  }

//Método que regresa el widget de formulario.
  Widget getFormulario(double maxHeight, double maxWidth) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: maxHeight * 0.01, horizontal: maxWidth * 0.05),
        child: Column(
          children: <Widget>[
            _txtCorreo(),
            SizedBox(
              height: 25.0,
            ),
            _txtContrasenia(),
            SizedBox(
              height: 25.0,
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.blueGrey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                ),
                children: [
                  TextSpan(text: '¿No tienes una cuenta? '),
                  TextSpan(
                    text: 'Registrate aquí',
                    style: TextStyle(color: Colors.blue),
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, 'registro');
                      },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 25.0,
            ),
            MaterialButton(
              child: Text(
                'Ingresar',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black87,
                ),
              ),
              color: Colors.blue[300],
              minWidth: maxWidth,
              height: 50.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              onPressed: () => validaLogin(context),
            ),
          ],
        ),
      ),
    );
  }

  //Método que regresa el input de la contraseña.
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
              });
            } else {
              setState(() {
                invisible = true;
                iconVisible =
                    Icon(Icons.visibility_off, color: Colors.blueGrey);
              });
            }
          },
        ),
      ),
    );
  }

  //Método que regresa el input del correo
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

  //Método que valida el login
  Future<void> validaLogin(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      VentanaEmergente ventanaCarga = VentanaEmergente(
        height: MediaQuery.of(context).size.height * 0.25,
        contenido: FutureBuilder(
          future: loggeaUsuario(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data.runtimeType == AuthResult) {
                AuthResult result = snapshot.data;
                PreferenciasUsuario preferencias = new PreferenciasUsuario();
                preferencias.userID = result.user.uid;
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('mapa');
                return null;
              } else {
                String errormessage;
                PlatformException error = snapshot.data;
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
                    errormessage = "Demasiados intentos consecutivos. Intente de nuevo en 2 minutos.";
                    break;
                  case "ERROR_OPERATION_NOT_ALLOWED":
                    errormessage = "No está habilitado este tipo de login.";
                    break;
                  default:
                    errormessage = "Error desconocido";
                }
                return Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'ERROR',
                          style: GoogleFonts.manrope(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w600,
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Icon(
                          Icons.cancel,
                          color: Colors.red[400],
                          size: 50.0,
                        ),
                      ),
                      Text(
                        errormessage,
                        style: GoogleFonts.openSans(color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
            } else {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      );
      ventanaCarga.mostrarVentana(context);
    }
  }

  Future loggeaUsuario() async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: correoController.text, password: contraController.text);
    } catch (error) {
      return error;
    }
  }
}
