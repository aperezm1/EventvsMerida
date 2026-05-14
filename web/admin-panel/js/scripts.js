// ==========================================================================
// VARIABLES
// ==========================================================================

window.APP_CONFIG = {
  API_BASE: "https://eventvsmerida-x2t1.onrender.com/api/",
};

// ==========================================================================
// CONTENIDO DEL DOM
// ==========================================================================

window.addEventListener("DOMContentLoaded", async (event) => {
  const sidebarToggle = document.body.querySelector("#sidebarToggle");

  if (sidebarToggle) {
    sidebarToggle.addEventListener("click", (event) => {
      event.preventDefault();
      document.body.classList.toggle("sb-sidenav-toggled");
      localStorage.setItem(
        "sb|sidebar-toggle",
        document.body.classList.contains("sb-sidenav-toggled"),
      );
    });
  }

  if (!document.URL.includes("/html/login.html")) {
    document.getElementById("nombreUsuario").innerText = obtenerNombreUsuario();
  }

  if (sessionStorage.getItem("sesionCaducada") === "true") {
    mostrarAlerta(
      "error",
      "Sesión caducada. Inicia sesión nuevamente.",
    );
    sessionStorage.removeItem("sesionCaducada");
  }
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para mostrar alertas usando SweetAlert2
function mostrarAlerta(tipo, mensaje) {
  const Toast = Swal.mixin({
    toast: true,
    position: "top-end",
    iconColor: "white",
    customClass: {
      popup: "colored-toast",
    },
    showConfirmButton: false,
    timer: 2000,
    timerProgressBar: true,
  });

  Toast.fire({
    icon: tipo,
    title: mensaje,
  });
}

// Función para cerrar sesión
async function cerrarSesion() {
  const URL = `${window.APP_CONFIG.API_BASE}auth/logout`;

  try {
    const respuesta = await fetchConAuth(URL, {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
    });

    if (respuesta.ok) {
      sessionStorage.clear();
      localStorage.removeItem("nombreUsuario");
      window.location.href = `${window.location.origin}/html/login.html`;
    } else {
      console.warn("Logout falló, status:", respuesta.status);
    }
  } catch (error) {
    console.error("Error en scripts.js", error);
  }
}

// Función para obtener el nombre de usuario almacenado en localStorage
function obtenerNombreUsuario() {
  return localStorage.getItem("nombreUsuario");
}

// Función que valida si el usuario está logeado
async function logeado() {
  const URL = `${window.APP_CONFIG.API_BASE}auth/session`;

  try {
    const respuesta = await fetchConAuth(URL, {
      method: "GET",
      credentials: "include",
      cache: "no-store",
    });

    return respuesta.status;
  } catch (error) {
    console.error("Error en scripts.js", error);
    return 500;
  }
}

// Función para validar la edad ingresada en un formulario
function validarEdad(input, edadMinima, edadMaxima, fechaObligatoria) {
  const feedback = input.parentElement.querySelector(".invalid-feedback");
  const fechaNacimiento = input.value;

  if (!fechaNacimiento) {
    if (fechaObligatoria) {
      input.setCustomValidity("Campo obligatorio");

      if (feedback) {
        feedback.textContent = "La fecha de nacimiento es obligatoria.";
      }

      return false;
    }

    input.setCustomValidity("");

    if (feedback) {
      feedback.textContent = "Ingresa una fecha válida.";
    }

    return true;
  }

  const hoy = new Date();
  const year = hoy.getFullYear();
  const month = String(hoy.getMonth() + 1).padStart(2, "0");
  const day = String(hoy.getDate()).padStart(2, "0");
  const fechaHoy = `${year}-${month}-${day}`;

  if (fechaNacimiento > fechaHoy) {
    input.setCustomValidity("Fecha inválida");

    if (feedback) {
      feedback.textContent =
        "La fecha de nacimiento no puede ser una fecha futura.";
    }

    return false;
  }

  const fechaMinimaPermitida = calcularFechaPorEdad(edadMaxima);
  const fechaMaximaPermitida = calcularFechaPorEdad(edadMinima);

  if (fechaNacimiento < fechaMinimaPermitida) {
    input.setCustomValidity("Edad demasiado alta");

    if (feedback) {
      feedback.textContent = `La edad máxima permitida es de ${edadMaxima} años.`;
    }

    return false;
  }

  if (fechaNacimiento > fechaMaximaPermitida) {
    input.setCustomValidity("Edad insuficiente");

    if (feedback) {
      feedback.textContent = `Debe tener al menos ${edadMinima} años.`;
    }

    return false;
  }

  input.setCustomValidity("");

  if (feedback) {
    feedback.textContent = "Ingresa una fecha válida.";
  }

  return true;
}

// Función para calcular la fecha mínima o máxima permitida según la edad
function calcularFechaPorEdad(edad) {
  const hoy = new Date();

  const fecha = new Date(
    hoy.getFullYear() - edad,
    hoy.getMonth(),
    hoy.getDate(),
  );

  const year = fecha.getFullYear();
  const month = String(fecha.getMonth() + 1).padStart(2, "0");
  const day = String(fecha.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

// Función para formatear una fecha en formato ISO a "dd/mm/yyyy"
function formatearFecha(fechaISO) {
  if (!fechaISO) {
    return "";
  }

  const fecha = new Date(fechaISO);

  if (isNaN(fecha.getTime())) {
    return "";
  }

  const dia = fecha.getDate().toString().padStart(2, "0");
  const mes = (fecha.getMonth() + 1).toString().padStart(2, "0");
  const anio = fecha.getFullYear();

  return `${dia}/${mes}/${anio}`;
}

// Función para configurar el comportamiento de mostrar/ocultar contraseñas en formularios
function configurarMostrarContraseniasFormulario(idsInputs, controles) {
  const inputs = idsInputs
    .map((id) => document.getElementById(id))
    .filter((input) => input !== null);

  const botones = controles
    .map((control) => ({
      boton: document.getElementById(control.idBoton),
      idIcono: control.idIcono,
    }))
    .filter((control) => control.boton !== null);

  if (inputs.length === 0 || botones.length === 0) return;

  function actualizarIconos(mostrando) {
    botones.forEach(({ boton, idIcono }) => {
      boton.innerHTML = mostrando
        ? `<i class="fa-solid fa-eye-slash" id="${idIcono}"></i>`
        : `<i class="fa-solid fa-eye" id="${idIcono}"></i>`;

      boton.setAttribute(
        "aria-label",
        mostrando ? "Ocultar contraseña" : "Mostrar contraseña",
      );
    });
  }

  botones.forEach(({ boton }) => {
    boton.addEventListener("click", () => {
      const mostrar = inputs[0].type === "password";

      inputs.forEach((input) => {
        input.type = mostrar ? "text" : "password";
      });

      actualizarIconos(mostrar);
    });
  });
}

// Función para requerir autenticación antes de cargar el contenido de la página
async function requireAuth() {
  const sesion = await logeado();

  if (sesion === 401) {
    window.location.href = `${window.location.origin}/html/login.html`;
    return false;
  }

  if (sesion === 200) {
    document.body.classList.remove("auth-pending");
  }

  return true;
}

const fetchConAuth = async (url, options = {}) => {
  const resp = await fetch(url, options);

  if (resp.redirected && resp.url.includes("login")) {
    sessionStorage.setItem("sesionCaducada", "true");
    window.location.href = `${window.location.origin}/html/login.html`;
    return resp;
  }

  if (resp.status === 401) {
    sessionStorage.setItem("sesionCaducada", "true");
    window.location.href = `${window.location.origin}/html/login.html`;
    return resp;
  }

  return resp;
};

// Función para validar una imagen antes de subirla (formato y tamaño)
function validarImagen(imagen) {
  const formatosPermitidos = ["image/jpeg", "image/jpg", "image/png"];
  const maxSize = 1.5 * 1024 * 1024;
  if (!imagen) return true;

  if (!formatosPermitidos.includes(imagen.type)) {
    mostrarAlerta(
      "error",
      "Solo se permiten imágenes en formato JPG, JPEG o PNG",
    );
    return false;
  }
  if (imagen.size > maxSize) {
    mostrarAlerta("error", "La imagen no puede superar los 1.5MB");
    return false;
  }
  return true;
}

// Validación Bootstrap para formularios
(() => {
  "use strict";
  const forms = document.querySelectorAll(".needs-validation");
  Array.from(forms).forEach((form) => {
    form.addEventListener(
      "submit",
      (event) => {
        if (!form.checkValidity()) {
          event.preventDefault();
          event.stopPropagation();
        }
        form.classList.add("was-validated");
      },
      false,
    );
  });
})();
