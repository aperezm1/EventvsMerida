Chart.defaults.global.defaultFontFamily =
  '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';

Chart.defaults.global.defaultFontColor = '#292b2c';

let myBarChart;

document.addEventListener("DOMContentLoaded", () => {
  crearGraficoVacio();
  cargarEventosYGraficar();
});

function crearGraficoVacio() {
  const ctx = document.getElementById("graficoEventoMes");
  
  myBarChart = new Chart(ctx, {
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

function mostrarLoader() {
  const loader = document.getElementById("loader");
  if (loader) {
    loader.style.display = "flex";
  }
}

function ocultarLoader() {
  const loader = document.getElementById("loader");
  if (loader) {
    loader.style.display = "none";
  }
}

async function cargarEventosYGraficar() {
  const URL = "https://eventvsmerida-x2t1.onrender.com/api/eventos/all";

  mostrarLoader();
  try {
    const respuesta = await fetch(URL, {
      method: "GET",
      credentials: "include"
    });

    if (!respuesta.ok) {
      throw new Error(`Error HTTP: ${respuesta.status}`);
    }

    const eventos = await respuesta.json();

    const eventosPorMes = agruparEventosPorMes(eventos);

    actualizarGrafico(eventosPorMes);

  } catch (error) {
    console.error("Error al cargar eventos:", error);
  } finally {
    ocultarLoader();
  }
}

function agruparEventosPorMes(eventos) {
  const contadorMeses = Array(12).fill(0);

  eventos.forEach(evento => {
    const fecha = evento.fechaInicio;


    if (!fecha) {
      console.warn("El evento no tiene fecha:", evento);
      return;
    }

    const mes = Number(fecha.substring(5, 7)) - 1;
    if (isNaN(mes) || mes < 0 || mes > 11) {
      console.warn("Fecha no válida:", fecha);
      return;
    }

    contadorMeses[mes]++;
  });

  return contadorMeses;
}

function actualizarGrafico(eventosPorMes) {
  myBarChart.data.datasets[0].data = eventosPorMes;
  myBarChart.update();
}