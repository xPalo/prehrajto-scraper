import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"
import "chartjs-adapter-date-fns"

Chart.register(...registerables)

// Renders a line chart from JSON data passed via data-chart-data-value.
// Used by the watchdog price-history view.
export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Array,
    label: String,
    xLabel: String,
    yLabel: String,
    currency: { type: String, default: "€" }
  }

  connect() {
    const isNarrow = window.matchMedia("(max-width: 575px)").matches
    const accent = "#C7F36A"
    const border = "#27272A"
    const text = "#A1A1AA"
    const surface = "#1A1A1D"
    const currency = this.currencyValue

    const gradient = (ctx) => {
      const { chart } = ctx
      const { ctx: c, chartArea } = chart
      if (!chartArea) return null
      const g = c.createLinearGradient(0, chartArea.top, 0, chartArea.bottom)
      g.addColorStop(0, "rgba(199, 243, 106, 0.25)")
      g.addColorStop(1, "rgba(199, 243, 106, 0)")
      return g
    }

    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: {
        datasets: [{
          label: this.labelValue,
          data: this.dataValue,
          parsing: { xAxisKey: "x", yAxisKey: "y" },
          borderColor: accent,
          backgroundColor: gradient,
          borderWidth: 2,
          fill: true,
          tension: 0.3,
          pointRadius: isNarrow ? 2 : 3,
          pointHoverRadius: isNarrow ? 4 : 6,
          pointBackgroundColor: accent,
          pointBorderColor: "#0A0A0A",
          pointBorderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: surface,
            titleColor: "#FAFAFA",
            bodyColor: "#FAFAFA",
            borderColor: border,
            borderWidth: 1,
            padding: 10,
            displayColors: false,
            callbacks: { label: (ctx) => `${ctx.parsed.y.toFixed(2)} ${currency}` }
          }
        },
        scales: {
          x: {
            type: "time",
            time: { unit: "day" },
            title: {
              display: !isNarrow,
              text: this.xLabelValue,
              color: text,
              font: { size: 11, weight: "500" }
            },
            grid: { color: border, drawTicks: false },
            border: { display: false },
            ticks: {
              color: text,
              maxRotation: 0,
              autoSkip: true,
              autoSkipPadding: 12,
              maxTicksLimit: isNarrow ? 4 : 8,
              font: { size: isNarrow ? 10 : 11 }
            }
          },
          y: {
            title: {
              display: !isNarrow,
              text: this.yLabelValue,
              color: text,
              font: { size: 11, weight: "500" }
            },
            grid: { color: border, drawTicks: false },
            border: { display: false },
            ticks: {
              color: text,
              maxTicksLimit: isNarrow ? 5 : 8,
              font: { size: isNarrow ? 10 : 11 },
              callback: (v) => `${v} ${currency}`
            }
          }
        }
      }
    })
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }
}
