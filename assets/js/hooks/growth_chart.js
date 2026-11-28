import Chart from "chart.js/auto";

let Hooks = {};

Hooks.GrowthChart = {
  mounted() {
    const data = JSON.parse(this.el.dataset.chart);

    this.chart = new Chart(this.el.getContext("2d"), {
      type: "scatter",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Criança",
            data: data.child,
            borderColor: "indigo",
            backgroundColor: "indigo",
            pointRadius: 6,
            showLine: false
          },
          { label: "-3DP", data: data.sd3neg, borderColor: "red", borderDash: [4, 4], showLine: true, pointRadius: 0 },
          { label: "-2DP", data: data.sd2neg, borderColor: "orange", borderDash: [5, 5], showLine: true, pointRadius: 0 },
          { label: "-1DP", data: data.sd1neg, borderColor: "green", borderDash: [6, 6], showLine: true, pointRadius: 0 },
          { label: "Mediana", data: data.sd0, borderColor: "blue", borderWidth: 2, showLine: true, pointRadius: 0 },
          { label: "+1DP", data: data.sd1, borderColor: "green", borderDash: [6, 6], showLine: true, pointRadius: 0 },
          { label: "+2DP", data: data.sd2, borderColor: "orange", borderDash: [5, 5], showLine: true, pointRadius: 0 },
          { label: "+3DP", data: data.sd3, borderColor: "red", borderDash: [4, 4], showLine: true, pointRadius: 0 }
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
    const keys = ["child", "sd3neg", "sd2neg", "sd1neg", "sd0", "sd1", "sd2", "sd3"];

    this.chart.data.labels = data.labels;
    keys.forEach((key, index) => {
      this.chart.data.datasets[index].data = data[key];
    });
    this.chart.update();
  }
};

export default Hooks;
