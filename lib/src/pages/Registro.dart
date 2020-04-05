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
  //String nombre, ap, correo, contrasenia, tel;

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
          return 'Falta este campo';
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
          return 'Falta este campo';
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
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta este campo';
        }
        return null;
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
      obscureText: true,
      validator: (input) {
        if (input.isEmpty) {
          return 'Falta este campo';
        }
        return null;
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
        suffixIcon: Icon(
          Icons.lock,
          color: Colors.blue,
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
      /*
      var auth = autenticaUsuario(
              context, correoController.text, contraController.text)
          .then(
        (valido) {
          if (valido) {
            registraUsuario();
            Navigator.of(context).pushNamed('/');
          }
        },
      );
      */
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
        'En_viaje': false,
        'Encoded_Polyline': '',
        'PActual': null,
        'PDestino': null,
        'POrigen': null,
        "Inicio_Viaje": null,
        "Fin_Viaje": null,
        'Tipo_Viaje': 1
      };

      Map<String, dynamic> registro = {
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
/*
  Widget _botonConsultaFormulario() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.90,
      child: FlatButton(
        color: Colors.blue[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(20.0),
        ),
        onPressed: _consultarDatos,
        child: Text('Consultar'),
      ),
    );
  }

  void _consultarDatos() {
    final dbFire = Firestore.instance;
    dbFire
        .collection('Artely_BD')
        .where('Correo', isEqualTo: correoController.text)
        .getDocuments()
        .then(
      (query) {
        if (query.documents.isNotEmpty) {
          String id = query.documents.first.documentID;
          print(id);
          final user =
              Firestore.instance.collection('Artely_BD/$id/Cuidadores');
          user.getDocuments().then((cuidad) {
            cuidad.documents.forEach(
              (doccuidad) {
                print(doccuidad.data);
              },
            );
          });
          final sitios =
              Firestore.instance.collection('Artely_BD/$id/Sitios Comunes');
          sitios.getDocuments().then((sitios) {
            print(sitios.documents.first.data);
          });
          print(query.documents.first.data);
        } else if (query.documents.isEmpty) {
          print('No encontre nada');
        }
      },
    );
  }
  */
