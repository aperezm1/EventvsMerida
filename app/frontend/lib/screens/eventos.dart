import 'dart:async';
import 'dart:ui';

import 'package:eventvsmerida/services/shared_preferences_service.dart';
import 'package:eventvsmerida/widgets/componentes_compartidos.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../models/api_response.dart';
import '../models/categoria.dart';
import '../models/evento.dart';
import '../models/usuario.dart';

import '../services/api_service.dart';
import '../services/eventos_guardados_service.dart';

class Eventos extends StatefulWidget {
  const Eventos({super.key});

  @override
  State<Eventos> createState() => _EventosState();
}

class _EventosState extends State<Eventos> {
  // ===========================================================================
  // VARIABLES
  // ===========================================================================

  GlobalKey keyTarjetaEvento = GlobalKey();
  GlobalKey keyBtnBuscar = GlobalKey();
  GlobalKey keyBtnFiltro = GlobalKey();

  String _textoBusqueda = '';

  late Future<ApiResponse<List<Evento>>> _eventosEncontrados;
  Future<ApiResponse<List<Evento>>>? _eventosFuture;
  late Future<ApiResponse<List<Categoria>>> _categorias;

  Usuario? _usuario;
  List<Evento> _eventosGuardados = [];

  Timer? _debounce;
  final TextEditingController _inputBusquedaController =
  TextEditingController();

  bool _modalBusquedaAbierto = false;

  final Set<int> _categoriasSeleccionadas = {};
  final List<Evento> _eventosList = [];

  int _page = 0;
  final int _pageSize = 15;

  bool _isLoadingEventos = false;
  bool _hasMoreEventos = true;
  bool _usandoFiltros = false;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoriasScrollController = ScrollController();

  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ===========================================================================
  // CICLO DE VIDA
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _eventosEncontrados = ApiService.buscarEventos(_textoBusqueda);
    _categorias = ApiService.obtenerCategorias();

    _cargarDatosUsuarioYGuardados();

    _scrollController.addListener(_onScroll);
    _resetAndFetchEventos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputBusquedaController.dispose();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _categoriasScrollController.dispose();

