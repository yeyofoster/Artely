import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static final PreferenciasUsuario _instancia =
      new PreferenciasUsuario._internal();

  factory PreferenciasUsuario() {
    return _instancia;
  }

  PreferenciasUsuario._internal();

  SharedPreferences _preferences;

  initPreferences() async {
    this._preferences = await SharedPreferences.getInstance();
  }

  set userID(String value) {
    this._preferences.setString('userID', value);
  }

  get userID {
    return this._preferences.getString('userID') ?? '';
  }

  set protegidosEnViaje(List<String> idProtegidos) {
    this._preferences.setStringList('protegidos', idProtegidos);
  }

  List<String> get protegidosEnViaje {
    return this._preferences.getStringList('protegidos');
  }
}
