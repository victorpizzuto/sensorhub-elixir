

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

const Hooks = {
  TelemetryChart: {
    mounted() {
      if (typeof echarts === 'undefined') {
        console.error('ECharts não está carregado!')
        return
      }

      this.chart = echarts.init(this.el)

      this.loadInitialData()

      this.setupEventListeners()
    },

    loadInitialData() {
      const initialData = this.el.dataset.chartData
      if (initialData) {
        try {
          const data = JSON.parse(initialData)
          this.renderChart(data)
        } catch (e) {
          console.error('Erro ao parsear dados iniciais:', e)
          this.renderEmptyChart()
        }
      } else {
        this.renderEmptyChart()
      }
    },

    setupEventListeners() {
      const chartId = this.el.id

      if (chartId === 'velocity-chart') {
        this.handleEvent("velocity-chart-update", (data) => {
          this.updateChart(data)
        })
      } else if (chartId === 'temperature-chart') {
        this.handleEvent("temperature-chart-update", (data) => {
          this.updateChart(data)
        })
      }
    },

    renderEmptyChart() {
      const chartId = this.el.id
      const isVelocity = chartId === 'velocity-chart'

      const option = {
        title: {
          text: isVelocity ? 'Velocidade dos Sensores' : 'Temperatura dos Sensores',
          left: 'center',
          textStyle: { fontSize: 16 }
        },
        tooltip: {
          trigger: 'axis'
        },
        legend: {
          top: '10%'
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          top: '20%',
          containLabel: true
        },
        xAxis: {
          type: 'time',
          boundaryGap: false
        },
        yAxis: {
          type: 'value',
          name: isVelocity ? 'Velocidade (km/h)' : 'Temperatura (°C)'
        },
        series: []
      }

      this.chart.setOption(option)
    },

    renderChart(data) {
      if (!data || !data.series) {
        this.renderEmptyChart()
        return
      }

      const chartId = this.el.id
      const isVelocity = chartId === 'velocity-chart'
      const unit = isVelocity ? 'km/h' : '°C'

      const option = {
        title: {
          text: isVelocity ? 'Velocidade dos Sensores' : 'Temperatura dos Sensores',
          left: 'center',
          textStyle: { fontSize: 16 }
        },
        tooltip: {
          trigger: 'axis',
          formatter: function (params) {
            if (Array.isArray(params) && params.length > 0) {
              const time = new Date(params[0].value[0]).toLocaleTimeString('pt-BR')
              let result = `<strong>${time}</strong><br/>`
              params.forEach(param => {
                result += `${param.marker} ${param.seriesName}: <strong>${param.value[1]} ${unit}</strong><br/>`
              })
              return result
            }
          }
        },
        legend: {
          top: '10%',
          data: data.series.map(s => s.name)
        },
        grid: {
          left: '3%',
          right: '4%',
          bottom: '3%',
          top: '20%',
          containLabel: true
        },
        xAxis: {
          type: 'time',
          boundaryGap: false,
          axisLabel: {
            formatter: function (value) {
              return new Date(value).toLocaleTimeString('pt-BR', {
                hour: '2-digit',
                minute: '2-digit'
              })
            }
          }
        },
        yAxis: {
          type: 'value',
          name: isVelocity ? 'Velocidade (km/h)' : 'Temperatura (°C)'
        },
        series: data.series.map(serie => ({
          ...serie,
          type: 'line',
          smooth: true,
          symbol: 'circle',
          symbolSize: 4
        }))
      }

      this.chart.setOption(option, true)
    },

    updateChart(data) {
      if (!data || !data.series || !this.chart) {
        return
      }

      const updatedSeries = data.series.map(newSerie => ({
        ...newSerie,
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 4
      }))

      this.chart.setOption({
        series: updatedSeries,
        legend: {
          data: data.series.map(s => s.name)
        }
      }, false, true)
    },

    destroyed() {
      if (this.chart) {
        this.chart.dispose()
      }
    }
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()

window.liveSocket = liveSocket

if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    reloader.enableServerLogs()

    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

