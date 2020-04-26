import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Class/Cuidador.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';

class PantallaCuidadores extends StatefulWidget {
  @override
  _PantallaCuidadoresState createState() => _PantallaCuidadoresState();
}

class _PantallaCuidadoresState extends State<PantallaCuidadores> {
  Future _getCuidadores;
  Future _actualiza;
  List<Cuidador> cuidadores = List<Cuidador>();
  TextEditingController correoController = TextEditingController();
  PreferenciasUsuario _preferenciasUsuario;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _preferenciasUsuario = new PreferenciasUsuario();
    cuidadores.clear();
    _actualiza = refreshCuidadores();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis cuidadores'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.green,
          tooltip: 'Agregar Cuidador',
          child: Icon(Icons.person_add),
          onPressed: () {
            double height = MediaQuery.of(context).size.height * 0.4;
            VentanaEmergente addCuidador = VentanaEmergente(
              contenido: formularioCuidador(),
              titulo: 'Añadir Cuidador',
              backgroundColorTitulo: Colors.blue[300],
              colorTitulo: Colors.white,
              height: height,
            );
            addCuidador.mostrarVentana(context);
          },
        ),
        body: RefreshIndicator(
          color: Colors.cyan,
          child: listaCuidadoresWidget(),
          onRefresh: () => _actualiza = refreshCuidadores(),
        ),
      ),
    );
  }

  //Actualiza la lista de cuidadores
  Future refreshCuidadores() async {
    setState(() {});
    cuidadores.clear();
    _getCuidadores = obtenerReferencias();
    return await _getCuidadores.then(
      (lista) async {
        await Future.forEach(
          lista,
          (elem) async {
            Cuidador temp = await obtenerDatos(elem.data['Referencia']);
            cuidadores.add(temp);
          },
        );
      },
    );
  }

  //Método que obtiene las referencias de los cuidadores del usuario.
  Future<List<DocumentSnapshot>> obtenerReferencias() async {
    return await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .getDocuments()
        .then(
          (query) => Future<List<DocumentSnapshot>>.value(query.documents),
        );
  }

  //Método que regresa el ListView con los cuidadores.
  Widget listaCuidadoresWidget() {
    return FutureBuilder(
      future: _actualiza,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (cuidadores.length > 0) {
            cuidadores.sort((a, b) => a.nombre.compareTo(b.nombre));
            return ListView.builder(
              itemCount: cuidadores.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                      title: Text(cuidadores.elementAt(index).nombre +
                          ' ' +
                          cuidadores.elementAt(index).pApellido),
                      subtitle: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Correo: ${cuidadores.elementAt(index).correo}'),
                          Text(
                              'Telefono: ${cuidadores.elementAt(index).telefono}'),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.cyan[50],
                        child: Icon(
                          Icons.person,
                          size: 28.0,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => ventanaEliminarCuidador(index),
                      ),
                      contentPadding: EdgeInsets.only(
                        top: 0.0,
                        bottom: 7.5,
                        left: 10.0,
                        right: 15.0,
                      ),
                      onTap: () {}),
                );
              },
            );
          } else if (cuidadores.isEmpty) {
            return ListView(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                ),
                Center(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'No tienes ningún cuidador agregado',
                        style: TextStyle(fontSize: 20.0, fontFamily: 'Roboto'),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Text(
                        'Agrega cuidores pulsando aquí',
                        style: TextStyle(fontSize: 20.0, fontFamily: 'Roboto'),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Image.asset(
                        'assets/img/curved_arrow.png',
                        width: MediaQuery.of(context).size.width * 0.42,
                        height: MediaQuery.of(context).size.height * 0.3,
                        fit: BoxFit.fill,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return Container();
      },
    );
  }

  //Método que regresa el formulario  mostrar en la ventna emergente.
  Widget formularioCuidador() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Ingresa el correo electrónico de tu cuidador',
              style: TextStyle(fontSize: 17.0, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 15.0,
            ),
            _txtCorreo(),
            SizedBox(
              height: 25.0,
            ),
            _botonFormulario(),
          ],
        ),
      ),
    );
  }

  //Método que regresa el campo de texto para agregaar un cuidador.
  Widget _txtCorreo() {
    return TextFormField(
      controller: correoController,
      keyboardType: TextInputType.emailAddress,
      autofocus: true,
      validator: (input) {
        if (input.isEmpty) {
          return 'Favor de ingresar un correo';
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

  //Método que obtiene el botón del formulario.
  Widget _botonFormulario() {
    return Container(
      width: 250.0,
      child: FlatButton(
        padding: EdgeInsets.symmetric(vertical: 15.0),
        color: Colors.blueAccent[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(20.0),
        ),
        onPressed: _enviarDatos,
        child: Text('Agregar'),
      ),
    );
  }

  //Mètodo que valida los datos del formulario
  void _enviarDatos() async {
    if (_formKey.currentState.validate()) {
      VentanaEmergente ventanaResult = VentanaEmergente(
        contenido: agregarCuidador(correoController.text),
        height: 200.0,
      );
      Navigator.of(context).pop();
      ventanaResult.mostrarVentana(context);
    }
  }

  //Método que agrega un nuevo cuidador a su list de cuidadores.
  //Regresa un widget mientras carga el insert o valida la consulta.
  Widget agregarCuidador(String text) {
    Future _buscar = buscarUsuario(text);
    return FutureBuilder(
      future: _buscar,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            QuerySnapshot result = snapshot.data;

            if (result.documents.isNotEmpty) {
              DocumentSnapshot datosCuidador = result.documents.first;
              bool existeCuidador;
              //Validación en caso de que ya se haya agregado a ese cuidador antes.
              existeCuidador = validarCuidador(datosCuidador);

              if (existeCuidador) {
                return Container(
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                          'Ya tienes agregado a ${datosCuidador.data['Nombre']} ${datosCuidador.data['PApellido']} como cuidador.'),
                      SizedBox(height: 15.0),
                      Icon(
                        Icons.person,
                        size: 70.0,
                        color: Colors.cyan,
                      )
                    ],
                  ),
                );
              }
              //Agrega al cuidador en caso de que no exista.
              else {
                //Método que agrega las referencias a laas colecciones correspondientes.
                addCuidadorFirebase(datosCuidador);

                String nombreCuidador = datosCuidador.data['Nombre'] +
                    ' ' +
                    datosCuidador.data['PApellido'];
                return Container(
                  padding: EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Se ha agregado a $nombreCuidador como cuidador'),
                      SizedBox(height: 15.0),
                      Icon(
                        Icons.check_circle,
                        size: 70.0,
                        color: Colors.lightGreen,
                      )
                    ],
                  ),
                );
              }
            } else {
              return Container(
                padding: EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                        'No se encontró ningún usuario registrado con ese correo :('),
                    SizedBox(height: 15.0),
                    Icon(
                      Icons.cancel,
                      size: 70.0,
                      color: Colors.red,
                    )
                  ],
                ),
              );
            }
          }
        } else {
          return CircularProgressIndicator();
        }
        return null;
      },
    );
  }

  //Método que devuelve la busqueda del usuario.
  Future<QuerySnapshot> buscarUsuario(String correo) async {
    return await Firestore.instance
        .collection('Artely_BD')
        .where('Correo', isEqualTo: correo)
        .getDocuments();
  }

  //Mètodo que añade el cuidador a Firebase
  Future<void> addCuidadorFirebase(DocumentSnapshot datosCuidador) async {
    Map<String, dynamic> datos = {
      'Referencia': datosCuidador.reference,
    };

    await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .add(datos);

    _actualiza = refreshCuidadores();
  }

  //Método que obtiene los datos de un cuidador.
  //Necesita como parámetro un DocumentReference
  Future<Cuidador> obtenerDatos(DocumentReference ref) async =>
      await Firestore.instance
          .collection('Artely_BD')
          .document(ref.documentID)
          .get()
          .then(
        (docCuid) {
          return Cuidador(
            nombre: docCuid.data['Nombre'],
            pApellido: docCuid.data['PApellido'],
            correo: docCuid.data['Correo'],
            telefono: docCuid.data['Telefono'],
          );
        },
      );

  //Método que valida que ya se tenga agregado al cuidador que se intenta agregar.
  bool validarCuidador(DocumentSnapshot datosCuidador) {
    bool valor = false;
    for (Cuidador c in cuidadores) {
      if (c.correo == datosCuidador.data['Correo']) {
        valor = true;
      }
    }
    return valor;
  }

  //Método que muestra la ventana de confirmación para eliminar un cuidador
  void ventanaEliminarCuidador(int index) {
    Future<QuerySnapshot> elimCuid =
        buscarUsuario(cuidadores.elementAt(index).correo);
    elimCuid.then((query) {
      DocumentSnapshot docCuid = query.documents.first;
      VentanaEmergente ventanaEliminar = VentanaEmergente(
        height: MediaQuery.of(context).size.height * 0.3,
        titulo: 'Eliminar Cuidador',
        contenido: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20.0,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.blueGrey[600],
                  fontSize: 18.0,
                ),
                children: [
                  TextSpan(text: '¿Estás seguro de eliminar a '),
                  TextSpan(
                    text:
                        '${docCuid.data['Nombre']} ${docCuid.data['PApellido']}',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '?'),
                ],
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            MaterialButton(
              color: Colors.red[400],
              minWidth: MediaQuery.of(context).size.width * 0.7,
              height: 42.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                VentanaEmergente cargaEliminacion = VentanaEmergente(
                  height: MediaQuery.of(context).size.height * 0.3,
                  contenido: FutureBuilder(
                    future: buscarDocCuidador(docCuid.reference),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        QuerySnapshot data = snapshot.data;
                        try {
                          eliminarDocCuidador(data.documents.first.documentID);
                          return Column(
                            children: <Widget>[
                              Text('Eliminado :DDD'),
                            ],
                          );
                        } catch (e) {
                          return Column(
                            children: <Widget>[
                              Text('Ocurrió un error'),
                            ],
                          );
                        }
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                );
                cargaEliminacion.mostrarVentana(context);
              },
            ),
          ],
        ),
      );
      ventanaEliminar.mostrarVentana(context);
    });
  }

  //Método que regresa el documento del cuidador que se desea eliminar.
  Future buscarDocCuidador(DocumentReference reference) async {
    return await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .where('Referencia', isEqualTo: reference)
        .getDocuments();
  }

  Future<void> eliminarDocCuidador(String documentID) async {
    await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .document(documentID)
        .delete();
    _actualiza = refreshCuidadores();
  }
}
