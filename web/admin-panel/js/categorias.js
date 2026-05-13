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

  await cargarCategorias();

  // Formulario agregar categoría
  const form = document.getElementById("formAgregarCategoria");

  form.addEventListener(
    "submit",
    function (event) {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        form.classList.add("was-validated");
      } else {
        event.preventDefault();
        const categoria = {
          nombre: document.getElementById("nombreCategoria").value,
        };
        crearCategoria(categoria);
      }
      form.classList.add("was-validated");
    },
    false,
  );

  // Formulario editar categoría
  const formEditar = document.getElementById("formEditarCategoria");

  formEditar.addEventListener(
    "submit",
    function (event) {
      if (!formEditar.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        formEditar.classList.add("was-validated");
      } else {
        event.preventDefault();
        const categoria = {
          nombre: document.getElementById("nombreCategoriaEditar").value,
        };
        editarCategoria(formEditar.dataset.id, categoria);
      }
      formEditar.classList.add("was-validated");
    },
    false,
  );

  // Modal agregar categoría: limpiar validación y formulario al cerrar
  const modalCategoria = document.getElementById("modalCrearCategoria");

  if (modalCategoria) {
    modalCategoria.addEventListener("hidden.bs.modal", function () {
      const form = document.getElementById("formAgregarCategoria");

      if (form) {
        form.classList.remove("was-validated");
        form.reset();
      }
    });
  }
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para cargar las categorías y mostrarlas en la tabla
async function cargarCategorias() {
  const tabla = document.getElementById("listadoCategorias");
  const loader = document.getElementById("loader");
  const body = document.querySelector("body");

  try {
    loader.style.display = "flex";
    body.classList.add("loading");

    const resp = await fetchConAuth(URL_BASE + "categorias/all", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
    });

    const data = await resp.json();

    // Mostrar mensaje si no hay categorías y limpiar tabla
    const categoriasVacia = document.getElementById("categorias-vacia");
    if (data.length === 0) {
      categoriasVacia.classList.remove("d-none");
      categoriasVacia.classList.add("d-block");
      tabla.innerHTML = "";
      return;
    } else {
      categoriasVacia.classList.remove("d-block");
      categoriasVacia.classList.add("d-none");
    }

    tabla.innerHTML = "";
    data.sort((a, b) => a.id - b.id);

    data.forEach((categoria) => {
      const tr = document.createElement("tr");
      const tdId = document.createElement("td");
      const tdCategoria = document.createElement("td");
      const textoId = document.createElement("div");
      const textoCategoria = document.createElement("div");
      textoId.textContent = document.createElement("div");
      textoId.textContent = categoria.id;
      textoCategoria.textContent = categoria.nombre;
      tdId.appendChild(textoId);
      tdCategoria.appendChild(textoCategoria);
      tdCategoria.classList.add("text-light");
      tr.appendChild(tdId);
      tr.appendChild(tdCategoria);
      const tdAcciones = document.createElement("td");
      const divGrupo = document.createElement("div");
      divGrupo.className = "btn-group";
      divGrupo.setAttribute("role", "group");

      // Botón editar
      const btnEditar = document.createElement("button");
      btnEditar.className = "btn btn-sm btn-warning";
      btnEditar.innerHTML = '<i class="fa-solid fa-pen"></i>';
      btnEditar.setAttribute("data-id", categoria.id);
      btnEditar.setAttribute("data-nombre", categoria.nombre);
      btnEditar.setAttribute("data-bs-toggle", "modal");
      btnEditar.setAttribute("data-bs-target", "#modalEditarCategoria");
      btnEditar.addEventListener("click", function () {
        document.getElementById("formEditarCategoria").dataset.id =
          categoria.id;
        document.getElementById("nombreCategoriaEditar").value =
          categoria.nombre;
      });

      // Botón eliminar
      const btnEliminar = document.createElement("button");
      btnEliminar.className = "btn btn-sm btn-danger";
      btnEliminar.innerHTML = '<i class="fa-solid fa-trash"></i>';
      btnEliminar.setAttribute("data-id", categoria.id);
      btnEliminar.setAttribute("data-nombre", categoria.nombre);
      btnEliminar.addEventListener("click", function () {
        eliminarCategoria(this.dataset.id, this.dataset.nombre);
      });

      divGrupo.appendChild(btnEditar);
      divGrupo.appendChild(btnEliminar);

      tdAcciones.appendChild(divGrupo);
      tdAcciones.classList.add("text-end");
      tr.appendChild(tdAcciones);
      tabla.appendChild(tr);
    });
  } catch (error) {
    console.error("Error al cargar las categorías:", error);
  } finally {
    loader.style.display = "none";
    body.classList.remove("loading");
  }
}


async function crearCategoria(datosCategoria) {
  try {
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(datosCategoria),
    };
    const resp = await fetchConAuth(URL_BASE + "categorias/add", options);
    const respuesta = await resp.json();
    if (resp.status === 201) {
      mostrarAlerta("success", "Categoría creada correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalCrearCategoria"),
      );
      modal.hide();
    } else {
      mostrarAlerta("error", "Error al crear la categoría: " + respuesta.error);
    }
  } catch (error) {
    console.error("Error al subir la categoría:", error);
  } finally {
    cargarCategorias();
  }
}

async function editarCategoria(id, datosCategoria) {
  try {
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(datosCategoria),
    };
    const resp = await fetchConAuth(URL_BASE + "categorias/update/" + id, options);
    const respuesta = await resp.json();
    if (resp.status === 200) {
      mostrarAlerta("success", "Categoría editada correctamente");

      const modal = bootstrap.Modal.getInstance(
        document.getElementById("modalEditarCategoria"),
      );
      modal.hide();
    } else {
      mostrarAlerta(
        "error",
        "Error al editar la categoría: " + respuesta.error,
      );
    }
  } catch (error) {
    console.error("Error al editar la categoría:", error);
  } finally {
    cargarCategorias();
  }
}

async function eliminarCategoria(id, categoria) {
  Swal.fire({
    title:
      '¿Estás seguro que deseas eliminar la categoría "' + categoria + '"?',
    text: "Esta acción no puede revertirse",
    icon: "warning",
    showCancelButton: true,
    cancelButtonColor: "#3085d6",
    cancelButtonText: "Cancelar",
    confirmButtonColor: "#d33",
    confirmButtonText: "Eliminar categoría",
  }).then(async (result) => {
    if (result.isConfirmed) {
      try {
        const options = {
          method: "DELETE",
          credentials: "include",
        };
        const resp = await fetchConAuth(URL_BASE + "categorias/delete/" + id, options);
        const respuesta = await resp.text();
        if (resp.status === 204) {
          mostrarAlerta("success", "Categoría eliminada correctamente");
        } else {
          mostrarAlerta(
            "error",
            "Error al eliminar la categoría: " + respuesta,
          );
        }
      } catch (error) {
        console.error("Error al eliminar la categoría:", error);
      } finally {
        cargarCategorias();
      }
    }
  });
}