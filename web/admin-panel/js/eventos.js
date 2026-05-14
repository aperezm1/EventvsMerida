// ==========================================================================
// VARIABLES
// ==========================================================================

const URL_BASE = window.APP_CONFIG.API_BASE;

let paginaActual = 0;
let cantidadPaginacion = 1;
const coordenadasSeleccionadas = new Map();

// ==========================================================================
// CONTENIDO DEL DOM
// ==========================================================================

window.addEventListener("DOMContentLoaded", async () => {
  const ok = await requireAuth();
  if (!ok) return;

  cargarEventos();
  obtenerOrganizadores();
  obtenerCategorias();

  // Buscador de eventos
  document.addEventListener("input", (e) => {
    if (e.target.matches("#buscador")) {
      if (e.target.value.trim() === "") {
        cargarEventos();
      } else {
        buscarEvento(e.target.value);
        document.getElementById("textoBusqueda").textContent = e.target.value;
      }
    }
  });

  [
    { inputId: "localizacion", listId: "localizacionResultados" },
    { inputId: "localizacionEditar", listId: "localizacionEditarResultados" },
  ].forEach(({ inputId, listId }) => {
    inicializarAutocompleteLocalizacion(inputId, listId);
  });

  // Formulario agregar evento
  const form = document.getElementById("formAgregarEvento");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const fechaInicioVal = document.getElementById("fechaInicio").value;
        const horaInicioVal = document.getElementById("horaInicio").value;
        const fechaFinVal = document.getElementById("fechaFin").value;
        const horaFinVal = document.getElementById("horaFin").value;
        const fechaInicio = new Date(`${fechaInicioVal}T${horaInicioVal}:00`);
        const fechaFin = new Date(`${fechaFinVal}T${horaFinVal}:00`);

        if (fechaFin < fechaInicio) {
          event.stopPropagation();
          mostrarAlerta(
            "error",
            "La fecha de fin no puede ser anterior a la fecha de inicio",
          );
          form.classList.add("was-validated");
          return;
        }

        const coords = coordenadasSeleccionadas.get("localizacion") || {};
        const evento = {
          titulo: document.getElementById("titulo").value,
          descripcion: document.getElementById("descripcion").value,
          fechaInicio: `${fechaInicioVal}T${horaInicioVal}:00.000`,
          fechaFin: `${fechaFinVal}T${horaFinVal}:00.000`,
          localizacion: document.getElementById("localizacion").value,
          latitud: coords.lat ?? null,
          longitud: coords.lon ?? null,
          foto: null,
          idUsuario: document.getElementById("organizadores").value,
          idCategoria: document.getElementById("categorias").value,
        };
        const formData = new FormData();
        formData.append("evento", JSON.stringify(evento));
        formData.append(
          "imagen",
          document.getElementById("fotoEvento").files[0],
        );
        crearEvento(formData, true);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  // Formulario editar evento
  const formEditar = document.getElementById("formEditarEvento");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
        return;
      }
      event.preventDefault();

      const titulo = document.getElementById("tituloEventoEditar").value.trim();
      const descripcion = document
        .getElementById("descripcionEventoEditar")
        .value.trim();
      const fechaInicioVal = document.getElementById("fechaInicioEditar").value;
      const horaInicioVal = document.getElementById("horaInicioEditar").value;
      const fechaFinVal = document.getElementById("fechaFinEditar").value;
      const horaFinVal = document.getElementById("horaFinEditar").value;
      const fechaInicio =
        fechaInicioVal && horaInicioVal
          ? `${fechaInicioVal}T${horaInicioVal}:00.000`
          : null;
      const fechaFin =
        fechaFinVal && horaFinVal
          ? `${fechaFinVal}T${horaFinVal}:00.000`
          : null;

      if (
        fechaInicio &&
        fechaFin &&
        new Date(fechaFin) < new Date(fechaInicio)
      ) {
        event.stopPropagation();
        mostrarAlerta(
          "error",
          "La fecha de fin no puede ser anterior a la fecha de inicio",
        );
        formEditar.classList.add("was-validated");
        return;
      }

      const coords = coordenadasSeleccionadas.get("localizacionEditar") || {};
      const evento = {
        titulo,
        descripcion,
        fechaInicio,
        fechaFin,
        localizacion: document
          .getElementById("localizacionEditar")
          .value.trim(),
        latitud: coords.lat ?? null,
        longitud: coords.lon ?? null,
        foto: null,
        idUsuario:
          Number(document.getElementById("organizadoresEditar").value) || null,
        idCategoria:
          Number(document.getElementById("categoriasEditar").value) || null,
      };

      const formData = new FormData();
      formData.append("evento", JSON.stringify(evento));
      const file = document.getElementById("formFileEditar")?.files?.[0];
      if (file && !validarImagen(file)) return;
      if (file) formData.append("imagen", file);

      editarEvento(formEditar.dataset.id, formData);
      formEditar.classList.add("was-validated");
    },
    false,
  );

  document.getElementById("fotoEvento").addEventListener("change", function () {
    if (!validarImagen(this.files[0])) {
      this.value = "";
    }
  });

  document
    .getElementById("formFileEditar")
    .addEventListener("change", function () {
      if (!validarImagen(this.files[0])) {
        this.value = "";
      }
    });
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Limpiar buscador al crear/editar/eliminar evento para mostrar cambios
function limpiarBuscador() {
  document.getElementById("buscador").value = "";
}

