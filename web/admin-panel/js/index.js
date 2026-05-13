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

  const nombreUsuario = obtenerNombreUsuario();
  if(document.referrer.includes("/html/login.html")) {
    mostrarAlerta("info", `Bievenid@ de nuevo ${nombreUsuario}`)
  }

  cargarDashboard(URL_BASE);
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para cargar los datos del dashboard y animar los contadores
async function cargarDashboard(URL_BASE) {
  try {
    const [
      usuarios,
      eventos,
      organizadores,
      categorias,
      roles
    ] = await Promise.all([
      fetch(URL_BASE + "usuarios/count/registered", { credentials: "include" }).then(r => r.text()),
      fetch(URL_BASE + "eventos/count").then(r => r.text()),
      fetch(URL_BASE + "usuarios/count/organizers", { credentials: "include" }).then(r => r.text()),
      fetch(URL_BASE + "categorias/count").then(r => r.text()),
      fetch(URL_BASE + "roles/count", { credentials: "include" }).then(r => r.text()),
    ]);

    animarContador(document.getElementById("numUsuarios"), Number(usuarios));
    animarContador(document.getElementById("numEventos"), Number(eventos));
    animarContador(document.getElementById("numOrganizadores"), Number(organizadores));
    animarContador(document.getElementById("numCategorias"), Number(categorias));
    animarContador(document.getElementById("numRoles"), Number(roles));

  } catch (error) {
    console.error("Error al cargar el dashboard:", error);
  }
}

// Función que anima un contador desde 0 hasta un valor final en un tiempo determinado
function animarContador(elemento, valorFinal, duracion = 1300) {
  let inicio = 0;
  const incrementoTiempo = 20;
  const incremento = Math.ceil(valorFinal / (duracion / incrementoTiempo));

  const intervalo = setInterval(() => {
    inicio += incremento;

    if (inicio >= valorFinal) {
      inicio = valorFinal;
      clearInterval(intervalo);
    }

    elemento.textContent = inicio;
  }, incrementoTiempo);
}