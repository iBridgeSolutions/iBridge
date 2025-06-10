document.addEventListener('DOMContentLoaded', function() {
  const form = document.getElementById('contact-form');
  const message = document.getElementById('form-message');
  if (form) {
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      message.style.display = 'block';
      message.textContent = 'Thank you for your message! We will get back to you soon.';
      message.className = 'form-message success';
      form.reset();
    });
  }
});