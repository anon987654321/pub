// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Modern JavaScript enhancements
document.addEventListener('DOMContentLoaded', function() {
  // Auto-hide flash messages after 5 seconds
  const alerts = document.querySelectorAll('.alert')
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert.parentNode) {
        alert.remove()
      }
    }, 5000)
  })
  
  // Add loading states to forms
  const forms = document.querySelectorAll('form')
  forms.forEach(form => {
    form.addEventListener('submit', function() {
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
      if (submitButton) {
        submitButton.disabled = true
        submitButton.innerHTML = '<span class="spinner"></span> Loading...'
        form.classList.add('loading')
      }
    })
  })
})

// Turbo event handlers for enhanced UX
document.addEventListener('turbo:load', function() {
  console.log('Turbo loaded')
})

// Error handling for better UX
document.addEventListener('turbo:frame-missing', function(event) {
  console.warn('Turbo frame missing:', event.detail)
  event.preventDefault()
  window.location = event.detail.response.url
})
