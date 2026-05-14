// ==========================================================================
// VARIABLES
// ==========================================================================

// Obtener token de la URL
const params = new URLSearchParams(window.location.search);
const token = params.get("token");
const form = document.getElementById("resetForm");
const url = "https://eventvsmerida-x2t1.onrender.com/api/auth/reset-password";

// Idioma
const idiomasPermitidos = ["es", "en", "pt", "fr"];
let idiomaActual = "es";
let traducciones = {};

const idiomasInfo = {
  es: {
    codigo: "ES",
    nombre: "Español",
    bandera: "assets/img/es.svg",
  },
  en: {
    codigo: "EN",
    nombre: "English",
    bandera: "assets/img/en.svg",
  },
  pt: {
    codigo: "PT",
    nombre: "Português",
    bandera: "assets/img/pt.svg",
  },
  fr: {
    codigo: "FR",
    nombre: "Français",
    bandera: "assets/img/fr.svg",
  },
};

// Toggle para mostrar/ocultar contraseña
const eyeOpen = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>';
const eyeClosed = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><line x1="2" y1="2" x2="22" y2="22"/></svg>';

// ==========================================================================
// INICIALIZACIÓN
// ==========================================================================

document.addEventListener("DOMContentLoaded", async () => {
  await inicializarIdioma();
  inicializarDropdownIdioma();
  inicializarTogglePassword();
});

// ==========================================================================
// IDIOMA
// ==========================================================================

async function inicializarIdioma() {
  const idiomaGuardado = localStorage.getItem("lang");
  const idiomaNavegador = navigator.language.split("-")[0];

  if (idiomaGuardado && idiomasPermitidos.includes(idiomaGuardado)) {
    idiomaActual = idiomaGuardado;
  } else if (idiomasPermitidos.includes(idiomaNavegador)) {
    idiomaActual = idiomaNavegador;
  } else {
    idiomaActual = "es";
  }

  await cargarIdioma(idiomaActual);
}

async function cargarIdioma(idioma) {
  try {
    const response = await fetch(`i18n/${idioma}.json`);

    if (!response.ok) {
      throw new Error(`No se pudo cargar el idioma ${idioma}`);
    }

    traducciones = await response.json();
    idiomaActual = idioma;

    localStorage.setItem("lang", idioma);

    document.documentElement.lang = idioma;
    document.title = traducir("pageTitle");

    aplicarTraducciones();
    actualizarDropdownIdioma();
    actualizarAriaLabelsPassword();
  } catch (error) {
    console.error("Error al cargar el idioma:", error);

    if (idioma !== "es") {
      await cargarIdioma("es");
    }
  }
}

function aplicarTraducciones() {
  document.querySelectorAll("[data-i18n]").forEach(elemento => {
    const clave = elemento.dataset.i18n;
    elemento.textContent = traducir(clave);
  });
}

function traducir(clave) {
  return traducciones[clave] || clave;
}

function inicializarDropdownIdioma() {
  document.querySelectorAll(".language-current").forEach(button => {
    button.addEventListener("click", event => {
      event.stopPropagation();

      const dropdown = button.closest(".language-dropdown");
      const menu = dropdown.querySelector(".language-menu");
      const estaAbierto = menu.classList.contains("open");

      cerrarDropdownsIdioma();

      if (!estaAbierto) {
        menu.classList.add("open");
        button.setAttribute("aria-expanded", "true");
      }
    });
  });

  document.querySelectorAll(".language-option").forEach(option => {
    option.addEventListener("click", async event => {
      event.stopPropagation();

      const idioma = option.dataset.lang;

      cerrarDropdownsIdioma();

      if (!idiomasPermitidos.includes(idioma) || idioma === idiomaActual) {
        return;
      }

      await cargarIdioma(idioma);
    });
  });

  document.addEventListener("click", cerrarDropdownsIdioma);

  document.addEventListener("keydown", event => {
    if (event.key === "Escape") {
      cerrarDropdownsIdioma();
    }
  });
}

function cerrarDropdownsIdioma() {
  document.querySelectorAll(".language-menu").forEach(menu => {
    menu.classList.remove("open");
  });

  document.querySelectorAll(".language-current").forEach(button => {
    button.setAttribute("aria-expanded", "false");
  });
}

function actualizarDropdownIdioma() {
  const infoIdioma = idiomasInfo[idiomaActual];

  document.querySelectorAll(".language-current").forEach(button => {
    const flag = button.querySelector("img");
    const text = button.querySelector("span:not(.language-chevron)");

    if (flag) {
      flag.src = infoIdioma.bandera;
      flag.alt = infoIdioma.nombre;
    }

    if (text) {
      text.textContent = infoIdioma.codigo;
    }
  });

  document.querySelectorAll(".language-option").forEach(option => {
    const activo = option.dataset.lang === idiomaActual;
    option.classList.toggle("active", activo);
  });
}

function actualizarAriaLabelsPassword() {
  document.querySelectorAll(".pwd-toggle").forEach(btn => {
    const target = document.getElementById(btn.dataset.target);
    const estaMostrando = target && target.type === "text";

    btn.setAttribute(
      "aria-label",
      estaMostrando ? traducir("hidePassword") : traducir("showPassword")
    );
  });
}

// ==========================================================================
// EVENTOS
// ==========================================================================

// Listener para el envío del formulario
form.addEventListener("submit", async function (e) {
  e.preventDefault();

  const contrasenia = document.getElementById("contraseniaNueva").value;
  const confirmarContrasenia = document.getElementById("confirmarContraseniaNueva").value;

  form.classList.add("was-validated");

  if (!form.checkValidity()) {
    return;
  }

  if (contrasenia !== confirmarContrasenia) {
    mostrarAlerta("error", traducir("passwordsMustMatch"));
    return;
  }

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        token: token,
        nuevaPassword: contrasenia,
      }),
    });

    const mensaje = await response.text();

    if (
      mensaje === "USED_TOKEN" ||
      mensaje === "EXPIRED_TOKEN" ||
      mensaje === "INVALID_TOKEN"
    ) {
      mostrarAlerta("error", traducir("invalidOrExpiredLink"));
      return;
    }

    mostrarAlerta(
      response.ok ? "success" : "error",
      response.ok ? traducir("resetSuccess") : mensaje
    );

    if (response.ok) {
      document.getElementById("card-reset").style.display = "none";
      document.getElementById("success-container").style.display = "block";
    }

  } catch (error) {
    mostrarAlerta("error", traducir("resetError"));
  }
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

function inicializarTogglePassword() {
  document.querySelectorAll(".pwd-toggle").forEach(btn => {
    btn.innerHTML = eyeClosed;

    btn.addEventListener("click", () => {
      const target = document.getElementById(btn.dataset.target);

      if (!target) {
        return;
      }

      const willShow = target.type === "password";

      target.type = willShow ? "text" : "password";
      btn.innerHTML = willShow ? eyeOpen : eyeClosed;
      btn.classList.toggle("showing", willShow);

      btn.setAttribute(
        "aria-label",
        willShow ? traducir("hidePassword") : traducir("showPassword")
      );
    });
  });
}

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