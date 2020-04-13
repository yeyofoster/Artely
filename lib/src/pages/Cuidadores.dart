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
  Future<QuerySnapshot> _getReferencias;
  Future actualiza;
  List<Cuidador> cuidadores = [];
  TextEditingController correoController = TextEditingController();
  PreferenciasUsuario _preferenciasUsuario;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _preferenciasUsuario = new PreferenciasUsuario();
    cuidadores.clear();
    actualiza = refreshCuidadores();
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
            double width = MediaQuery.of(context).size.width * 0.75;
            double height = MediaQuery.of(context).size.height * 0.4;
            VentanaEmergente addCuidador = VentanaEmergente(
              contenido: formularioCuidador(width),
              titulo: 'Añadir Cuidador',
              backgroundColorTitulo: Colors.blue[300],
              colorTitulo: Colors.white,
              width: width,
              height: height,
            );
            addCuidador.mostrarVentana(context);
          },
        ),
        body: RefreshIndicator(
          color: Colors.cyan,
          child: listaCuidadoresWidget(),
          onRefresh: () => refreshCuidadores(),
        ),
      ),
    );
  }

  //Método que obtiene las referencias de los cuidadores del usuario.
  Future<QuerySnapshot> obtenerReferencias() async {
    QuerySnapshot query = await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .getDocuments();
    return query;
  }

  //Método encargado de obtener los datos de los cuidadores.
  //Necesita que se haya ejecutado obtener referencias previamente.
  Future obtenerCuidadores(Future<QuerySnapshot> consulta) {
    consulta.then(
      (query) {
        query.documents.forEach(
          (DocumentSnapshot docRef) async {
            String codDoc = docRef.data['Referencia'].documentID;
            await Firestore.instance
                .collection('Artely_BD')
                .document(codDoc)
                .get()
                .then(
              (DocumentSnapshot docCuidador) {
                Cuidador cuid = Cuidador(
                  nombre: docCuidador.data['Nombre'],
                  pApellido: docCuidador.data['PApellido'],
                  correo: docCuidador.data['Correo'],
                  telefono: docCuidador.data['Telefono'],
                );
                cuidadores.add(cuid);
              },
            ).catchError(
              (onError) {
                print('Error');
              },
            );
          },
        );
      },
    );
    return Future.delayed(Duration(milliseconds: 700));
  }

  //Método que regresa el ListView con los cuidadores.
  Widget listaCuidadoresWidget() {
    return FutureBuilder(
      future: actualiza,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (cuidadores.isNotEmpty) {
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
        return null;
      },
    );
  }

  //Método que regresa el formulario  mostrar en la ventna emergente.
  Widget formularioCuidador(double width) {
    return Container(
      width: width,
      child: Form(
        key: _formKey,
        child: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.symmetric(
            vertical: 22.0,
            horizontal: 20.0,
          ),
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

  //Obtiene una ctualizaciòn de los cuidadores
  Future refreshCuidadores() async {
    cuidadores.clear();
    _getReferencias = obtenerReferencias();
    return obtenerCuidadores(_getReferencias);
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
  Future buscarUsuario(String correo) async {
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

    await refreshCuidadores();
    setState(() {});
  }
}