// Cargar eventos con paginación
async function cargarEventos() {
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetchConAuth(
      URL_BASE + `eventos/paginated?page=${paginaActual}&size=10`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      },
    );

    const data = await resp.json();
    mostrarEventos(data["content"], data["totalPages"]);
  } catch (error) {
    console.error("Error al cargar los eventos:", error);
  } finally {
    body.classList.remove("loading");
    loader.style.display = "none";
  }
}

// Buscar eventos
async function buscarEvento(textoBusqueda) {
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetchConAuth(
      URL_BASE + `eventos/search?q=${textoBusqueda}&limit=10`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
      },
    );

    if (!resp.ok) {
      throw new Error("Error al obtener los categorías");
    }

    const data = await resp.json();
    mostrarEventos(data);
  } catch (error) {
    console.error("Error al buscar el evento", error);
  } finally {
    body.classList.remove("loading");
    loader.style.display = "none";
  }
}

// Mostrar eventos en la tabla
function mostrarEventos(data, numeroPaginas = 0) {
  const tabla = document.getElementById("listadoEventos");
  cantidadPaginacion = numeroPaginas;

  // Mostrar mensaje si no hay eventos y limpiar tabla
  const eventosVacio = document.getElementById("eventos-vacio");
  if (data.length === 0) {
    eventosVacio.classList.remove("d-none");
    eventosVacio.classList.add("d-block");
    tabla.innerHTML = "";
    return;
  } else {
    eventosVacio.classList.remove("d-block");
    eventosVacio.classList.add("d-none");
  }

  tabla.innerHTML = "";
  data.sort((a, b) => a.id - b.id);
  data.forEach((evento) => {
    const tr = document.createElement("tr");
    const tdId = document.createElement("td");
    const tdTitulo = document.createElement("td");
    const tdDescripcion = document.createElement("td");
    const tdFechaInicio = document.createElement("td");
    const tdFechaFin = document.createElement("td");
    const tdLocalizacion = document.createElement("td");
    const textoTitulo = document.createElement("div");
    const textoDescripcion = document.createElement("div");
    const textoLocalizacion = document.createElement("div");
    tdId.textContent = evento.id;
    textoTitulo.textContent = evento.titulo;
    textoDescripcion.textContent = evento.descripcion;
    textoLocalizacion.textContent = evento.localizacion;
    textoTitulo.classList.add("texto-3lineas");
    textoDescripcion.classList.add("descripcion-corta");
    textoLocalizacion.classList.add("texto-3lineas");
    tdTitulo.appendChild(textoTitulo);
    tdDescripcion.appendChild(textoDescripcion);
    tdLocalizacion.appendChild(textoLocalizacion);
    tdFechaInicio.textContent = formatearFecha(evento["fechaInicio"]);
    tdFechaFin.textContent = formatearFecha(evento["fechaFin"]);
    tdTitulo.classList.add("text-light");
    tdDescripcion.classList.add("text-light");
    tdFechaInicio.classList.add("text-light");
    tdFechaFin.classList.add("text-light");
    tdLocalizacion.classList.add("text-light");
    tr.appendChild(tdId);
    tr.appendChild(tdTitulo);
    tr.appendChild(tdDescripcion);
    tr.appendChild(tdFechaInicio);
    tr.appendChild(tdFechaFin);
    tr.appendChild(tdLocalizacion);
    tr.classList.add("evento");
    const tdAcciones = document.createElement("td");
    const divGrupo = document.createElement("div");
    divGrupo.className = "btn-group";
    divGrupo.setAttribute("role", "group");

    // Botón ver
    const btnVer = document.createElement("button");
    btnVer.className = "btn btn-sm btn-primary";
    btnVer.innerHTML = '<i class="fa-solid fa-eye"></i>';
    btnVer.setAttribute("data-bs-toggle", "modal");
    btnVer.setAttribute("data-bs-target", "#modalVerEvento");
    btnVer.addEventListener("click", function () {
      document.getElementById("contenidoModalEvento").innerHTML = `
        <h4 class="text-light mb-0 text-center mb-2">${evento.titulo || "-"}</h4>
        <div class="text-center mb-4">
          ${
            evento.foto
              ? `<img src="${evento.foto}" alt="${evento.titulo}" class="img-fluid img-thumbnail img-evento-modal mb-2" />`
              : `<div class="avatar-placeholder mx-auto mb-2"><i class="fas fa-calendar-days"></i></div>`
          }
        </div>

        <div class="card bg-dark border-secondary mb-3">
          <div class="card-header text-light border-secondary">
            <i class="fas fa-calendar-days me-2"></i>
            Información básica
          </div>
          <div class="card-body">
            <div class="row g-3">
              <div class="col-md-12">
                <p class="mb-1 text-muted">Descripción</p>
                <p class="mb-0 text-light fw-semibold">${evento.descripcion || "-"}</p>
              </div>
              <div class="col-md-6">
                <p class="mb-1 text-muted">Localización</p>
                <p class="mb-0 text-light fw-semibold">${evento.localizacion || "-"}</p>
              </div>
              <div class="col-md-6">
                <p class="mb-1 text-muted">Categoría</p>
                <p class="mb-0 text-light fw-semibold">${evento.nombreCategoria || "-"}</p>
              </div>
              <div class="col-md-6">
                <p class="mb-1 text-muted">Organizador</p>
                <p class="mb-0 text-light fw-semibold">${evento.emailUsuario || "-"}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-dark border-secondary mb-3">
          <div class="card-header text-light border-secondary">
            <i class="fas fa-clock me-2"></i>
            Fechas y horarios
          </div>
          <div class="card-body">
            <div class="row g-3">
              <div class="col-md-6">
                <p class="mb-1 text-muted">Fecha de inicio</p>
                <p class="mb-0 text-light fw-semibold">${formatearFecha(evento.fechaInicio) || "-"}</p>
              </div>
              <div class="col-md-6">
                <p class="mb-1 text-muted">Fecha de fin</p>
                <p class="mb-0 text-light fw-semibold">${formatearFecha(evento.fechaFin) || "-"}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-dark border-secondary">
          <div class="card-header text-light border-secondary">
            <i class="fas fa-map-marker-alt me-2"></i>
            Ubicación
          </div>
          <div class="card-body">
            ${mapa}
          </div>
        </div>
      `;
    });

    let mapa = "";
    if (evento.latitud && evento.longitud) {
      const lat = parseFloat(evento.latitud);
      const lon = parseFloat(evento.longitud);
      const delta = 0.0002; // Menos zoom: aumentar este valor si quieres ver más área
      const bbox = [
        lon - delta, // oeste
        lat - delta, // sur
        lon + delta, // este
        lat + delta, // norte
      ].join(",");
      mapa = `
        <div style="max-width:320px;margin:0 auto;">
          <iframe
            style="width:100%;height:280px;border-radius:10px;border:0;display:block"
            frameborder="0"
            scrolling="no"
            marginheight="0"
            marginwidth="0"
            src="https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lon}">
          </iframe>
        </div>
      `;
    } else {
      mapa =
        '<div class="text-center text-warning">No hay coordenadas para este evento.</div>';
    }

    // Botón editar
    const btnEditar = document.createElement("button");
    btnEditar.className = "btn btn-sm btn-warning";
    btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
    btnEditar.setAttribute("data-id", evento.id);
    btnEditar.setAttribute("data-bs-toggle", "modal");
    btnEditar.setAttribute("data-bs-target", "#modalEditarEvento");
    btnEditar.addEventListener("click", function () {
      document.getElementById("formEditarEvento").dataset.id = evento.id;
      document.getElementById("tituloEventoEditar").value = evento.titulo;
      document.getElementById("descripcionEventoEditar").value =
        evento.descripcion;
      document.getElementById("fechaInicioEditar").value =
        evento.fechaInicio.substring(0, 10);
      document.getElementById("horaInicioEditar").value =
        evento.fechaInicio.substring(11, 16);
      document.getElementById("fechaFinEditar").value =
        evento.fechaFin.substring(0, 10);
      document.getElementById("horaFinEditar").value =
        evento.fechaFin.substring(11, 16);
      const selectOrganizadoresEditar = document.getElementById(
        "organizadoresEditar",
      );
      const opcionOrganizador = Array.from(
        selectOrganizadoresEditar.options,
      ).find((opt) => opt.dataset.email === evento.emailUsuario);

      if (opcionOrganizador) {
        selectOrganizadoresEditar.value = opcionOrganizador.value;
      } else {
        selectOrganizadoresEditar.value = "";
      }
      document.getElementById("localizacionEditar").value = evento.localizacion;
      const selectCategoriasEditar =
        document.getElementById("categoriasEditar");
      selectCategoriasEditar.value = evento.nombreCategoria;
      if (selectCategoriasEditar.value !== evento.nombreCategoria) {
        const opcion = Array.from(selectCategoriasEditar.options).find(
          (opt) =>
            opt.textContent.trim() === String(evento.nombreCategoria).trim(),
        );
        if (opcion) {
          selectCategoriasEditar.value = opcion.value;
        }
      }
      document.getElementById("imagenEvento").src = evento.foto;
    });

    // Botón eliminar
    const btnEliminar = document.createElement("button");
    btnEliminar.className = "btn btn-sm btn-danger";
    btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
    btnEliminar.setAttribute("data-id", evento.id);
    btnEliminar.setAttribute("data-nombre", evento.titulo);
    btnEliminar.addEventListener("click", function () {
      eliminarEvento(this.dataset.id, this.dataset.nombre);
    });

    divGrupo.appendChild(btnVer);
    divGrupo.appendChild(btnEditar);
    divGrupo.appendChild(btnEliminar);
    tdAcciones.appendChild(divGrupo);
    tr.appendChild(tdAcciones);
    tabla.appendChild(tr);
  });

  cargarPaginacion(numeroPaginas, paginaActual);
}

