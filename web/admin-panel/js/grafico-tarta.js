// ==========================================================================
// VARIABLES
// ==========================================================================

Chart.defaults.global.defaultFontFamily ='-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
Chart.defaults.global.defaultFontColor = "#292b2c";

let graficoTarta;

// ==========================================================================
// CONTENIDO DEL DOM
// ==========================================================================

document.addEventListener("DOMContentLoaded", () => {
  crearGraficoVacioTarta();
  cargarGraficoTarta();
});

// ==========================================================================
// FUNCIONES
// ==========================================================================

// Función para crear un gráfico de tarta vacío
function crearGraficoVacioTarta() {
  const ctx = document.getElementById("graficoEventosCategoria");

  if (!ctx) {
    console.warn("No existe el canvas #graficoEventosCategoria");
    return;
  }

  graficoTarta = new Chart(ctx, {
    type: "pie",
    data: {
      labels: [],
      datasets: [
        {
          data: [],
          backgroundColor: [
            "#007bff",
            "#dc3545",
            "#ffc107",
            "#28a745",
            "#6f42c1",
            "#17a2b8",
            "#fd7e14",
            "#20c997"
          ],
        },
      ],
    },
    options: {
      legend: {
        position: "bottom"
      }
    }
  });
}

// Función para cargar los datos del gráfico de tarta desde la API
async function cargarGraficoTarta() {
  const URL = `${URL_BASE}eventos/eventos-por-categoria`;

  try {
    const respuesta = await fetchConAuth(URL, {
      method: "GET",
      credentials: "include",
    });

    if (!respuesta.ok) {
      throw new Error(`Error HTTP: ${respuesta.status}`);
    }

    const eventos = await respuesta.json();

    const eventosPorCategoria = agruparEventosPorCategoria(eventos);

    actualizarGraficoTarta(eventosPorCategoria);

  } catch (error) {
    console.error("Error al cargar eventos:", error);
  }
}

// Función para agrupar los eventos por categoría y preparar los datos para el gráfico
function agruparEventosPorCategoria(categorias) {
  const labels = [];
  const datos = [];

  categorias.forEach((item) => {
    labels.push(item.categoria);
    datos.push(Number(item.total));
  });

  return {
    labels: labels,
    datos: datos,
  };
}

// Función para actualizar el gráfico de tarta con nuevos datos
function actualizarGraficoTarta(eventosPorCategoria) {
  if (!graficoTarta) {
    console.warn("El gráfico todavía no está creado");
    return;
  }

  graficoTarta.data.labels = eventosPorCategoria.labels;
  graficoTarta.data.datasets[0].data = eventosPorCategoria.datos;
  graficoTarta.update();
}