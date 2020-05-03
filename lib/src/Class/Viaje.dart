class Viaje {
  String origen;
  String destino;
  String minutos;
  int tipo;

  Viaje({
    this.tipo = 1,
    this.origen = '',
    this.destino = '',
    this.minutos = '',
  });

  @override
  String toString() {
    return 'Tipo: ${this.tipo}, Minutos: ${this.minutos}, Origen: ${this.origen}, Destino: ${this.destino}';
  }
}
