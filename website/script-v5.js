// Initialize Lenis for Smooth Scrolling
const lenis = new Lenis({
    duration: 1.2,
    easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
    smooth: true,
});

function raf(time) {
    lenis.raf(time);
    requestAnimationFrame(raf);
}
requestAnimationFrame(raf);

// Initialize GSAP ScrollTrigger with Lenis
gsap.registerPlugin(ScrollTrigger);

// Custom Cursor Logic
const cursor = document.querySelector('.cursor');
const hoverTargets = document.querySelectorAll('.hover-target, a, button');

document.addEventListener('mousemove', (e) => {
    // using gsap for smoother cursor movement
    gsap.to(cursor, {
        x: e.clientX,
        y: e.clientY,
        duration: 0.1,
        ease: "power2.out"
    });
});

hoverTargets.forEach(target => {
    target.addEventListener('mouseenter', () => {
        cursor.classList.add('hovered');
    });
    target.addEventListener('mouseleave', () => {
        cursor.classList.remove('hovered');
    });
});

// Hide cursor when it leaves the window
document.addEventListener('mouseleave', () => {
    gsap.to(cursor, { opacity: 0, duration: 0.3 });
});
document.addEventListener('mouseenter', () => {
    gsap.to(cursor, { opacity: 1, duration: 0.3 });
});

// Animations

// 1. Hero Text Reveal
const heroSpans = document.querySelectorAll('.hero-title span');
gsap.fromTo(heroSpans, 
    { y: 100, opacity: 0 },
    { y: 0, opacity: 1, duration: 1, stagger: 0.1, ease: "power4.out", delay: 0.2 }
);

gsap.fromTo('.hero-subtitle',
    { y: 30, opacity: 0 },
    { y: 0, opacity: 1, duration: 1, ease: "power3.out", delay: 0.8 }
);

// 2. Continuous Marquee Animation
gsap.to(".marquee-content", {
    xPercent: -50,
    ease: "none",
    duration: 10,
    repeat: -1
});

// 3. Smooth Word Text Transition Scrub
const introWords = document.querySelectorAll('.intro-text .word');
if(introWords.length > 0) {
    gsap.to(introWords, {
        opacity: 1,
        stagger: 0.1,
        ease: "none",
        scrollTrigger: {
            trigger: ".intro-section",
            start: "top 70%",
            end: "center center",
            scrub: 0.5 // Creates the smooth text-reveal effect typical of premium sites
        }
    });
}

// 4. Section Title Reveal (Community & CTA)
const sectionTitles = document.querySelectorAll('.section-title span, .cta-title span');
sectionTitles.forEach(title => {
    gsap.fromTo(title,
        { y: 100, opacity: 0 },
        {
            y: 0, opacity: 1,
            duration: 1,
            ease: "power4.out",
            scrollTrigger: {
                trigger: title.parentElement,
                start: "top 80%",
            }
        }
    );
});

// 5. Fade Up Elements (Cards, Subtitles)
const fadeUpElements = document.querySelectorAll('.fade-up, .fade-in');
fadeUpElements.forEach(el => {
    gsap.fromTo(el,
        { y: 40, opacity: 0 },
        {
            y: 0, opacity: 1,
            duration: 1,
            ease: "power3.out",
            scrollTrigger: {
                trigger: el,
                start: "top 90%",
            }
        }
    );
});