// Función para cargar paginación
function cargarPaginacion(totalPaginas, paginaActual) {
  const lista = document.getElementById("paginacion");
  const btnAnterior = document.getElementById("btnAnterior");
  const btnSiguiente = document.getElementById("btnSiguiente");

  if (totalPaginas === 0) {
    lista.style.display = "none";
    return;
  }

  lista.style.display = "flex";

  lista
    .querySelectorAll(".pagina-numero, .ellipsis")
    .forEach((el) => el.remove());

  const MAX_VISIBLE = 10;
  const mitad = Math.floor(MAX_VISIBLE / 2);

  let inicio = Math.max(0, paginaActual - mitad);
  let fin = Math.min(totalPaginas - 1, inicio + MAX_VISIBLE - 1);

  if (fin - inicio < MAX_VISIBLE - 1) {
    inicio = Math.max(0, fin - MAX_VISIBLE + 1);
  }

  btnAnterior.classList.toggle("disabled", paginaActual === 0);

  if (inicio > 0) {
    insertarPagina(lista, 0);
    insertarPuntos(lista);
  }

  for (let i = inicio; i <= fin; i++) {
    insertarPagina(lista, i, paginaActual);
  }

  if (fin < totalPaginas - 1) {
    insertarPuntos(lista);
    insertarPagina(lista, totalPaginas - 1, paginaActual);
  }

  btnSiguiente.classList.toggle("disabled", paginaActual === totalPaginas - 1);
}

