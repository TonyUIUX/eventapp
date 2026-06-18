// ============================================================
// EVORRA — Landing Page Script
// Scroll animations, stat counters, parallax
// ============================================================

(function () {
  "use strict";

  // ── Respect reduced motion preference ──
  const reducedMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)"
  ).matches;

  // ══════════════════════════════════════════════
  // NAV — Scroll glass effect
  // ══════════════════════════════════════════════
  const nav = document.getElementById("nav");

  function updateNav() {
    if (window.scrollY > 60) {
      nav.classList.add("scrolled");
    } else {
      nav.classList.remove("scrolled");
    }
  }

  window.addEventListener("scroll", updateNav, { passive: true });
  updateNav();

  // ══════════════════════════════════════════════
  // HERO — Sequential line animation on load
  // ══════════════════════════════════════════════
  function initHeroAnimation() {
    if (reducedMotion) {
      document
        .querySelectorAll(
          ".hero-line, #hero .hero-body, #hero .hero-ctas, #hero .hero-phone-wrap"
        )
        .forEach((el) => el.classList.add("loaded"));
      return;
    }

    const heroLines = document.querySelectorAll("#hero .hero-line");
    const heroBody = document.querySelector("#hero .hero-body");
    const heroCtas = document.querySelector("#hero .hero-ctas");
    const heroPhone = document.querySelector("#hero .hero-phone-wrap");

    // Lines animate in sequence — CSS handles delay via transition-delay
    requestAnimationFrame(() => {
      heroLines.forEach((line) => line.classList.add("loaded"));
      setTimeout(() => heroBody && heroBody.classList.add("loaded"), 600);
      setTimeout(() => heroCtas && heroCtas.classList.add("loaded"), 750);
      setTimeout(() => heroPhone && heroPhone.classList.add("loaded"), 950);
    });
  }

  // Run on DOMContentLoaded
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initHeroAnimation);
  } else {
    initHeroAnimation();
  }

  // ══════════════════════════════════════════════
  // SCROLL REVEAL — IntersectionObserver
  // ══════════════════════════════════════════════
  function initReveal() {
    const revealEls = document.querySelectorAll(".reveal");

    if (!revealEls.length) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const el = entry.target;
            const delay = el.dataset.delay || 0;

            if (reducedMotion) {
              el.classList.add("visible");
            } else {
              setTimeout(() => el.classList.add("visible"), Number(delay));
            }

            observer.unobserve(el);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -40px 0px" }
    );

    revealEls.forEach((el) => observer.observe(el));
  }

  initReveal();

  // ══════════════════════════════════════════════
  // STAT COUNTERS — Count up from 0 on scroll
  // ══════════════════════════════════════════════
  function easeOutQuart(t) {
    return 1 - Math.pow(1 - t, 4);
  }

  function animateCounter(el) {
    if (el.dataset.counted) return;
    el.dataset.counted = "true";

    const target = parseFloat(el.dataset.target);
    const isDecimal = String(target).includes(".");
    const duration = 1200; // ms
    const startTime = performance.now();

    function tick(now) {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = easeOutQuart(progress);
      const current = eased * target;

      el.textContent = isDecimal
        ? current.toFixed(1)
        : Math.floor(current).toLocaleString();

      if (progress < 1) {
        requestAnimationFrame(tick);
      } else {
        el.textContent = isDecimal
          ? target.toFixed(1)
          : target.toLocaleString();
      }
    }

    requestAnimationFrame(tick);
  }

  function initStatCounters() {
    const counters = document.querySelectorAll(".stat-count");
    if (!counters.length) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            animateCounter(entry.target);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.5 }
    );

    counters.forEach((c) => observer.observe(c));
  }

  initStatCounters();

  // ══════════════════════════════════════════════
  // HOW-IT-WORKS — Step connector animation
  // ══════════════════════════════════════════════
  function initStepConnector() {
    const connector = document.querySelector(".step-connector");
    if (!connector) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            connector.classList.add("active");
            observer.unobserve(connector);
          }
        });
      },
      { threshold: 0.4 }
    );

    observer.observe(connector);
  }

  initStepConnector();

  // ══════════════════════════════════════════════
  // PARALLAX — Phone floats on mouse move (hero)
  // ══════════════════════════════════════════════
  function initParallax() {
    if (reducedMotion) return;

    const phoneContainer = document.querySelector("#hero .phone-container");
    if (!phoneContainer) return;

    const MAX_MOVE = 12;
    let rafId;

    function onMouseMove(e) {
      cancelAnimationFrame(rafId);
      rafId = requestAnimationFrame(() => {
        const cx = window.innerWidth / 2;
        const cy = window.innerHeight / 2;
        const dx = ((e.clientX - cx) / cx) * MAX_MOVE;
        const dy = ((e.clientY - cy) / cy) * MAX_MOVE;
        phoneContainer.style.transform = `translate(${dx}px, ${dy}px)`;
      });
    }

    function onMouseLeave() {
      cancelAnimationFrame(rafId);
      phoneContainer.style.transition = "transform 0.6s cubic-bezier(0.16,1,0.3,1)";
      phoneContainer.style.transform = "translate(0,0)";
      setTimeout(() => (phoneContainer.style.transition = ""), 600);
    }

    document.addEventListener("mousemove", onMouseMove, { passive: true });
    document.addEventListener("mouseleave", onMouseLeave);
  }

  initParallax();

  // ══════════════════════════════════════════════
  // SMOOTH SCROLL — Anchor links
  // ══════════════════════════════════════════════
  document.querySelectorAll('a[href^="#"]').forEach((link) => {
    link.addEventListener("click", (e) => {
      const target = document.querySelector(link.getAttribute("href"));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  });

  // ══════════════════════════════════════════════
  // STAGGERED CHILDREN reveal
  // ══════════════════════════════════════════════
  function initStaggerGroups() {
    const groups = document.querySelectorAll("[data-stagger]");

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const children = entry.target.querySelectorAll(".reveal");
            children.forEach((child, i) => {
              const delay = i * 80;
              setTimeout(() => child.classList.add("visible"), delay);
            });
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 }
    );

    groups.forEach((g) => observer.observe(g));
  }

  initStaggerGroups();
})();
