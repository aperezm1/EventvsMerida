// Obtener token de la URL
const params = new URLSearchParams(window.location.search);

const token = params.get("token");

const form = document.getElementById("resetForm");

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
    const response = await fetch("http://localhost:8080/api/auth/reset-password", {
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