// Función para insertar página nueva
function insertarPagina(lista, indice, paginaActual) {
  const li = document.createElement("li");
  li.classList.add("page-item", "pagina-numero");

  if (indice === paginaActual) li.classList.add("active");

  const a = document.createElement("a");
  a.classList.add("page-link");
  a.href = "#";
  a.textContent = indice + 1;

  a.addEventListener("click", (e) => {
    e.preventDefault();
    avanzarPagina(indice);
  });

  li.appendChild(a);
  lista.insertBefore(li, document.getElementById("btnSiguiente"));
}

// Función para insertar puntos suspensivos
function insertarPuntos(lista) {
  const li = document.createElement("li");
  li.classList.add("page-item", "ellipsis");

  const span = document.createElement("span");
  span.classList.add("page-link");
  span.textContent = "…";

  li.appendChild(span);
  lista.insertBefore(li, document.getElementById("btnSiguiente"));
}

// Función para actualizar estado de botones anterior/siguiente
function actualizarBotones() {
  const btnAnterior = document.getElementById("btnAnterior");
  const btnSiguiente = document.getElementById("btnSiguiente");

  btnAnterior.classList.toggle("disabled", paginaActual === 0);
  btnSiguiente.classList.toggle(
    "disabled",
    paginaActual === cantidadPaginacion - 1,
  );
}

