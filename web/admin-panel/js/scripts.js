window.addEventListener("DOMContentLoaded", async (event) => {
  // Toggle the side navigation
  const sidebarToggle = document.body.querySelector("#sidebarToggle");
  if (sidebarToggle) {
    // Uncomment Below to persist sidebar toggle between refreshes
    // if (localStorage.getItem('sb|sidebar-toggle') === 'true') {
    //     document.body.classList.toggle('sb-sidenav-toggled');
    // }
    sidebarToggle.addEventListener("click", (event) => {
      event.preventDefault();
      document.body.classList.toggle("sb-sidenav-toggled");
      localStorage.setItem(
        "sb|sidebar-toggle",
        document.body.classList.contains("sb-sidenav-toggled"),
      );
    });
  }

  document.getElementById("nombreUsuario").innerText = obtenerNombreUsuario();
});

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

async function cerrarSesion() {
  const URL = "https://eventvsmerida-x2t1.onrender.com/api/auth/logout";

  try {
    const respuesta = await fetch(URL, {
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
      console.warn('Logout falló, status:', respuesta.status);
    }
  } catch (error) {
    console.error("Error en scripts.js", error);
  }
}

function obtenerNombreUsuario() {
  return localStorage.getItem("nombreUsuario");
}

async function logeado() {
  const URL = "https://eventvsmerida-x2t1.onrender.com/api/auth/session";

  try {
    const respuesta = await fetch(URL, {
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