    super.dispose();
  }

  bool _targetEstaListo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;

    final renderObject = ctx.findRenderObject();
    return renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize;
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================

  Future<void> _cargarDatosUsuarioYGuardados() async {
    final (usuario, guardados) =
    await EventosGuardadosService.cargarUsuarioYEventosGuardados();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _eventosGuardados = guardados;
    });
  }

  Future<void> _fetchEventosPage() async {
    if (_isLoadingEventos || !_hasMoreEventos) return;

    setState(() {
      _isLoadingEventos = true;
    });

    try {
      final mapaResp = await ApiService.obtenerEventosPaginados(
        page: _page,
        size: _pageSize,
        fechaFinDesde: DateTime.now(),
      );

      if (!mounted) return;

      if (mapaResp == null) {
        setState(() {
          _hasMoreEventos = false;
        });
        return;
      }

      final items = (mapaResp['items'] as List<Evento>?) ?? [];
      final last = mapaResp['last'] as bool? ?? items.length < _pageSize;
      final esPrimeraPagina = _page == 0;

      setState(() {
        _eventosList.addAll(items);
        _page++;
        _hasMoreEventos = !last;
      });

      if (esPrimeraPagina) {
        await _cargarTutorial();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasMoreEventos = false;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoadingEventos = false;
      });
    }
  }

  Future<void> _cargarTutorial() async {
    if (await SharedPreferencesService.cargarTutorial()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        _comprobarInicializacionTutorial();
      });
    }
  }

  // ===========================================================================
  // FUNCIONES AUXILIARES
  // ===========================================================================

  void _buscarEventos(String text, void Function(void Function()) setStateModal) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_modalBusquedaAbierto) return;

      _actualizarResultadosBusqueda(text);
      setStateModal(() {});
    });
  }

  void _actualizarResultadosBusqueda(String texto) {
    _textoBusqueda = texto;
    _eventosEncontrados = ApiService.buscarEventos(_textoBusqueda);
  }

  void _reiniciarBusqueda() {
    _debounce?.cancel();
    _inputBusquedaController.clear();
    _actualizarResultadosBusqueda('');
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _esHoraCero(DateTime fecha) {
    return fecha.hour == 0 && fecha.minute == 0;
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String _formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  String _textoFechaHoraCard(Evento evento) {
    final esMismoDia = _esMismoDia(evento.fechaInicio, evento.fechaFin);
    final inicioFecha = _formatearFecha(evento.fechaInicio);
    final finFecha = _formatearFecha(evento.fechaFin);
    final inicioHora = _formatearHora(evento.fechaInicio);
    final finHora = _formatearHora(evento.fechaFin);
    final horasIguales = inicioHora == finHora;
    final ambasHorasCero =
        _esHoraCero(evento.fechaInicio) && _esHoraCero(evento.fechaFin);

    if (esMismoDia) {
      if (horasIguales && ambasHorasCero) return 'Fecha: $inicioFecha';
      if (horasIguales) return 'Fecha: $inicioFecha · $inicioHora';
      return 'Fecha: $inicioFecha · $inicioHora - $finHora';
    }

    if (horasIguales && ambasHorasCero) {
      return 'Fecha: $inicioFecha - $finFecha';
    }

    if (horasIguales) {
      return 'Fecha: $inicioFecha - $finFecha · $inicioHora';
    }

    return 'Fecha: $inicioFecha - $finFecha · $inicioHora - $finHora';
  }

  String _textoFechaBusqueda(Evento evento) {
    return '${_formatearFecha(evento.fechaInicio)} · ${_formatearHora(evento.fechaInicio)}';
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingEventos ||
        !_hasMoreEventos ||
        _usandoFiltros) {
      return;
    }

    if (_scrollController.position.extentAfter < 200) {
      _fetchEventosPage();
    }
  }

  void _resetAndFetchEventos() {
    _eventosList.clear();
    _page = 0;
    _hasMoreEventos = true;
    _isLoadingEventos = false;
    _fetchEventosPage();
  }

  void _alternarCategoria(
      Categoria categoria,
      Set<int> categoriasTemporales,
      void Function(void Function()) setStateModal,
      ) {
    setStateModal(() {
      if (categoriasTemporales.contains(categoria.id)) {
        categoriasTemporales.remove(categoria.id);
      } else {
        categoriasTemporales.add(categoria.id);
      }
    });
  }

  void _aplicarFiltros(Set<int> categoriasTemporales) {
    Navigator.of(context, rootNavigator: true).maybePop();

    setState(() {
      _categoriasSeleccionadas
        ..clear()
        ..addAll(categoriasTemporales);
    });

    if (_categoriasSeleccionadas.isEmpty) {
      setState(() {
        _usandoFiltros = false;
        _eventosFuture = null;
      });

      _resetAndFetchEventos();
      return;
    }

    setState(() {
      _usandoFiltros = true;
      _eventosFuture = ApiService.obtenerEventosFiltradosPorCategorias(
        _categoriasSeleccionadas.toList(),
      );
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _categoriasSeleccionadas.clear();
      _usandoFiltros = false;
      _eventosFuture = null;
    });

    _resetAndFetchEventos();
  }

  void _limpiarFiltrosDesdeModal() {
    Navigator.of(context, rootNavigator: true).maybePop();
    _limpiarFiltros();
  }

  List<Evento> _obtenerEventosBusqueda(
      ApiResponse<List<Evento>>? respuesta,
      String tipo,
      ) {
    final eventos = List<Evento>.from(respuesta?.datos ?? const []);

    if (tipo.isEmpty) {
      eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    }

    return eventos;
  }

  // ===========================================================================
  // MODALES
  // ===========================================================================

  void _abrirModalEvento(Evento evento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ModalEvento(
          eventos: [evento],
          usuario: _usuario,
          eventosGuardados: _eventosGuardados,
          onEventosGuardadosActualizados: (nuevaLista) {
            setState(() {
              _eventosGuardados = nuevaLista;
            });
          },
          mostrarBotonGuardado: true,
        ),
      ),
    );
  }

  void _abrirModalBusqueda() {
    _modalBusquedaAbierto = true;

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (ctx) {
        return Stack(
          children: [
            _buildFondoModalDesenfocado(),
            StatefulBuilder(
              builder: (context, setStateModal) {
                return _buildModalBusqueda(setStateModal);
              },
            ),
          ],
        );
      },
    ).then((_) {
      _modalBusquedaAbierto = false;

      if (!mounted) return;

      _reiniciarBusqueda();
      setState(() {});
    });
  }

  Widget _buildModalBusqueda(void Function(void Function()) setStateModal) {
    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inputBusquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar eventos...',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _modalBusquedaAbierto = false;
                    _debounce?.cancel();
                    Navigator.of(context, rootNavigator: true).maybePop();
                  },
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    if (!_modalBusquedaAbierto) return;

                    _inputBusquedaController.clear();
                    _actualizarResultadosBusqueda('');
                    setStateModal(() {});
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (text) => _buscarEventos(text, setStateModal),
            ),
            const SizedBox(height: 12),
            _buildEventosFiltradosBusquedaBody(
              _eventosEncontrados,
              'busqueda',
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalFiltros() {
    final categoriasTemporales = Set<int>.from(_categoriasSeleccionadas);

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (ctx) {
        return Stack(
          children: [
            _buildFondoModalDesenfocado(),
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 48,
              ),
              child: StatefulBuilder(
                builder: (contextModal, setStateModal) {
                  return _buildModalFiltros(
                    categoriasTemporales,
                    setStateModal,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalFiltros(Set<int> categoriasTemporales, void Function(void Function()) setStateModal) {
    final hayFiltrosAplicados = _categoriasSeleccionadas.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCabeceraModalFiltros(),
          const SizedBox(height: 8),
          _buildListaCategoriasFiltro(
            categoriasTemporales,
            setStateModal,
          ),

          if (hayFiltrosAplicados) ...[
            const SizedBox(height: 12),
            _buildBotonLimpiarFiltros(),
          ],

          const SizedBox(height: 12),
          _buildBotonAplicarFiltros(categoriasTemporales),
        ],
      ),
    );
  }

  Widget _buildCabeceraModalFiltros() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Filtrar por categoría',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _cs.onSurface,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: _cs.primary),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).maybePop();
          },
        ),
      ],
    );
  }

  Widget _buildListaCategoriasFiltro(Set<int> categoriasTemporales, void Function(void Function()) setStateModal) {
    return FutureBuilder<ApiResponse<List<Categoria>>>(
      future: _categorias,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Error: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final resp = snapshot.data;
        if (resp == null || !resp.exito) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              resp?.mensaje ?? 'No se pudieron cargar las categorías',
              textAlign: TextAlign.center,
            ),
          );
        }

        final lista = resp.datos ?? const <Categoria>[];

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 4,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: _cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              RawScrollbar(
                controller: _categoriasScrollController,
                thumbVisibility: true,
                trackVisibility: false,
                interactive: true,
                thickness: 6,
                radius: const Radius.circular(20),
                mainAxisMargin: 0,
                crossAxisMargin: 4,
                thumbColor: _cs.primary,
                child: ListView.separated(
                  controller: _categoriasScrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(right: 14),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final categoria = lista[index];
                    return _buildCategoriaFiltroItem(
                      categoria,
                      categoriasTemporales,
                      setStateModal,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriaFiltroItem(Categoria categoria, Set<int> categoriasTemporales, void Function(void Function()) setStateModal) {
    final seleccionado = categoriasTemporales.contains(categoria.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _alternarCategoria(
          categoria,
          categoriasTemporales,
          setStateModal,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado
                  ? _cs.primary
                  : _cs.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _cs.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.label,
                    size: 18,
                    color: _cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  categoria.nombre,
                  style: TextStyle(
                    fontSize: 15,
                    color: _cs.onSurface,
                  ),
                ),
              ),
              Checkbox(
                value: seleccionado,
                onChanged: (_) => _alternarCategoria(
                  categoria,
                  categoriasTemporales,
                  setStateModal,
                ),
                activeColor: _cs.primary,
                checkColor: _cs.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonAplicarFiltros(Set<int> categoriasTemporales) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _aplicarFiltros(categoriasTemporales),
        style: ElevatedButton.styleFrom(
          backgroundColor: _cs.primary,
          foregroundColor: _cs.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Aplicar filtros'),
      ),
    );
  }

  Widget _buildBotonLimpiarFiltros() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.filter_alt_off, color: _cs.primary),
        label: const Text('Limpiar filtros'),
        onPressed: _limpiarFiltrosDesdeModal,
        style: OutlinedButton.styleFrom(
          foregroundColor: _cs.primary,
          side: BorderSide(color: _cs.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MENSAJES
  // ===========================================================================

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ===========================================================================
  // INTERFAZ
  // ===========================================================================

  Widget _buildFondoModalDesenfocado() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required String tooltip, VoidCallback? onPressed, int badgeCount = 0, Key? widgetKey}) {
    final action = badgeCount <= 0
        ? IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _cs.primary),
      tooltip: tooltip,
    )
        : _buildAppBarActionConBadge(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      badgeCount: badgeCount,
    );

    return KeyedSubtree(
      key: widgetKey,
      child: action,
    );
  }

  Widget _buildAppBarActionConBadge({required IconData icon, required String tooltip, VoidCallback? onPressed, required int badgeCount}) {
    final text = badgeCount > 9 ? '9+' : badgeCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: _cs.primary),
          tooltip: tooltip,
        ),
        Positioned(
          right: 0,
          top: 6,
          child: Container(
            width: 22,
            height: 14,
            decoration: BoxDecoration(
              color: _cs.primary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _cs.surface, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: _cs.surface,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoCentro({required IconData icono, required String mensaje}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 42),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento, {Key? key}) {
    return Card(
      key: key,
      elevation: 6,
      shadowColor: _cs.onSurface,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _cs.onPrimary, width: 2),
      ),
      color: _cs.secondary,
      child: InkWell(
        onTap: () => _abrirModalEvento(evento),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagenEventoPrincipal(evento.foto),
            _buildContenidoEventoCard(evento),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenEventoPrincipal(String foto) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/images/icono.gif',
          image: foto,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          placeholderFit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildContenidoEventoCard(Evento evento) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evento.titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            evento.nombreCategoria,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            evento.localizacion,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            _textoFechaHoraCard(evento),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImagenEventoBusqueda(String foto) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        bottomLeft: Radius.circular(18),
      ),
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/images/icono.gif',
        image: foto,
        width: 100,
        height: 110,
        fit: BoxFit.cover,
        placeholderFit: BoxFit.cover,
      ),
    );
  }

  Widget _buildEventoBusquedaCard(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _abrirModalEvento(evento),
          child: Container(
            decoration: BoxDecoration(
              color: _cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cs.primary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _cs.onPrimary.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildImagenEventoBusqueda(evento.foto),
                Expanded(
                  child: _buildContenidoEventoBusquedaCard(evento),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoEventoBusquedaCard(Evento evento) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evento.titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _cs.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            evento.localizacion,
            style: TextStyle(
              color: _cs.onSurface.withValues(alpha: 0.70),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            _textoFechaBusqueda(evento),
            style: TextStyle(
              fontSize: 13,
              color: _cs.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorCargaLista() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEventosPaginatedBody() {
    if (_eventosList.isEmpty && _isLoadingEventos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eventosList.isEmpty) {
      return _buildEstadoCentro(
        icono: Icons.event_busy,
        mensaje: 'No hay eventos disponibles',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _eventosList.length + (_hasMoreEventos ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _eventosList.length) {
          final evento = _eventosList[index];

          return _buildEventoCard(
            evento,
            key: index == 0 ? keyTarjetaEvento : null,
          );
        }

        return _buildIndicadorCargaLista();
      },
    );
  }

  Widget _buildEventosFiltradosBusquedaBody(Future<ApiResponse<List<Evento>>> listadoEventos, String tipo) {
    return FutureBuilder<ApiResponse<List<Evento>>>(
      future: listadoEventos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEstadoCentro(
            icono: Icons.error_outline,
            mensaje: 'Error: ${snapshot.error}',
          );
        }

        final respuesta = snapshot.data;

        if (respuesta == null || !respuesta.exito) {
          return _buildEstadoCentro(
            icono: Icons.error_outline,
            mensaje:
            respuesta?.mensaje ?? 'No se han podido cargar los eventos',
          );
        }

        final eventos = _obtenerEventosBusqueda(respuesta, tipo);

        if (tipo == 'busqueda' && _textoBusqueda.isEmpty) {
          return _buildEstadoCentro(
            icono: Icons.search,
            mensaje: 'Ingresa un término de búsqueda para encontrar eventos',
          );
        }

        if (eventos.isEmpty) {
          return _buildEstadoCentro(
            icono: tipo == 'busqueda' ? Icons.search_off : Icons.event_busy,
            mensaje: tipo == 'busqueda'
                ? 'No se han encontrado eventos para "$_textoBusqueda"'
                : 'No hay eventos disponibles',
          );
        }

        if (tipo == 'busqueda') {
          return _buildResultadosBusqueda(eventos);
        }

        return ListView.builder(
          itemCount: eventos.length,
          itemBuilder: (context, index) {
            return _buildEventoCard(eventos[index]);
          },
        );
      },
    );
  }

  Widget _buildResultadosBusqueda(List<Evento> eventos) {
    const double itemHeight = 110;
    final visibleCount = eventos.length < 3 ? eventos.length : 3;
    final maxHeight = itemHeight * visibleCount;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: eventos.length,
        itemBuilder: (context, index) {
          return _buildEventoBusquedaCard(eventos[index]);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_usandoFiltros) {
      if (_eventosFuture == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return _buildEventosFiltradosBusquedaBody(_eventosFuture!, '');
    }

    return _buildEventosPaginatedBody();
  }

  // ===========================================================================
  // TUTORIAL
  // ===========================================================================

  void _comprobarInicializacionTutorial() {
    if (!mounted) return;
    if (Tutorial.numPantalla != 1) return;
    if (Tutorial.tutorialInicializado) return;
    if (_eventosList.isEmpty) return;
    if (!_targetEstaListo(keyTarjetaEvento) ||
        !_targetEstaListo(keyBtnBuscar) ||
        !_targetEstaListo(keyBtnFiltro)) {
      return;
    }

    Tutorial.tutorialInicializado = true;
    _configurarTutorial();
  }

  void _configurarTutorial() {
    Tutorial.pasosTutorial.clear();
    cargarPasosTutorial();

    Tutorial.tutorial = Tutorial.crearTutorial(
      context: context,
      pasosTutorial: Tutorial.pasosTutorial,
      color: Theme.of(context).colorScheme.primary,
    );

    Tutorial.mostrarTutorial(context);
  }

  void cargarPasosTutorial() {
    Tutorial.navPasoActivo.value = false;

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyTarjetaEvento,
        titulo: 'Eventos disponibles',
        descripcion:
        'Aquí puedes ver todos los eventos disponibles. Toca en cualquiera para verlo en detalle.',
        icon: Icons.event,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
        forma: ShapeLightFocus.RRect,
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyBtnBuscar,
        titulo: 'Buscar eventos',
        descripcion:
        'Desde aquí puedes buscar eventos por nombre, ubicación o categoría.',
        icon: Icons.search,
        siguiente: true,
        onNext: () => Tutorial.tutorial.next(),
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        context: context,
        key: keyBtnFiltro,
        titulo: 'Filtrar eventos',
        descripcion:
        'Desde aquí puedes filtrar los eventos por categoría para encontrar más rápido segun tus gustos.',
        icon: Icons.filter_alt,
        siguiente: true,
        onNext: () {
          Tutorial.navPasoActivo.value = true;
          Tutorial.tutorial.next();
        },
      ),
    );

    Tutorial.pasosTutorial.add(
      Tutorial.crearPaso(
        alineamientoTarjeta: ContentAlign.top,
        context: context,
        key: Tutorial.keyNavMapa,
        titulo: 'Mapa',
        descripcion:
        'A continuación, pasemos al mapa. Pulsa el botón de continuar para ir al mapa.',
        icon: Icons.map,
        siguiente: true,
        onNext: () async {
          Tutorial.navPasoActivo.value = false;
          Tutorial.numPantalla = 2;
          Tutorial.tutorialInicializado = false;
          Tutorial.tutorial.finish();

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;

          context.go('/mapa');
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildAppBarAction(
                  icon: Icons.search,
                  tooltip: 'Buscar',
                  onPressed: _abrirModalBusqueda,
                  widgetKey: keyBtnBuscar,
                ),
                _buildAppBarAction(
                  icon: Icons.filter_alt_rounded,
                  tooltip: 'Filtrar',
                  onPressed: _abrirModalFiltros,
                  badgeCount: _categoriasSeleccionadas.length,
                  widgetKey: keyBtnFiltro,
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}