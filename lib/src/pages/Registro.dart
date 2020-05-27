import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Class/ArtelyColors.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';

class PantallaRegistro extends StatefulWidget {
  @override
  _PantallaRegistroState createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _nombreController = TextEditingController();
  TextEditingController _apellidoController = TextEditingController();
  TextEditingController _correoController = TextEditingController();
  TextEditingController _contraController = TextEditingController();
  TextEditingController _telController = TextEditingController();
  bool _invisible;
  Widget _iconVisible;

  @override
  void initState() {
    super.initState();
    _invisible = true;
    _iconVisible = Icon(Icons.visibility_off, color: Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
    double _maxHeight = MediaQuery.of(context).size.height;
    double _maxWidth = MediaQuery.of(context).size.width;
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
                  height: _maxHeight,
                  width: _maxWidth,
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: _maxHeight * 0.15,
                left: _maxWidth * 0.07,
                child: Text(
                  'Registro',
                  style: GoogleFonts.montserrat(
                      fontSize: 34, fontWeight: FontWeight.w600),
                ),
              ),
              Positioned(
                top: _maxHeight * 0.22,
                child: Container(
                  width: _maxWidth,
                  child: _getFormulario(_maxHeight, _maxWidth),
                ),
              ),
              Positioned(
                left: _maxWidth * 0.64,
                top: _maxHeight * 0.05,
                child: SvgPicture.asset(
                  'assets/svg/ballena.svg',
                  width: _maxWidth * 0.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFormulario(double _maxHeight, double _maxWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _maxHeight * 0.01,
        horizontal: _maxWidth * 0.09,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _txtNombre(),
            SizedBox(
              height: _maxHeight * 0.02,
            ),
            _txApellido(),
            SizedBox(
              height: _maxHeight * 0.02,
            ),
            _txtCorreo(),
            SizedBox(
              height: _maxHeight * 0.02,
            ),
            _txtTelefono(),
            SizedBox(
              height: _maxHeight * 0.02,
            ),
            _txtContrasenia(),
            SizedBox(
              height: _maxHeight * 0.05,
            ),
            _botonFormulario(),
          ],
        ),
      ),
    );
  }

  //Método que regresa el input para el nombre.
  Widget _txtNombre() {
    return TextFormField(
      controller: _nombreController,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta ingresar un nombre';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
        ),
        hintText: 'Nombre',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: Icon(
          Icons.person,
          color: Colors.blue,
        ),
      ),
    );
  }

  //Método que regresa el input para el apellido.
  Widget _txApellido() {
    return TextFormField(
      controller: _apellidoController,
      textCapitalization: TextCapitalization.words,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta ingresar apellido';
        }
        return null;
      },
      decoration: InputDecoration(
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
        ),
        hintText: 'Primer Apellido',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: Icon(
          Icons.person,
          color: Colors.blue,
        ),
      ),
    );
  }

  //Método que regresa el input para el correo.
  Widget _txtCorreo() {
    return TextFormField(
      controller: _correoController,
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
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
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

  //Método que regresa el input para el telefono.
  Widget _txtTelefono() {
    return TextFormField(
      controller: _telController,
      validator: (input) {
        if (input.isEmpty) {
          _telController.text = '0';
        }
        return null;
      },
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
        ),
        hintText: 'Teléfono (Opcional)',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: Icon(
          Icons.phone,
          color: Colors.blue,
        ),
      ),
    );
  }

  //Método que regresa el input para la contraseña.
  Widget _txtContrasenia() {
    return TextFormField(
      controller: _contraController,
      obscureText: _invisible,
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
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.7),
        ),
        hintText: 'Contraseña',
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        suffixIcon: IconButton(
          icon: _iconVisible,
          onPressed: () {
            if (_invisible) {
              setState(() {
                _invisible = false;
                _iconVisible = Icon(Icons.visibility, color: Colors.blue);
              });
            } else {
              setState(() {
                _invisible = true;
                _iconVisible =
                    Icon(Icons.visibility_off, color: Colors.blueGrey);
              });
            }
          },
        ),
      ),
    );
  }

  //Método que regresa el botón del formulario.
  Widget _botonFormulario() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      child: FlatButton(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        color: ArtelyColors.darkSeaGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(20.0),
        ),
        onPressed: _enviarDatos,
        child: Text('Enviar'),
      ),
    );
  }

  //Método que muestra ventana de carga y manda a llamar los métodos para crear el usuario.
  void _enviarDatos() async {
    if (_formKey.currentState.validate()) {
      VentanaEmergente ventanaCarga = VentanaEmergente(
        height: MediaQuery.of(context).size.height * 0.35,
        closeButton: false,
        contenido: FutureBuilder(
          future: autenticaUsuario(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data.runtimeType == AuthResult) {
                AuthResult authRes = snapshot.data;
                registraUsuario(authRes.user);
                return Container(
                  height: MediaQuery.of(context).size.height * 0.33,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            '¡Bienvenido!',
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
                            'assets/flare/check.flr',
                            animation: 'checked',
                          ),
                        ),
                        Text(
                          'Usuario creado exitosamente. Verifica tu email para iniciar sesión',
                          style: GoogleFonts.openSans(color: Colors.blueGrey),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15.0,
                          ),
                          child: MaterialButton(
                            color: Colors.green[400],
                            minWidth: MediaQuery.of(context).size.width * 0.6,
                            child: Text('Iniciar sesión'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                String errormessage;
                PlatformException error = snapshot.data;
                switch (error.code) {
                  case "ERROR_EMAIL_ALREADY_IN_USE":
                    errormessage =
                        "Ya existe un usuario registrado con ese correo";
                    break;
                  case "ERROR_NETWORK_REQUEST_FAILED":
                    errormessage = "No cuenta con conexión a Internet.";
                    break;
                  default:
                    errormessage = "Error desconocido. Intente más tarde";
                }
                print(errormessage);
                return Container(
                  height: MediaQuery.of(context).size.height * 0.3,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                        ),
                        child: MaterialButton(
                          color: Colors.red[400],
                          minWidth: MediaQuery.of(context).size.width * 0.6,
                          child: Text('Continuar'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
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

  //Método que intenta autenticar un nuevo usuario. Si ya existe ee correo retorna el error.
  Future autenticaUsuario() async {
    try {
      AuthResult res =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text,
        password: _contraController.text,
      );
      print('Resultado: $res');
      print('El usuario es: ${res.user.displayName}');
      if (res.user != null) {
        print('Mandando correo');
        res.user.sendEmailVerification();
      }
      return res;
    } catch (error) {
      print(error);
      return error;
    }
  }

  //Método que guarda los datos del usuario en Firestore.
  Future<void> registraUsuario(FirebaseUser user) async {
    try {
      final dbFire = Firestore.instance;

      Map<String, dynamic> registro = {
        'En_viaje': false,
        'Nombre': _nombreController.text,
        'PApellido': _apellidoController.text,
        'Correo': _correoController.text,
        'Telefono': int.parse(_telController.text),
        'Viaje': null
      };
      await dbFire.collection('Artely_BD').document(user.uid).setData(registro);
    } catch (e) {
      print(e.code);
    }
  }
}
