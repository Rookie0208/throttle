document.addEventListener("DOMContentLoaded", () => {
    // Initialize Lenis Smooth Scroll
    const lenis = new Lenis();
    function raf(time) {
        lenis.raf(time);
        requestAnimationFrame(raf);
    }
    requestAnimationFrame(raf);

    // 1. Hero Title Animation
    const heroTl = gsap.timeline({ delay: 0.5 });
    heroTl.to(".char", {
        y: "0%",
        duration: 1,
        stagger: 0.03,
        ease: "expo.out"
    }).from(".l-hero .right", {
        opacity: 0,
        y: 20,
        duration: 0.8
    }, "-=0.5");

    // 2. Scroll-triggered Word Reveal
    gsap.utils.toArray(".word span").forEach((word) => {
        gsap.to(word, {
            y: "0%",
            scrollTrigger: {
                trigger: word,
                start: "top 90%",
                toggleActions: "play none none reverse"
            },
            duration: 0.8,
            ease: "power2.out"
        });
    });

    // 3. Launch Countdown Logic
    const launchDate = new Date("April 19, 2026 00:00:00").getTime();
    const updateCountdown = () => {
        const now = new Date().getTime();
        const distance = launchDate - now;
        if (distance < 0) return;

        const d = Math.floor(distance / (1000 * 60 * 60 * 24));
        const h = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const m = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const s = Math.floor((distance % (1000 * 60)) / 1000);

        document.getElementById("cd-days").innerText = d.toString().padStart(2, '0');
        document.getElementById("cd-hours").innerText = h.toString().padStart(2, '0');
        document.getElementById("cd-mins").innerText = m.toString().padStart(2, '0');
        document.getElementById("cd-secs").innerText = s.toString().padStart(2, '0');
    };
    setInterval(updateCountdown, 1000);
    updateCountdown();
});