import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';

class PantallaConfiguracion extends StatefulWidget {
  PantallaConfiguracion({Key key}) : super(key: key);

  @override
  _PantallaConfiguracionState createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  @override
  Widget build(BuildContext context) {
    double maxHeight = MediaQuery.of(context).size.height;
    // double maxWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mi configuración'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Card(
                elevation: 5.0,
                child: ListTile(
                    title: Text(
                      'Mis rutas',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 24.0,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: SvgPicture.asset(
                        'assets/icon/route.svg',
                        color: Colors.cyan,
                        height: 27.0,
                      ),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
                    onTap: () {
                      Navigator.of(context).pushNamed('rutas');
                    }),
              ),
              Card(
                elevation: 5.0,
                child: ListTile(
                    title: Text(
                      'Mis cuidadores',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 24.0,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.people,
                        color: Colors.cyan,
                      ),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
                    onTap: () {
                      Navigator.of(context).pushNamed('cuidadores');
                    }),
              ),
              Card(
                elevation: 5.0,
                child: ListTile(
                    title: Text(
                      'Mis viajes',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 24.0,
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.cyan,
                      ),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
                    onTap: () {
                      Navigator.of(context).pushNamed('viajes');
                    }),
              ),
              Expanded(
                child: Container(),
              ),
              ListTile(
                  title: Text(
                    'Cerrar sesión',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400],
                      fontSize: 24.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 20.0,
                  ),
                  onTap: () {
                    VentanaEmergente cerrarApp = VentanaEmergente(
                      height: maxHeight * 0.3,
                      titulo: 'Cerrar sesión',
                      closeButton: false,
                      backgroundColorTitulo: Colors.cyan,
                      contenido: Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: Icon(
                                Icons.exit_to_app,
                                color: Colors.cyan,
                                size: 50.0,
                              ),
                            ),
                            Text(
                              '¿Estás seguro de cerrar sesión?',
                              style:
                                  GoogleFonts.openSans(color: Colors.blueGrey),
                              textAlign: TextAlign.center,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  MaterialButton(
                                    color: Colors.blue[400],
                                    minWidth:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: Text('Cerrar sesión'),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    onPressed: () {
                                      PreferenciasUsuario pref =
                                          new PreferenciasUsuario();
                                      pref.userID = '';
                                      pref.protegidosEnViaje = [];
                                      Navigator.pushNamedAndRemoveUntil(context,
                                          '/', ModalRoute.withName('/'));
                                    },
                                  ),
                                  SizedBox(
                                    width: 20.0,
                                  ),
                                  MaterialButton(
                                    color: Colors.red[400],
                                    minWidth:
                                        MediaQuery.of(context).size.width * 0.3,
                                    child: Text('Cancelar'),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    cerrarApp.mostrarVentana(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
