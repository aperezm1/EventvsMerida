// ==========================================================================
// VARIABLES
// ==========================================================================

const URL_BASE = window.APP_CONFIG.API_BASE;

// ==========================================================================
// CONTENIDO DEL DOM
// ==========================================================================

window.addEventListener("DOMContentLoaded", async () => {
  const ok = await requireAuth();
  if (!ok) return;

  cargarOrganizadores();

  // Formulario agregar organizador
  const form = document.getElementById("formAgregarOrganizador");
  if (form) {
    form.addEventListener(
      "submit",
      function (event) {
        event.preventDefault();

        const contrasenia = document.getElementById("contrasena").value;
        const confirmarContrasenia = document.getElementById("confirmarContrasena").value;

        validarEdad(document.getElementById("fechaNacimiento"), 14, 100, true);

        if (!form.checkValidity()) {
          event.stopPropagation();
        } else if (contrasenia !== confirmarContrasenia) {
          event.stopPropagation();
          mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
        } else {
          const organizador = {
            nombre: document.getElementById("nombre").value,
            apellidos: document.getElementById("apellidos").value,
            fechaNacimiento: formatearFecha(
              document.getElementById("fechaNacimiento").value,
            ),
            email: document.getElementById("correo").value,
            telefono: document.getElementById("telefono").value,
            password: contrasenia,
            idRol: 2,
          };

          const formData = new FormData();
          formData.append("usuario", JSON.stringify(organizador));

          const fotoFile = document.getElementById("fotoOrganizador").files[0];
          if (fotoFile) {
            formData.append("foto", fotoFile);
          }

          crearOrganizador(formData);
        }

        form.classList.add("was-validated");
      },
      false,
    );
  }

  // Formulario editar organizador
  const formEditar = document.getElementById("formEditarOrganizador");
  let contrasenia = "";

  formEditar.addEventListener(
    "submit",
    function (event) {
      event.preventDefault();

      validarEdad(document.getElementById("fechaNacimiento"), 14, 100, false);
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const organizador = {
          nombre: document.getElementById("nombreEditar").value,
          apellidos: document.getElementById("apellidosEditar").value,
          fechaNacimiento: formatearFecha(
            document.getElementById("fechaNacimientoEditar").value,
          ),
          email: document.getElementById("correoEditar").value,
          telefono: document.getElementById("telefonoEditar").value,
          password: contraseniaModificada ? contrasenia : null,
          idRol: 2,
        };

        const formData = new FormData();
        formData.append("usuario", JSON.stringify(organizador));

        const fotoFile = document.getElementById("formFileEditar")?.files?.[0];
        if (fotoFile) {
          formData.append("foto", fotoFile);
        }

        editarOrganizador(formEditar.dataset.id, formData);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );

  // Formulario editar contraseña organizador
  let contraseniaModificada = false;

  const formEditarContrasenia = document.getElementById(
    "formEditarContrasenia",
  );

  formEditarContrasenia.addEventListener(
    "submit",
    function (event) {
      const contraseniaEditar =
        document.getElementById("contraseniaEditar").value;
      const confirmarContraseniaEditar = document.getElementById(
        "confirmarContraseniaEditar",
      ).value;

      if (!formEditarContrasenia.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditarContrasenia.classList.add("was-validated");
      } else if (contraseniaEditar !== confirmarContraseniaEditar) {
        event.stopPropagation();
        event.preventDefault();
        mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
      } else {
        event.preventDefault();
        contrasenia = document.getElementById("contraseniaEditar").value;
        contraseniaModificada = true;

        bootstrap.Modal.getInstance(
          document.getElementById("modalEditarContrasenia"),
        ).hide();

        mostrarAlerta("info", "Contraseña actualizada pendiente de guardar");

        const modalEditarContrasenia = document.getElementById("modalEditarContrasenia");

        modalEditarContrasenia.addEventListener("hidden.bs.modal", function () {
          const modalEditarOrganizador = new bootstrap.Modal(
            document.getElementById("modalEditarOrganizador"),
          );
          modalEditarOrganizador.show();
        });
      }
      formEditarContrasenia.classList.add("was-validated");
    },
    false,
  );

  // Limpia validaciones y campos al cerrar el modal de usuario
  const modalOrganizador = document.getElementById("modalCrearOrganizador");
  if (modalOrganizador) {
    modalOrganizador.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formAgregarOrganizador");
      if (form) {
        form.classList.remove("was-validated");
        form.reset();
      }
    });
  }

  const modalEditarOrganizador = document.getElementById(
    "modalEditarOrganizador",
  );
  if (modalEditarOrganizador) {
    modalEditarOrganizador.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formEditarOrganizador");
      if (form) {
        form.classList.remove("was-validated");
      }
    });
  }

  if (modalEditarOrganizador) {
    modalEditarOrganizador.addEventListener("hidden.bs.modal", function () {
      const inputImagen = document.getElementById("formFileEditar");
      if (inputImagen) inputImagen.value = "";
      formEditar.classList.remove("was-validated");
    });
  }

  document.getElementById("fotoOrganizador").addEventListener("change", function () {
    if(!validarImagen(this.files[0])){
      this.value = "";
    }
  });

  document.getElementById("formFileEditar").addEventListener("change", function () {
    if(!validarImagen(this.files[0])){
      this.value = "";
    }
  });

  configurarMostrarContraseniasFormulario(
    ["contrasenia", "confirmarContrasenia"],
    [
      {
        idBoton: "toggleContrasenia",
        idIcono: "iconoContrasena",
      },
      {
        idBoton: "toggleConfirmarContrasena",
        idIcono: "iconoConfirmarContrasena",
      },
    ],
  );

  configurarMostrarContraseniasFormulario(
    ["contraseniaEditar", "confirmarContraseniaEditar"],
    [
      {
        idBoton: "toggleContraseniaEditar",
        idIcono: "iconoContrasenaEditar",
      },
      {
        idBoton: "toggleConfirmarContraseniaEditar",
        idIcono: "iconoConfirmarContrasenaEditar",
      },
    ],
  );
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función que carga los organizadores desde la API y los muestra en la tabla
async function cargarOrganizadores() {
  const tabla = document.getElementById("listadoOrganizadores");
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    if (loader) {
      loader.style.display = "flex";
      body.classList.add("loading");
    }

    const resp = await fetch(URL_BASE + "usuarios/organizers", {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay usuarios y limpiar tabla
    const usuariosVacio =
      document.getElementById("usuarios-vacio") ||
      document.getElementById("organizadores-vacio");

    if (data.length === 0) {
      if (usuariosVacio) {
        usuariosVacio.classList.remove("d-none");
        usuariosVacio.classList.add("d-block");
      }
      tabla.innerHTML = "";
      return;
    } else {
      if (usuariosVacio) {
        usuariosVacio.classList.remove("d-block");
        usuariosVacio.classList.add("d-none");
      }
    }

    tabla.innerHTML = "";
    data.sort((a, b) => a.id - b.id);

    data.forEach((organizador) => {
      const tr = document.createElement("tr");
      const tdId = document.createElement("td");
      const textoId = document.createElement("div");
      const tdNombre = document.createElement("td");
      const textoNombre = document.createElement("div");
      const tdApellidos = document.createElement("td");
      const textoApellidos = document.createElement("div");
      const tdfechaNac = document.createElement("td");
      const textofechaNac = document.createElement("div");
      const tdCorreo = document.createElement("td");
      const textoCorreo = document.createElement("div");
      const tdTelefono = document.createElement("td");
      const textoTelefono = document.createElement("div");
      textoId.textContent = organizador.id;
      textoNombre.textContent = organizador.nombre;
      textoApellidos.textContent = organizador.apellidos;
      textofechaNac.textContent = formatearFecha(organizador.fechaNacimiento);
      textoCorreo.textContent = organizador.email;
      textoTelefono.textContent = organizador.telefono;
      tdId.appendChild(textoId);
      tdNombre.appendChild(textoNombre);
      tdApellidos.appendChild(textoApellidos);
      tdfechaNac.appendChild(textofechaNac);
      tdCorreo.appendChild(textoCorreo);
      tdTelefono.appendChild(textoTelefono);
      tr.appendChild(tdId);
      tr.appendChild(tdNombre);
      tr.appendChild(tdApellidos);
      tr.appendChild(tdfechaNac);
      tr.appendChild(tdCorreo);
      tr.appendChild(tdTelefono);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón ver
      const btnVer = document.createElement("button");
      btnVer.className = "btn btn-sm btn-primary";
      btnVer.innerHTML = '<i class="fa-solid fa-eye"></i>';
      btnVer.setAttribute("data-bs-toggle", "modal");
      btnVer.setAttribute("data-bs-target", "#modalVerOrganizador");
      btnVer.addEventListener("click", async function () {
        const detalle = await obtenerOrganizadorPorId(organizador.id);
        if (detalle) {
          verOrganizador(detalle);
        }
      });

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", organizador.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarOrganizador");
      btnEditar.addEventListener("click", async function () {
        const detalle = await obtenerOrganizadorPorId(organizador.id);
        const data = detalle || organizador;

        document.getElementById("formEditarOrganizador").dataset.id = data.id;
        document.getElementById("nombreEditar").value = data.nombre || "";
        document.getElementById("apellidosEditar").value = data.apellidos || "";
        document.getElementById("fechaNacimientoEditar").value = data.fechaNacimiento || "";
        document.getElementById("correoEditar").value = data.email || "";
        document.getElementById("telefonoEditar").value = data.telefono || "";

        const imagenOrganizador = document.getElementById("fotoOrganizadorEditar");
        const sinFotoOrganizador =
          document.getElementById("sinFotoOrganizador");

        if (data.fotoUrl) {
          imagenOrganizador.src = data.fotoUrl;
          imagenOrganizador.style.display = "block";
          sinFotoOrganizador.style.display = "none";
        } else {
          imagenOrganizador.removeAttribute("src");
          imagenOrganizador.style.display = "none";
          sinFotoOrganizador.style.display = "flex";
        }
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", organizador.id);
      btnEliminar.setAttribute("data-nombre", organizador.nombre);
      btnEliminar.setAttribute("data-apellidos", organizador.apellidos);
      btnEliminar.addEventListener("click", function () {
        eliminarOrganizador(this.dataset.id, this.dataset.nombre, this.dataset.apellidos);
      });

      divGrupo.appendChild(btnVer);
      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar los usuarios:", error);
  } finally {
    if (loader) {
      loader.style.display = "none";
      body.classList.remove("loading");
    }
  }
}

// Función que crea un nuevo organizador
async function crearOrganizador(datosFormulario) {
  try {
    const options = {
      method: "POST",
      credentials: "include",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "usuarios/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Organizador creado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearOrganizador"),
      );
      modal.hide();
    } else {
      mostrarAlerta(
        "error",
        "Error al crear el organizador: " + respuesta.error,
      );
    }
  } catch (error) {
    console.error("Error al crear el organizador:", error);
  } finally {
    await cargarOrganizadores();
  }
}

// Función que edita un organizador existente
async function editarOrganizador(id, datosFormulario) {
  try {
    const options = {
      method: "PUT",
      credentials: "include",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "usuarios/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Usuario editado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarOrganizador"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al editar el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al editar el evento:", error);
  } finally {
    await cargarOrganizadores();
  }
}

// Función que elimina un organizador
async function eliminarOrganizador(id, nombre, apellidos) {
  Swal.fire({
    title: `¿Estás seguro que deseas eliminar el organizador \"` + nombre  + " " + apellidos + `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar organizador",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };

        const resp = await fetch(URL_BASE + "usuarios/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Organizador eliminado correctamente");
        } else {
          const errorTexto = await resp.text();
          mostrarAlerta("error", "Error al eliminar el organizador: " + errorTexto);
        }
      } catch (error) {
        console.error("Error al eliminar el organizador:", error);
      } finally {
        await cargarOrganizadores();
      }
    }
  });
}

// Función que obtiene los detalles de un organizador por su ID
async function obtenerOrganizadorPorId(id) {
  try {
    const resp = await fetch(URL_BASE + "usuarios/" + id, {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!resp.ok) {
      throw new Error("No se pudo obtener el organizador");
    }

    return await resp.json();
  } catch (error) {
    console.error("Error al obtener el organizador:", error);
    mostrarAlerta("error", "No se pudo cargar el organizador");
    return null;
  }
}

// Función que muestra los detalles de un organizador en el modal de visualización
function verOrganizador(organizador) {
  const tieneFoto =
    organizador.fotoUrl &&
    organizador.fotoUrl.trim() !== "" &&
    organizador.fotoUrl !== "null" &&
    organizador.fotoUrl !== "undefined";

  let contenido = `
    <div id="contenidoModalOrganizador">
      <div class="text-center mb-4">
        <div class="avatar-wrapper mx-auto mb-2">
          ${
            tieneFoto
              ? `<img
                  src="${organizador.fotoUrl}"
                  alt="Foto de ${organizador.nombre}"
                  class="avatar-usuario-modal"
                />`
              : `<div class="avatar-placeholder d-flex">
                  <i class="fas fa-user"></i>
                </div>`
          }
        </div>

        <h4 class="text-light mb-0">
          ${organizador.nombre || "-"} ${organizador.apellidos || ""}
        </h4>

        <small class="text-muted">
          Información del organizador
        </small>
      </div>

      <div class="card bg-dark border-secondary mb-3">
        <div class="card-header text-light border-secondary">
          <i class="fas fa-id-card me-2"></i>
          Datos personales
        </div>

        <div class="card-body">
          <div class="row g-3">
            <div class="col-md-6">
              <p class="mb-1 text-muted">Nombre</p>
              <p class="mb-0 text-light fw-semibold">
                ${organizador.nombre || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Apellidos</p>
              <p class="mb-0 text-light fw-semibold">
                ${organizador.apellidos || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Fecha de nacimiento</p>
              <p class="mb-0 text-light fw-semibold">
                ${formatearFecha(organizador.fechaNacimiento) || "-"}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="card bg-dark border-secondary">
        <div class="card-header text-light border-secondary">
          <i class="fas fa-address-book me-2"></i>
          Datos de contacto
        </div>

        <div class="card-body">
          <div class="row g-3">
            <div class="col-md-6">
              <p class="mb-1 text-muted">Email</p>
              <p class="mb-0 text-light fw-semibold">
                ${organizador.email || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Teléfono</p>
              <p class="mb-0 text-light fw-semibold">
                ${organizador.telefono || "-"}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  document.getElementById("contenidoModalOrganizador").innerHTML = contenido;
}