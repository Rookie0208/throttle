// Smooth scroll Lenis
const lenis = new Lenis({
  duration: 1.2,
  easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t))
});
function raf(time) {
  lenis.raf(time);
  requestAnimationFrame(raf);
}
requestAnimationFrame(raf);

gsap.registerPlugin(ScrollTrigger);

// 1. Hero Text Reveal Animation
const heroTl = gsap.timeline();
heroTl.to(".hero-title span", {
  y: 0,
  opacity: 1,
  duration: 1.2,
  stagger: 0.05,
  ease: "power4.out",
  delay: 0.2
})
.to(".hero-sub", {
  opacity: 1,
  y: -20,
  duration: 0.8,
  ease: "power3.out"
}, "-=0.6");

// 2. Specific Shrink Animation logic
// Pinned wrapper scrubs image to half width while sliding text in from right.

const shrinkTl = gsap.timeline({
    scrollTrigger: {
        trigger: ".shrink-section",
        start: "top top",
        end: "+=1500", // Scroll distance
        pin: true,
        scrub: 1
    }
});

// Image shrinks down to a contained block on left
shrinkTl.to(".image-wrapper", {
    width: "45vw",  
    height: "80vh",
    y: "10vh",    // perfectly aligned vertically
    x: "5vw",     // offset from left edge
    borderRadius: "40px", 
    ease: "power1.inOut"
}, 0);

// Subtle scale on image inside the wrapper
shrinkTl.to(".image-wrapper img", {
    scale: 1.1,
    ease: "power1.inOut"
}, 0);

// Text slides in and fades up. 
// Height and top are set in CSS so it perfectly rests side-by-side!
shrinkTl.fromTo(".text-wrapper", 
    { opacity: 0, x: 50 }, 
    { opacity: 1, x: 0, ease: "power1.inOut" }, 
    0.2 
);


// 3. Horizontal Scrolling Cards logic (What We Offer)
// Inspired by the "Made with GSAP" cool js library section

let horizontalScrollTl = gsap.timeline({
    scrollTrigger: {
        trigger: ".features-section",
        start: "top top",
        end: () => "+=" + document.querySelector('.horizontal-container').scrollWidth, // End based on width
        scrub: 1,
        pin: true, // pin the .features-section
        anticipatePin: 1
    }
});

// Calculate how far to translate X to view all cards
const cardsWrapper = document.querySelector('.cards-wrapper');
horizontalScrollTl.to(cardsWrapper, {
    x: () => -(cardsWrapper.scrollWidth - window.innerWidth + 120), // 120 for padding buffers
    ease: "none"
});


// 4. About Section Reveal
gsap.utils.toArray(".founder-card").forEach((card, i) => {
    gsap.to(card, {
        scrollTrigger: {
            trigger: ".about-section",
            start: "top 70%", // Triggers when about-section approaches
        },
        y: 0,
        opacity: 1,
        duration: 0.8,
        ease: "back.out(1.7)",
        delay: i * 0.15 
    });
});

// 5. Countdown Timer logic
const launchDate = new Date("April 19, 2026 00:00:00").getTime();
const updateCountdown = () => {
    const now = new Date().getTime();
    const distance = launchDate - now;

    if(distance < 0) return; 

    const days = Math.floor(distance / (1000 * 60 * 60 * 24));
    const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((distance % (1000 * 60)) / 1000);

    // Make sure elements exist
    const elDays = document.getElementById("cd-days");
    if(elDays){
        elDays.textContent = days.toString().padStart(2, '0');
        document.getElementById("cd-hours").textContent = hours.toString().padStart(2, '0');
        document.getElementById("cd-mins").textContent = minutes.toString().padStart(2, '0');
        document.getElementById("cd-secs").textContent = seconds.toString().padStart(2, '0');
    }
};

updateCountdown();
setInterval(updateCountdown, 1000);

// 6. Form handling
const form = document.querySelector('.waitlist-form');
if(form) {
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        const btn = form.querySelector('button');
        gsap.to(btn, {
            backgroundColor: "#2a9d8f",
            color: "#ffffff",
            duration: 0.3
        });
        btn.textContent = "Spot Secured!";
        btn.style.pointerEvents = "none";
    });
}
