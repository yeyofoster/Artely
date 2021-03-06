class BusquedaRoutes {
  String _apiKey = 'AIzaSyD18jrJ0uzDz-Pt3hg2YLCXjxpEkCAYJ2c';
  String _language = 'es-419';
  String _mode = 'driving'; //walking, bicycling, transit
  String _alternatives = 'true'; //True = +1 ruta. False = 1 ruta
  String _units = 'metric';
  String _urlAPI = 'https://maps.googleapis.com/maps/api/directions/json?';
  String _origen;
  String _destino;

  BusquedaRoutes();

  set origen(String input) {
    this._origen = input;
  }

  set destino(String input) {
    this._destino = input;
  }

  set modo(String input) {
    this._mode = input;
  }

  set alternativas(String input) {
    this._alternatives = input;
  }

  set units(String input) {
    this._units = input;
  }

  set apikey(String key) {
    this._apiKey = key;
  }

  String get urlRoutes {
    return this._urlAPI +
        'origin=' +
        this._origen +
        '&destination=' +
        this._destino +
        '&mode=' +
        this._mode +
        '&alternatives=' +
        this._alternatives +
        '&units=' +
        this._units +
        '&language=' +
        this._language +
        '&key=' +
        this._apiKey;
  }
}
