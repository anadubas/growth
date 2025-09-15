import Chart from "chart.js/auto";

let Hooks = {};

Hooks.GrowthChart = {
  mounted() {
    console.log("GrowthChart mounted");
    console.log(this.el.dataset.chart);
    const data = JSON.parse(this.el.dataset.chart);

    this.chart = new Chart(this.el.getContext("2d"), {
      type: "scatter",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Criança",
            data: data.child,
            borderColor: "red",
            backgroundColor: "red",
            pointRadius: 6,
            showLine: false // Scatter points sem linha
          },
          {label: "-3DP", data: data.sd3neg, borderColor: "gray", borderDash: [4, 4], showLine: true},
    {label: "-2DP", data: data.sd2neg, borderColor: "orange", borderDash: [5, 5], showLine: true},
    {label: "-1DP", data: data.sd1neg, borderColor: "yellow", borderDash: [6, 6], showLine: true},
    {label: "Mediana", data: data.m, borderColor: "blue", borderWidth: 2, showLine: true},
    {label: "+1DP", data: data.sd1, borderColor: "yellow", borderDash: [6, 6], showLine: true},
    {label: "+2DP", data: data.sd2, borderColor: "orange", borderDash: [5, 5], showLine: true},
    {label: "+3DP", data: data.sd3, borderColor: "gray", borderDash: [4, 4], showLine: true}
        ]
      },
      options: {
        responsive: true,
        scales: {
          x: { title: { display: true, text: "Idade (meses)" } },
          y: { title: { display: true, text: data.label } }
        }
      }
    });
  },

  updated() {
    const data = JSON.parse(this.el.dataset.chart);
    this.chart.data.labels = data.labels;
    this.chart.data.datasets[0].data = data.child;
    this.chart.data.datasets[1].data = data.p50;
    this.chart.data.datasets[2].data = data.p2;
    this.chart.data.datasets[3].data = data.p98;
    this.chart.update();
  }
};

export default Hooks;
