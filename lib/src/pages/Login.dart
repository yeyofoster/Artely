import 'package:firebase_auth/firebase_auth.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Class/ArtelyColors.dart';
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
  Future loggin;

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
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/img/background.png',
                  height: maxHeight,
                  width: maxWidth,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: maxHeight * 0.24,
                left: maxWidth * 0.07,
                child: Text(
                  'Iniciar sesión',
                  style: GoogleFonts.montserrat(
                      fontSize: 34, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                top: maxHeight * 0.37,
                child: Container(
                  width: maxWidth,
                  child: getFormulario(maxHeight, maxWidth),
                ),
              ),
              Positioned(
                left: maxWidth * 0.64,
                top: maxHeight * 0.05,
                child: SvgPicture.asset(
                  'assets/svg/ballena.svg',
                  width: maxWidth * 0.35,
                ),
              ),
            ],
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
          vertical: maxHeight * 0.01,
          horizontal: maxWidth * 0.05,
        ),
        child: Column(
          children: <Widget>[
            _txtCorreo(),
            SizedBox(
              height: 25.0,
            ),
            _txtContrasenia(),
            // SizedBox(
            //   height: 10.0,
            // ),
            _recuperarContrasenia(maxHeight, maxWidth),
            SizedBox(
              height: maxHeight * 0.03,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: MaterialButton(
                child: Text(
                  'Ingresar',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black87,
                  ),
                ),
                color: ArtelyColors.teal,
                minWidth: maxWidth * 0.5,
                height: 50.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                onPressed: () {
                  setState(() {
                    loggin = loggeaUsuario();
                    validaLogin(context);
                  });
                },
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '¿No tienes cuenta? ',
                  style: TextStyle(
                    color: Colors.blueGrey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 16.3,
                  ),
                ),
                FlatButton(
                  padding: EdgeInsets.all(0.0),
                  onPressed: () {
                    Navigator.pushNamed(context, 'registro');
                  },
                  child: Text(
                    '¡Registrate aquí!',
                    style: TextStyle(
                      color: ArtelyColors.blackArtely,
                      fontWeight: FontWeight.w500,
                      fontSize: 16.3,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            )
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
          borderSide: BorderSide(),
        ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
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
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
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
  void validaLogin(BuildContext context) {
    if (_formKey.currentState.validate()) {
      VentanaEmergente ventanaCarga = VentanaEmergente(
        height: MediaQuery.of(context).size.height * 0.3,
        closeButton: false,
        contenido: FutureBuilder(
          future: loggin,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data.runtimeType == AuthResult) {
                AuthResult result = snapshot.data;
                PreferenciasUsuario preferencias = new PreferenciasUsuario();
                preferencias.userID = result.user.uid;
                Future.microtask(
                    () => Navigator.of(context).popAndPushNamed('mapa'));
                return Container();
                // if (result.user.isEmailVerified) {
                // PreferenciasUsuario preferencias = new PreferenciasUsuario();
                // preferencias.userID = result.user.uid;
                // Future.microtask(
                //     () => Navigator.of(context).popAndPushNamed('mapa'));
                // return Container();
                // } else {
                //   return Container(
                //     height: MediaQuery.of(context).size.height * 0.25,
                //     child: Column(
                //       children: <Widget>[
                //         Padding(
                //           padding: const EdgeInsets.symmetric(vertical: 20.0),
                //           child: Text(
                //             'ERROR',
                //             style: GoogleFonts.manrope(
                //               letterSpacing: 2.0,
                //               fontWeight: FontWeight.w600,
                //               fontSize: 20.0,
                //             ),
                //           ),
                //         ),
                //         Container(
                //           width: MediaQuery.of(context).size.width * 0.18,
                //           height: MediaQuery.of(context).size.width * 0.18,
                //           child: FlareActor(
                //             'assets/flare/error_x.flr',
                //             animation: 'error',
                //           ),
                //         ),
                //         Text(
                //           'Necesitas verificar tu email para ingresar',
                //           style: GoogleFonts.openSans(color: Colors.blueGrey),
                //           textAlign: TextAlign.center,
                //         ),
                //       ],
                //     ),
                //   );
                // }
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
                    errormessage =
                        "Demasiados intentos consecutivos. Intente de nuevo en 2 minutos.";
                    break;
                  case "ERROR_OPERATION_NOT_ALLOWED":
                    errormessage = "No está habilitado este tipo de login.";
                    break;
                  case "ERROR_NETWORK_REQUEST_FAILED":
                    errormessage = "No cuenta con conexión a Internet.";
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
                      Container(
                        width: MediaQuery.of(context).size.width * 0.18,
                        height: MediaQuery.of(context).size.width * 0.18,
                        child: FlareActor(
                          'assets/flare/error_x.flr',
                          animation: 'error',
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

  Widget _recuperarContrasenia(double maxHeight, double maxWidth) {
    return Align(
      alignment: Alignment.centerRight,
      child: FlatButton(
        child: Text(
          'Olvidé mi contraseña',
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.w500,
            fontSize: 15.0,
          ),
        ),
        padding: EdgeInsets.all(0.0),
        onPressed: () {
          TextEditingController _txtEmail = TextEditingController();
          final _formEmailKey = GlobalKey<FormState>();
          VentanaEmergente ventanaContrasena = VentanaEmergente(
            height: maxHeight * 0.35,
            titulo: 'Recuperar contraseña',
            closeButton: false,
            backgroundColorTitulo: ArtelyColors.mediumSeaGreen,
            contenido: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(
                    'Ingrese su correo electrónico',
                    style: GoogleFonts.roboto(
                        fontSize: 17.0, color: Colors.blueGrey),
                  ),
                  Form(
                    key: _formEmailKey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: maxWidth * 0.05),
                          child: TextFormField(
                            controller: _txtEmail,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
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
                          ),
                        ),
                        MaterialButton(
                          child: Text(
                            'Recuperar',
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black87,
                            ),
                          ),
                          color: ArtelyColors.mediumSeaGreen,
                          minWidth: maxWidth * 0.5,
                          height: 45.0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          onPressed: () {
                            if (_formEmailKey.currentState.validate()) {
                              Navigator.of(context).pop();
                              Future emailRequest =
                                  enviarEmailContrasenia(_txtEmail.text);
                              VentanaEmergente ventanaEmailContra =
                                  VentanaEmergente(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                closeButton: false,
                                contenido: FutureBuilder(
                                  future: emailRequest,
                                  builder: (BuildContext context,
                                      AsyncSnapshot snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      if (snapshot.data.runtimeType ==
                                          PlatformException) {
                                        String errormessage;
                                        PlatformException error = snapshot.data;
                                        switch (error.code) {
                                          case "ERROR_USER_NOT_FOUND":
                                            errormessage =
                                                "No existe ningún usuario registrado con ese correo.";
                                            break;
                                          case "ERROR_USER_DISABLED":
                                            errormessage =
                                                "Este usuario ha sido deshabilitado.";
                                            break;
                                          case "ERROR_TOO_MANY_REQUESTS":
                                            errormessage =
                                                "Demasiados intentos consecutivos. Intente de nuevo en 2 minutos.";
                                            break;
                                          case "ERROR_NETWORK_REQUEST_FAILED":
                                            errormessage =
                                                "No cuenta con conexión a Internet.";
                                            break;
                                          default:
                                            errormessage =
                                                "Error desconocido. Intente más tarde.";
                                        }
                                        return Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.25,
                                          child: Column(
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20.0),
                                                child: Text(
                                                  'ERROR',
                                                  style: GoogleFonts.manrope(
                                                    letterSpacing: 2.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.18,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.18,
                                                child: FlareActor(
                                                  'assets/flare/error_x.flr',
                                                  animation: 'error',
                                                ),
                                              ),
                                              Text(
                                                errormessage,
                                                style: GoogleFonts.openSans(
                                                    color: Colors.blueGrey),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        return SingleChildScrollView(
                                          child: Column(
                                            children: <Widget>[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 5.0,
                                                ),
                                                child: Text(
                                                  'Correo enviado',
                                                  style: GoogleFonts.manrope(
                                                    letterSpacing: 2.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.18,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.18,
                                                child: FlareActor(
                                                  'assets/flare/check.flr',
                                                  animation: 'checked',
                                                ),
                                              ),
                                              Text(
                                                'Se ha enviado un correo a ${_txtEmail.text} para reestablecer la contraseña',
                                                style: GoogleFonts.openSans(
                                                    color: Colors.blueGrey),
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
                              ventanaEmailContra.mostrarVentana(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          ventanaContrasena.mostrarVentana(context);
        },
      ),
    );
  }

  Future enviarEmailContrasenia(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return 0;
    } catch (errorContra) {
      print('Error al enviar correo para recuperar contraseña: $errorContra');
      return errorContra;
    }
  }
}
