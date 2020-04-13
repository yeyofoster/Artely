class Cuidador {
  String nombre;
  String pApellido;
  String correo;
  int telefono;

  Cuidador({this.nombre, this.pApellido, this.correo, this.telefono});

  Cuidador.fromJson(Map<String, dynamic> json) {
    nombre = json['Nombre'];
    pApellido = json['PApellido'];
    correo = json['Correo'];
    telefono = json['Telefono'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Nombre'] = this.nombre;
    data['PApellido'] = this.pApellido;
    data['Correo'] = this.correo;
    data['Telefono'] = this.telefono;
    return data;
  }
}
