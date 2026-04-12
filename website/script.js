document.addEventListener("DOMContentLoaded", () => {
  // Select all elements to be observed and animated
  const elementsToObseve = document.querySelectorAll('.observe-me');

  // Set up the Intersection Observer
  const observerOptions = {
    root: null, // use the viewport
    rootMargin: '0px',
    threshold: 0.15 // trigger when 15% of the element is visible
  };

  const observer = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      // If the element is visible
      if (entry.isIntersecting) {
        // Add the 'visible' class to trigger CSS transition
        entry.target.classList.add('visible');
        
        // Unobserve the element if we only want it to animate once
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  // Start observing
  elementsToObseve.forEach(element => {
    observer.observe(element);
  });

  // Handle Waitlist Form Submission (Demo)
  const waitlistForm = document.querySelector('.waitlist-form');
  if(waitlistForm) {
    waitlistForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const input = waitlistForm.querySelector('input');
      const btn = waitlistForm.querySelector('button');
      
      const originalText = btn.textContent;
      btn.textContent = "Welcome to Throttle!";
      btn.style.backgroundColor = "var(--accent-1)";
      btn.style.color = "white";
      input.value = "";
      
      setTimeout(() => {
        btn.textContent = originalText;
        btn.style.backgroundColor = "";
        btn.style.color = "";
      }, 3000);
    });
  }
});
