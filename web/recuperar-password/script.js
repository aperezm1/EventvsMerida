// ==========================================================================
// VARIABLES
// ==========================================================================

// Obtener token de la URL
const params = new URLSearchParams(window.location.search);
const token = params.get("token");
const form = document.getElementById("resetForm");
const url = "https://eventvsmerida-x2t1.onrender.com/api/auth/reset-password";

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
    mostrarAlerta("error", "Las contraseñas tienen que ser iguales");
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
      mostrarAlerta("error", "El enlace de restablecimiento es inválido o ha expirado");
      return;
    }

    mostrarAlerta(response.ok ? "success" : "error", mensaje);

    document.getElementById("card-reset").style.display = "none";
    document.getElementById("success-container").style.display = "block";

  } catch (error) {
    mostrarAlerta("error", "Ocurrió un error al restablecer la contraseña");
  }
});

// Toggle para mostrar/ocultar contraseña
const eyeOpen = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>';
const eyeClosed = '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><line x1="2" y1="2" x2="22" y2="22"/></svg>';

document.querySelectorAll('.pwd-toggle').forEach(btn => {
  btn.innerHTML = eyeClosed;
  btn.addEventListener('click', () => {
    const target = document.getElementById(btn.dataset.target);
    if (!target) return;
    const willShow = target.type === 'password';
    target.type = willShow ? 'text' : 'password';
    btn.innerHTML = willShow ? eyeOpen : eyeClosed;
    btn.classList.toggle('showing', willShow);
    btn.setAttribute('aria-label', willShow ? 'Ocultar contraseña' : 'Mostrar contraseña');
  });
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

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