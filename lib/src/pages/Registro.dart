import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantallaRegistro extends StatefulWidget {
  @override
  _PantallaRegistroState createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nombreController = TextEditingController();
  TextEditingController apellidoController = TextEditingController();
  TextEditingController correoController = TextEditingController();
  TextEditingController contraController = TextEditingController();
  TextEditingController telController = TextEditingController();
  bool invisible;
  Widget iconVisible;
  //String nombre, ap, correo, contrasenia, tel;

  @override
  void initState() {
    super.initState();
    invisible = true;
    iconVisible = Icon(Icons.visibility_off, color: Colors.blueGrey);
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Form(
            key: _formKey,
            child: Container(
              padding: EdgeInsets.only(top: 70.0, left: 20.0, right: 20.0),
              child: Container(
                child: ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        _txtNombre(),
                        SizedBox(
                          height: 25.0,
                        ),
                        _txApellido(),
                        SizedBox(
                          height: 25.0,
                        ),
                        _txtCorreo(),
                        SizedBox(
                          height: 25.0,
                        ),
                        _txtTelefono(),
                        SizedBox(
                          height: 25.0,
                        ),
                        _txtContrasenia(),
                        SizedBox(
                          height: 50.0,
                        ),
                        _botonFormulario(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _txtNombre() {
    return TextFormField(
      controller: nombreController,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta ingresar un nombre';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
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

  Widget _txApellido() {
    return TextFormField(
      controller: apellidoController,
      textCapitalization: TextCapitalization.words,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta ingresar apellido';
        }
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
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

  Widget _txtTelefono() {
    return TextFormField(
      controller: telController,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta este campo';
        }
        return null;
      },
      keyboardType: TextInputType.phone,
      
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        hintText: 'Teléfono',
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

  Widget _botonFormulario() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.90,
      child: FlatButton(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        color: Colors.blueAccent[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(20.0),
        ),
        onPressed: _enviarDatos,
        child: Text('Enviar'),
      ),
    );
  }

  void _enviarDatos() async {
    if (_formKey.currentState.validate()) {
      autenticaUsuario(context);
      Navigator.of(context).pushNamed('/');
    }
  }

  void autenticaUsuario(BuildContext context) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      AuthResult result = await auth.createUserWithEmailAndPassword(
        email: correoController.text,
        password: contraController.text,
      );
      FirebaseUser user = result.user;
      registraUsuario(user);
    } catch (error) {
      print(error);
      print(error.code);
      String errormessage;
      switch (error.code) {
        case "ERROR_EMAIL_ALREADY_IN_USE":
          errormessage = "Ya existe un usuario registrado con ese correo.";
          break;
        default:
          errormessage = "Error desconocido";
      }
      mostrarAlerta(context, 'Error', errormessage);
    }
  }

  void registraUsuario(FirebaseUser user) {
    try {
      final dbFire = Firestore.instance;
      Map<String, dynamic> datosViaje = {
        'Encoded_Polyline': '',
        'PActual': null,
        'PDestino': null,
        'POrigen': null,
        "Inicio_Viaje": null,
        "Fin_Viaje": null,
        'Tipo_Viaje': 1
      };

      Map<String, dynamic> registro = {
        'En_viaje': false,
        'Nombre': nombreController.text,
        'PApellido': apellidoController.text,
        'Correo': correoController.text,
        'Telefono': int.parse(telController.text),
        'Viaje': datosViaje
      };

      dbFire
          .collection('Artely_BD')
          .document(user.uid)
          .setData(registro)
          .whenComplete(
        () {
          mostrarAlerta(context, 'Bienvenido', 'Usuario agregado con exito');
        },
      );
    } catch (e) {
      print(e.toString());
      print(e.code);
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
