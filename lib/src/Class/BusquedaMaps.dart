class BusquedaMaps {
  String _apiKey = 'AIzaSyD18jrJ0uzDz-Pt3hg2YLCXjxpEkCAYJ2c';
  String _language = 'es-419';
  String _urlAPI =
      'https://maps.googleapis.com/maps/api/place/textsearch/json?query=';
  //String _urlAPI =
  //    'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=';
  String _busqueda;

  BusquedaMaps();

  set search(String input) {
    this._busqueda = input;
  }

  set apikey(String key) {
    this._apiKey = key;
  }

  String get urlBusqueda {
    return this._urlAPI +
        this._busqueda +
        '&language=' +
        this._language +
        '&key=' +
        this._apiKey;
  }
}
