import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasUsuario {
  static final PreferenciasUsuario _instancia =
      new PreferenciasUsuario._internal();

  factory PreferenciasUsuario() {
    return _instancia;
  }

  PreferenciasUsuario._internal();

  /*
  String token;
  String email;
  */
  
  SharedPreferences _preferences;

  initPreferences() async {
    this._preferences = await SharedPreferences.getInstance();
  }

  set token(String value){
    this._preferences.setString('token', value);
  }

  get token{
    return this._preferences.getString('token') ?? '';
  }
}
