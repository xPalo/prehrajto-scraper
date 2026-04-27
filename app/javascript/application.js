// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "controllers"

document.addEventListener("submit", (event) => {
  const message = event.target?.dataset?.confirm
  if (message && !window.confirm(message)) {
    event.preventDefault()
  }
})
