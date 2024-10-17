import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Chart from "chart.js/auto";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")


let Hooks = {};

Hooks.Chart = {
  mounted() {
    let ctx = document.getElementById('growth-chart').getContext('2d');
    let chartData = this.el.dataset.chartData;

    new Chart(ctx, {
      type: 'line',
      data: JSON.parse(chartData),
      options: {
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    });
  }
};


let liveSocket = new LiveSocket("/live", Socket, { 
  hooks: Hooks, 
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken} 
});


topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"});
window.addEventListener("phx:page-loading-start", _info => topbar.show(300));
window.addEventListener("phx:page-loading-stop", _info => topbar.hide());

liveSocket.connect();

window.liveSocket = liveSocket;