// Función para avanzar a página específica
function avanzarPagina(indice) {
  paginaActual = indice;
  cargarEventos();
  actualizarBotones();
}

// Funciones para obtener categorías
async function obtenerCategorias() {
  const selectCrear = document.getElementById("categorias");
  const selectEditar = document.getElementById("categoriasEditar");

  try {
    const resp = await fetchConAuth(URL_BASE + "categorias/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    if (!resp.ok) {
      throw new Error("Error al obtener los categorías");
    }

    const data = await resp.json();
    const selects = [selectCrear, selectEditar].filter(Boolean);

    selects.forEach((select) => {
      const placeholder = select.querySelector("option[value='']");
      select.innerHTML = "";

      if (placeholder) {
        select.appendChild(placeholder);
      }

      data.forEach((categoria) => {
        const opt = document.createElement("option");
        opt.value = categoria.id;
        opt.textContent = categoria.nombre;
        select.appendChild(opt);
      });
    });
  } catch (error) {
    console.error("Error al cargar las categorías:", error);
  }
}

// Función para obtener organizadores
async function obtenerOrganizadores() {
  const selectCrear = document.getElementById("organizadores");
  const selectEditar = document.getElementById("organizadoresEditar");

  try {
    const resp = await fetchConAuth(URL_BASE + "usuarios/organizers", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    if (!resp.ok) {
      throw new Error("Error al obtener los organizadores");
    }

    const data = await resp.json();
    const selects = [selectCrear, selectEditar].filter(Boolean);

    selects.forEach((select) => {
      const placeholder = select.querySelector("option[value='']");
      select.innerHTML = "";

      if (placeholder) {
        select.appendChild(placeholder);
      }

      data.forEach((organizador) => {
        const opt = document.createElement("option");
        opt.value = organizador.id;
        opt.textContent = organizador.nombre + " " + organizador.apellidos;
        opt.dataset.email = organizador.email;
        select.appendChild(opt);
      });
    });
  } catch (error) {
    console.error("Error al cargar los organizadores:", error);
  }
}

// Función para crear evento
async function crearEvento(datosFormulario) {
  try {
    const options = {
      method: "POST",
      credentials: "include",
      body: datosFormulario,
    };

    const resp = await fetchConAuth(URL_BASE + "eventos/add", options);
    const respuesta = await resp.json();

    if (resp.status === 201) {
      mostrarAlerta("success", "Evento creado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearEvento"),
      );

      modal.hide();
      limpiarFormularioCrearEvento();
    } else {
      mostrarAlerta("error", "Error al crear el evento: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el evento:", error);
  } finally {
    limpiarBuscador();
    cargarEventos();
  }
}

// Función para editar evento
async function editarEvento(id, datosFormulario) {
  try {
    const options = {
      method: "PUT",
      credentials: "include",
      body: datosFormulario,
    };

    const resp = await fetchConAuth(URL_BASE + "eventos/update/" + id, options);
    const respuesta = await resp.json();

    if (resp.status === 200) {
      mostrarAlerta("success", "Evento editado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarEvento"),
      );

      modal.hide();
    } else {
      mostrarAlerta("error", "Error al editar el evento: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al editar el evento:", error);
  } finally {
    limpiarBuscador();
    cargarEventos();
  }
}

// Función para eliminar evento
async function eliminarEvento(id, nombre) {
  Swal.fire({
    title: `¿Estás seguro que deseas eliminar el evento \"` + nombre + `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar evento",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
          credentials: "include",
        };

        const resp = await fetchConAuth(URL_BASE + "eventos/delete/" + id, options);

        if (resp.status === 204) {
          mostrarAlerta("success", "Evento eliminado correctamente");
        } else {
          const respuesta = await resp.text();
          mostrarAlerta("error", "Error al eliminar el evento: " + respuesta);
        }
      } catch (error) {
        console.error("Error al eliminar el evento:", error);
      } finally {
        limpiarBuscador();
        cargarEventos();
      }
    }
  });
}

// Función para formatear fecha en formato dd/mm/yyyy - hh:mm
function formatearFecha(fechaISO) {
  const fecha = new Date(fechaISO);
  const dia = fecha.getDate().toString().padStart(2, "0");
  const mes = (fecha.getMonth() + 1).toString().padStart(2, "0");
  const anio = fecha.getFullYear();
  const hora = fecha.getHours().toString().padStart(2, "0");
  const minutos = fecha.getMinutes().toString().padStart(2, "0");
  return `${dia}/${mes}/${anio} - ${hora}:${minutos}`;
}

// Botones paginación
document.getElementById("btnAnterior").addEventListener("click", (e) => {
  e.preventDefault();
  if (paginaActual > 0) {
    paginaActual--;
    cargarEventos();
  }
});

document.getElementById("btnSiguiente").addEventListener("click", (e) => {
  e.preventDefault();
  if (paginaActual < cantidadPaginacion - 1) {
    paginaActual++;
    cargarEventos();
  }
});

// Función que realiza la llamada a la API para obtener los lugares buscados.
async function buscarLugar(textoBusqueda) {
  try {
    const texto = encodeURIComponent(
      `${textoBusqueda} Mérida, Badajoz, España`,
    );
    const resp = await fetch(`/api/geoapify?text=${encodeURIComponent(textoBusqueda)}`);
    if (!resp.ok) throw new Error("Geoapify error");
    const data = await resp.json();
    return data?.features || [];
  } catch (error) {
    console.error("Error al obtener la Ubicación:", error);
    return [];
  }
}

// Función que carga y muestra los resultados obtenidos en la búsqueda
function inicializarAutocompleteLocalizacion(inputId, listId) {
  const input = document.getElementById(inputId);
  const lista = document.getElementById(listId);

  if (!input || !lista) return;

  let timerId;

  input.addEventListener("input", () => {
    clearTimeout(timerId);
    const texto = input.value.trim();
    coordenadasSeleccionadas.delete(inputId);

    if (texto.length < 2) {
      limpiarResultadosLocalizacion(lista);
      return;
    }

    timerId = setTimeout(async () => {
      const consulta = texto;
      renderizarCargandoLocalizacion(lista);
      const resultados = await buscarLugar(consulta);
      if (input.value.trim() !== consulta) return;
      renderizarResultadosLocalizacion(lista, resultados, input);
    }, 500);
  });

  input.addEventListener("focus", () => {
    if (lista.children.length > 0) {
      lista.classList.remove("d-none");
    }
  });

  document.addEventListener("click", (event) => {
    if (event.target === input || lista.contains(event.target)) return;
    limpiarResultadosLocalizacion(lista);
  });
}

// Función para vaciar los resultados de búsqueda
function limpiarResultadosLocalizacion(lista) {
  lista.innerHTML = "";
  lista.classList.add("d-none");
}

// Funciones para mostrar mensajes mientras están cargando los resultados
function renderizarCargandoLocalizacion(lista) {
  lista.innerHTML = `
    <div class="list-group-item localizacion-loading">
      <span class="localizacion-spinner"></span>
      Buscando ubicaciones...
    </div>
  `;
  lista.classList.remove("d-none");
}

function renderizarMensajeLocalizacion(lista, mensaje) {
  lista.innerHTML = `
    <div class="list-group-item localizacion-empty">
      ${mensaje}
    </div>
  `;
  lista.classList.remove("d-none");
}

// Función para mostrar los reultados obtenidos
function renderizarResultadosLocalizacion(lista, resultados, input) {
  lista.innerHTML = "";

  if (!Array.isArray(resultados) || resultados.length === 0) {
    renderizarMensajeLocalizacion(lista, "No hay resultados para esta búsqueda.");
    return;
  }

  resultados.slice(0, 6).forEach((item) => {
    const categoria = String(item?.properties?.category || "").toLowerCase();
    const texto =
      item?.properties?.formatted ||
      item?.properties?.address_line1 ||
      "Ubicación";
    const coords = {
      lat: Number(item?.properties?.lat ?? item?.geometry?.coordinates?.[1]),
      lon: Number(item?.properties?.lon ?? item?.geometry?.coordinates?.[0]),
    };

    const boton = document.createElement("button");
    boton.type = "button";
    boton.className = "list-group-item list-group-item-action localizacion-item";
    boton.innerHTML = `<i class="fa-solid fa-signs-post"></i> </i>${texto}`;
    boton.addEventListener("click", () => {
      input.value = texto;
      if (Number.isFinite(coords.lat) && Number.isFinite(coords.lon)) {
        coordenadasSeleccionadas.set(input.id, coords);
      } else {
        coordenadasSeleccionadas.delete(input.id);
      }
      limpiarResultadosLocalizacion(lista);
    });

    lista.appendChild(boton);
  });

  lista.classList.remove("d-none");
}

// Función para limpiar el formulario de creación de eventos
function limpiarFormularioCrearEvento() {
  const form = document.getElementById("formAgregarEvento");

  if (!form) return;

  // Limpia todos los campos del formulario, incluido el input file
  form.reset();

  // Quita estilos de validación de Bootstrap
  form.classList.remove("was-validated");

  // Limpia resultados del autocompletado de localización
  const listaLocalizacion = document.getElementById("localizacionResultados");
  if (listaLocalizacion) {
    limpiarResultadosLocalizacion(listaLocalizacion);
  }

  // Limpia coordenadas seleccionadas de la localización del formulario crear
  coordenadasSeleccionadas.delete("localizacion");
}