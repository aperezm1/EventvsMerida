// Set new default font family and font color to mimic Bootstrap's default styling
Chart.defaults.global.defaultFontFamily =
  '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

Chart.defaults.global.defaultFontColor = "#292b2c";

let grafico;

document.addEventListener("DOMContentLoaded", () => {
  crearGraficoVacioTarta();
  cargarGraficoTarta();
});

function crearGraficoVacioTarta() {
  const ctx = document.getElementById("graficoEventosCategoria");

  if (!ctx) {
    console.warn("No existe el canvas #graficoEventosCategoria");
    return;
  }

  grafico = new Chart(ctx, {
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

async function cargarGraficoTarta() {
  const URL = "https://eventvsmerida-x2t1.onrender.com/api/eventos/eventos-por-categoria";

  try {
    const respuesta = await fetch(URL, {
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

function actualizarGraficoTarta(eventosPorCategoria) {
  if (!grafico) {
    console.warn("El gráfico todavía no está creado");
    return;
  }

  grafico.data.labels = eventosPorCategoria.labels;
  grafico.data.datasets[0].data = eventosPorCategoria.datos;
  grafico.update();
}