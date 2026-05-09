Chart.defaults.global.defaultFontFamily =
  '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

Chart.defaults.global.defaultFontColor = "#292b2c";

let graficoBarras;

document.addEventListener("DOMContentLoaded", () => {
  crearGraficoBarrasVacio();
  cargarGraficoBarras();
});

function crearGraficoBarrasVacio() {
  const ctx = document.getElementById("graficoEventoMes");

  if (!ctx) {
    console.warn("No existe el canvas #graficoEventoMes");
    return;
  }

  graficoBarras = new Chart(ctx, {
    type: "bar",
    data: {
      labels: [
        "Enero", "Febrero", "Marzo", "Abril",
        "Mayo", "Junio", "Julio", "Agosto",
        "Septiembre", "Octubre", "Noviembre", "Diciembre"
      ],
      datasets: [{
        label: "Eventos",
        backgroundColor: "#0074e8",
        borderColor: "#fff",
        data: Array(12).fill(0)
      }]
    },
    options: {
      scales: {
        xAxes: [{
          gridLines: {
            display: false
          },
          ticks: {
            maxTicksLimit: 12
          }
        }],
        yAxes: [{
          ticks: {
            min: 0,
            precision: 0,
            maxTicksLimit: 5
          },
          gridLines: {
            display: true
          }
        }]
      },
      legend: {
        display: false
      }
    }
  });
}

async function cargarGraficoBarras() {
  const URL = "https://eventvsmerida-x2t1.onrender.com/api/eventos/eventos-por-mes";

  try {
    const respuesta = await fetch(URL, {
      method: "GET",
      credentials: "include"
    });

    if (!respuesta.ok) {
      throw new Error(`Error HTTP: ${respuesta.status}`);
    }

    const eventos = await respuesta.json();

    console.log("Eventos por mes:", eventos);

    const eventosPorMes = convertirEventosAMeses(eventos);

    actualizarGraficoBarras(eventosPorMes);

  } catch (error) {
    console.error("Error al cargar eventos por mes:", error);
  }
}

function convertirEventosAMeses(eventos) {
  const contadorMeses = Array(12).fill(0);

  eventos.forEach(evento => {
    const indiceMes = Number(evento.numMes) - 1;
    const cantidad = Number(evento.cantidadEventos);

    if (indiceMes >= 0 && indiceMes <= 11) {
      contadorMeses[indiceMes] = cantidad;
    }
  });

  return contadorMeses;
}

function actualizarGraficoBarras(eventosPorMes) {
  if (!graficoBarras) {
    console.warn("El gráfico de barras todavía no está creado");
    return;
  }

  graficoBarras.data.datasets[0].data = eventosPorMes;
  graficoBarras.update();
}