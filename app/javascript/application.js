import "controllers"

// Show a confirmation prompt before submitting any form that has either
// `data-confirm` on the form element OR on the button that triggered the
// submit (via button_to ... data: { confirm: ... }).
document.addEventListener("submit", (event) => {
  const message =
    event.target?.dataset?.confirm ||
    event.submitter?.dataset?.confirm
  if (message && !window.confirm(message)) {
    event.preventDefault()
  }
})
