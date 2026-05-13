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

  await cargarRoles();

  // Formulario de creación de rol
  const form = document.getElementById("formAgregarRol");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const rol = {
          nombre: document.getElementById("nombreRol").value,
        };
        crearRol(rol);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  // Formulario de edición de rol
  const formEditar = document.getElementById("formEditarRol");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const rol = {
          nombre: document.getElementById("nombreRolEditar").value,
        };
        editarRol(formEditar.dataset.id, rol);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para cargar los roles y mostrarlos en la tabla
async function cargarRoles() {
  const tabla = document.getElementById("listadoRoles");
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetchConAuth(URL_BASE + "roles/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay categorías y limpiar tabla
    const rolesVacio = document.getElementById("roles-vacio");
    if (data.length === 0) {
      rolesVacio.classList.remove("d-none");
      rolesVacio.classList.add("d-block");
      tabla.innerHTML = "";
      return;
    } else {
      rolesVacio.classList.remove("d-block");
      rolesVacio.classList.add("d-none");
    }

    tabla.innerHTML = "";
    data.sort((a, b) => a.id - b.id);
    data.forEach((rol) => {
      const tr = document.createElement("tr");
      const tdId = document.createElement("td");
      const textoId = document.createElement("div");
      const tdRoles = document.createElement("td");
      const textoRoles = document.createElement("div");
      textoId.textContent = rol.id;
      textoRoles.textContent = rol.nombre;
      tdId.appendChild(textoId);
      tdRoles.appendChild(textoRoles);
      tdRoles.classList.add("text-light");
      tr.appendChild(tdId);
      tr.appendChild(tdRoles);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", rol.id);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarRol");
      btnEditar.addEventListener("click", function () {
        document.getElementById("formEditarRol").dataset.id =
          rol.id;
        document.getElementById("nombreRolEditar").value =
          rol.nombre;
        document.getElementById("nombreRolEditar").value = rol.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", rol.id);
      btnEliminar.setAttribute("data-nombre", rol.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarRol(this.dataset.id, this.dataset.nombre);
      });

      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar los roles:", error);
  } finally {
    loader.style.display = "none";
    body.classList.remove("loading");
  }
}

// Función para crear un nuevo rol
async function crearRol(datosRol) {
  try {
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(datosRol),
    };
    const resp = await fetchConAuth(URL_BASE + "roles/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Rol creado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearRol"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear el rol: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir el rol:", error);
  } finally {
    await cargarRoles();
  }
}

// Función para editar un rol existente
async function editarRol(id, datosRol) {
  try {
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(datosRol),
    };
    const resp = await fetchConAuth(URL_BASE + "roles/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Rol actualizado correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarRol"),
      );
      modal.hide();
    } else {
      mostrarAlerta(
        "error",
        "Error al editar el rol: " + respuesta.error,
      );
    }
  } catch (error) {
    console.error("Error al editar el rol:", error);
  } finally {
    await cargarRoles();
  }
}

// Función para eliminar un rol
async function eliminarRol(id, rol) {
  Swal.fire({
    title: "¿Estás seguro que deseas eliminar el rol \"" + rol +"\"?",
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar rol",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
          credentials: "include"
        };
        const resp = await fetchConAuth(URL_BASE + "roles/delete/" + id, options);
        const respuesta = await resp.text();
        if (resp.status === 204) {
          mostrarAlerta("success", "Rol eliminado correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar el rol: " + respuesta,
          );
        }
      } catch (error) {
        console.error("Error al eliminar el rol:", error);
      } finally {
        await cargarRoles();
      }
    }
  });
}