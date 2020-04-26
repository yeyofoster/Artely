import 'package:flutter/material.dart';

class VentanaEmergente {
  Widget contenido;
  String titulo;
  double height;
  double width;
  Color colorTitulo;
  Color backgroundColor;
  Color backgroundColorTitulo;
  bool closeButton;

  VentanaEmergente({
    this.contenido,
    this.titulo,
    this.height,
    this.width,
    this.colorTitulo,
    this.backgroundColor,
    this.backgroundColorTitulo,
    this.closeButton,
  });

  void cerrarVentana(BuildContext context) {
    Navigator.of(context).pop();
  }

  void mostrarVentana(BuildContext context) {
    valoresDefault(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext build) {
        return Dialog(
          child: Container(
            width: this.width,
            height: this.height,
            child: Stack(
              children: <Widget>[
                //Este el titulo del Dialog
                getTitle(context),

                //Este es el contenido del Dialog
                getBody(context),

                //Este es el botón para cerrar
                getCloseButton(context),
              ],
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          elevation: 1.0,
        );
      },
    );
  }

  //Método que obtiene los valores por default del Dialog.
  void valoresDefault(BuildContext context) {
    if (this.width == null) {
      this.width = MediaQuery.of(context).size.width * 0.95;
    }

    if (this.height == null) {
      this.height = MediaQuery.of(context).size.height * 0.5;
    }

    if (this.backgroundColorTitulo == null) {
      this.backgroundColorTitulo = Colors.blue;
    }

    if (this.backgroundColor == null) {
      this.backgroundColor = Colors.white;
    }

    if (this.closeButton == null) {
      this.closeButton = true;
    }
  }

  //Método que regresa el Widget del titulo. Si el título es null regresa un widget vacio.
  Widget getTitle(BuildContext context) {
    if (this.titulo == null) {
      return SizedBox();
    } else {
      return Container(
        height: MediaQuery.of(context).size.height * 0.08,
        width: this.width,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          vertical: 15.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15.0),
            topLeft: Radius.circular(15.0),
          ),
          color: this.backgroundColorTitulo,
        ),
        child: Text(
          this.titulo,
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 24.0, color: this.colorTitulo),
        ),
      );
    }
  }

  Widget getBody(BuildContext context) {
    if (this.titulo == null) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: this.backgroundColor,
        ),
        child: SingleChildScrollView(
          child: this.contenido,
        ),
      );
    } else {
      return Positioned(
        top: MediaQuery.of(context).size.height * 0.08,
        left: this.width * 0.008,
        child: Container(
          height: this.height - MediaQuery.of(context).size.height * 0.09,
          width: this.width * 0.82,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: this.backgroundColor,
          ),
          child: SingleChildScrollView(
            child: this.contenido,
          ),
        ),
      );
    }
  }

  Widget getCloseButton(BuildContext context) {
    if (closeButton) {
      return Align(
        alignment: Alignment(1.05, -1.03),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.close,
              color: Colors.black,
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
