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

  await cargarUsuarios();

  // Formulario de creación de usuario
  const form = document.getElementById("formAgregarUsuario");
  const fechaNacimientoInput = document.getElementById("fechaNacimiento");

  if (fechaNacimientoInput) {
    fechaNacimientoInput.addEventListener("input", function () {
      validarEdad(this, 14, 100, true);
    });
  }

  if (form) {
    form.addEventListener(
      "submit",
      function (event) {
        event.preventDefault();

        validarEdad(fechaNacimientoInput, 14, 100, true);

        const contrasenia = document.getElementById("contrasena").value;
        const confirmarContrasenia = document.getElementById(
          "confirmarContrasena",
        ).value;

        if (!form.checkValidity()) {
          event.stopPropagation();
        } else if (contrasenia !== confirmarContrasenia) {
          event.stopPropagation();
          mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
        } else {
          const usuario = {
            nombre: document.getElementById("nombre").value,
            apellidos: document.getElementById("apellidos").value,
            fechaNacimiento: formatearFecha(
              document.getElementById("fechaNacimiento").value,
            ),
            email: document.getElementById("correo").value,
            telefono: document.getElementById("telefono").value,
            password: contrasenia,
            idRol: 1,
          };

          const formData = new FormData();
          formData.append("usuario", JSON.stringify(usuario));

          const fotoFile = document.getElementById("fotoUsuario").files[0];
          if (fotoFile) {
            formData.append("foto", fotoFile);
          }

          crearUsuario(formData);
        }

        form.classList.add("was-validated");
      },
      false,
    );
  }

  // Formulario de edición de usuario
  const formEditar = document.getElementById("formEditarUsuario");
  const fechaNacimientoEditarInput = document.getElementById("fechaNacimientoEditar");
  let contrasenia = "";

  if (fechaNacimientoEditarInput) {
    fechaNacimientoEditarInput.addEventListener("input", function () {
      validarEdad(this, 14, 100, false);
    });
  }

  if (formEditar) {
    formEditar.addEventListener(
      "submit",
      function (event) {
        event.preventDefault();

        validarEdad(fechaNacimientoEditarInput, 14, 100, false);

        if (!formEditar.checkValidity()) {
          event.stopPropagation();
          formEditar.classList.add("was-validated");
        } else {
          const usuario = {
            nombre:
              document.getElementById("nombreEditar").value === ""
                ? null
                : document.getElementById("nombreEditar").value,
            apellidos:
              document.getElementById("apellidosEditar").value === ""
                ? null
                : document.getElementById("apellidosEditar").value,
            fechaNacimiento:
              formatearFecha(
                document.getElementById("fechaNacimientoEditar").value,
              ) === ""
                ? null
                : formatearFecha(
                    document.getElementById("fechaNacimientoEditar").value,
                  ),
            email:
              document.getElementById("correoEditar").value === ""
                ? null
                : document.getElementById("correoEditar").value,
            telefono:
              document.getElementById("telefonoEditar").value === ""
                ? null
                : document.getElementById("telefonoEditar").value,
            password: contraseniaModificada ? contrasenia : null,
            idRol: 1,
          };

          const formData = new FormData();
          formData.append("usuario", JSON.stringify(usuario));

          const fotoFile = document.getElementById("formFileEditar")?.files?.[0];
          if (fotoFile) {
            formData.append("foto", fotoFile);
          }

          editarUsuario(formEditar.dataset.id, formData);
        }

        formEditar.classList.add("was-validated");
      },
      false,
    );
  }

  // Formulario de edición de contraseña
  let contraseniaModificada = false;
  const formEditarContrasenia = document.getElementById("formEditarContrasenia");

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

        bootstrap.Modal.getInstance(
          document.getElementById("modalEditarContrasenia"),
        ).hide();

        mostrarAlerta("info", "Contraseña actualizada pendiente de guardar");

        const modalEditarContrasenia = document.getElementById(
          "modalEditarContrasenia",
        );

        modalEditarContrasenia.addEventListener("hidden.bs.modal", function () {
          const modalEditarUsuario = new bootstrap.Modal(
            document.getElementById("modalEditarUsuario"),
          );

          modalEditarUsuario.show();
        });
      }
      formEditarContrasenia.classList.add("was-validated");
    },
    false,
  );

  const modalUsuario = document.getElementById("modalCrearUsuario");
  if (modalUsuario) {
    modalUsuario.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formAgregarUsuario");
      if (form) {
        form.classList.remove("was-validated");
        form.reset();
        document.getElementById("fotoUsuario").value = "";
      }
    });
  }

  const modalEditarUsuario = document.getElementById("modalEditarUsuario");
  if (modalEditarUsuario) {
    modalEditarUsuario.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formEditarUsuario");
      if (form) {
        form.classList.remove("was-validated");
        contraseniaModificada = false;
      }
    });
  }

  if (modalEditarUsuario) {
    modalEditarUsuario.addEventListener("hidden.bs.modal", function () {
      const inputImagen = document.getElementById("formFileEditar");
      if (inputImagen) inputImagen.value = "";
      formEditar.classList.remove("was-validated");
    });
  }

  document
    .getElementById("fotoUsuario")
    .addEventListener("change", function () {
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

  configurarMostrarContraseniasFormulario(
    ["contrasena", "confirmarContrasena"],
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
        idIcono: "iconoContraseniaEditar",
      },
      {
        idBoton: "toggleConfirmarContraseniaEditar",
        idIcono: "ConfirmarContraseniaEditar",
      },
    ],
  );
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para cargar los usuarios y mostrarlos en la tabla
async function cargarUsuarios() {
  const tabla =document.getElementById("listadoUsuarios") || document.getElementById("listadUsuarios");
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetch(URL_BASE + "usuarios/registered", {
      method: "GET",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
      },
    });

    const data = await resp.json();
    data.sort((a, b) => a.id - b.id);

    // Mostrar mensaje si no hay usuarios y limpiar tabla
    const usuariosVacio =
      document.getElementById("usuarios-vacio") ||
      document.getElementById("roles-vacio");

    if (!tabla) {
      console.error("No se encontró la tabla de usuarios (#listadoUsuarios)");
      return;
    }

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

    data.forEach((usuario) => {
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
      textoId.textContent = usuario.id;
      textoNombre.textContent = usuario.nombre;
      textoApellidos.textContent = usuario.apellidos;
      textofechaNac.textContent = formatearFecha(usuario.fechaNacimiento);
      textoCorreo.textContent = usuario.email;
      textoTelefono.textContent = usuario.telefono;
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
      btnVer.setAttribute("data-bs-target", "#modalVerUsuario");
      btnVer.addEventListener("click", async function () {
        const detalle = await obtenerOrganizadorPorId(usuario.id);
        if (detalle) {
          verOrganizador(detalle);
        }
      });

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", usuario.id);
      btnEditar.setAttribute("data-nombre", usuario.nombre);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarUsuario");
      btnEditar.addEventListener("click", async function () {
        const detalle = await obtenerOrganizadorPorId(usuario.id);
        const data = detalle || usuario;
        document.getElementById("formEditarUsuario").dataset.id = data.id;
        document.getElementById("nombreEditar").value = data.nombre;
        document.getElementById("apellidosEditar").value = data.apellidos;
        document.getElementById("fechaNacimientoEditar").value = data.fechaNacimiento;
        document.getElementById("correoEditar").value = data.email;
        document.getElementById("telefonoEditar").value = data.telefono;
        const imagenUsuario = document.getElementById("imagenUsuario");
        const sinFotoUsuario = document.getElementById("sinFotoUsuario");
        if (data.fotoUrl) {
          imagenUsuario.src = data.fotoUrl;
          imagenUsuario.style.display = "block";
          sinFotoUsuario.style.display = "none";
        } else {
          imagenUsuario.style.display = "none";
          sinFotoUsuario.style.display = "flex";
        }
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", usuario.id);
      btnEliminar.setAttribute("data-nombre", usuario.nombre);
      btnEliminar.setAttribute("data-apellidos", usuario.apellidos);
      btnEliminar.addEventListener("click", function () {
        eliminarUsuario(
          this.dataset.id,
          this.dataset.nombre,
          this.dataset.apellidos,
        );
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

// Función para crear un nuevo usuario
async function crearUsuario(datosFormulario) {
  try {
    const options = {
      method: "POST",
      credentials: "include",
      body: datosFormulario,
    };
    const resp = await fetch(URL_BASE + "usuarios/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Usuario creado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearUsuario"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al crear el usuario:", error);
  } finally {
    await cargarUsuarios();
  }
}

// Función para editar un usuario existente
async function editarUsuario(id, datosFormulario) {
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
        document.getElementById("modalEditarUsuario"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al editar el usuario: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al editar el usuario:", error);
  } finally {
    await cargarUsuarios();
  }
}

// Función para eliminar un usuario
async function eliminarUsuario(id, nombre, apellidos) {
  Swal.fire({
    title:
      `¿Estás seguro que deseas eliminar el usuario \"` +
      nombre +
      " " +
      apellidos +
      `\"?`,
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar usuario",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
        };
        const resp = await fetch(URL_BASE + "usuarios/delete/" + id, options);
        if (resp.status === 204) {
          mostrarAlerta("success", "Usuario eliminado correctamente");
        } else {
          const errorTexto = await resp.text();
          mostrarAlerta("error", "Error al eliminar el usuario: " + errorTexto);
        }
      } catch (error) {
        console.error("Error al eliminar el usuario:", error);
      } finally {
        await cargarUsuarios();
      }
    }
  });
}

// Función para obtener los detalles de un organizador por su ID
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
      throw new Error("No se pudo obtener el usuario");
    }

    return await resp.json();
  } catch (error) {
    console.error("Error al obtener el usuario:", error);
    mostrarAlerta("error", "No se pudo cargar el usuario");
    return null;
  }
}

function verOrganizador(usuario) {
  const tieneFoto =
    usuario.fotoUrl &&
    usuario.fotoUrl.trim() !== "" &&
    usuario.fotoUrl !== "null" &&
    usuario.fotoUrl !== "undefined";

  let contenido = `
    <div id="contenidoModalVerUsuario">
      <div class="text-center mb-4">
        <div class="avatar-wrapper mx-auto mb-2">
          ${
            tieneFoto
              ? `<img
                  src="${usuario.fotoUrl}"
                  alt="Foto de ${usuario.nombre}"
                  class="avatar-usuario-modal"
                />`
              : `<div class="avatar-placeholder">
                  <i class="fas fa-user"></i>
                </div>`
          }
        </div>

        <h4 class="text-light mb-0">
          ${usuario.nombre || "-"} ${usuario.apellidos || ""}
        </h4>

        <small class="text-muted">
          Información del usuario
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
                ${usuario.nombre || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Apellidos</p>
              <p class="mb-0 text-light fw-semibold">
                ${usuario.apellidos || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Fecha de nacimiento</p>
              <p class="mb-0 text-light fw-semibold">
                ${formatearFecha(usuario.fechaNacimiento) || "-"}
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
                ${usuario.email || "-"}
              </p>
            </div>

            <div class="col-md-6">
              <p class="mb-1 text-muted">Teléfono</p>
              <p class="mb-0 text-light fw-semibold">
                ${usuario.telefono || "-"}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  document.getElementById("contenidoModalUsuario").innerHTML = contenido;
}