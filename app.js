/* ============================================
   Duet Company — App JavaScript
   ============================================ */

(function () {
  'use strict';

  // --- Mobile Nav Toggle ---
  const navToggle = document.querySelector('.nav-toggle');
  const navLinks = document.querySelector('.nav-links');

  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navToggle.classList.toggle('active');
      navLinks.classList.toggle('open');
      document.body.style.overflow = navLinks.classList.contains('open') ? 'hidden' : '';
    });

    // Close on link click
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navToggle.classList.remove('active');
        navLinks.classList.remove('open');
        document.body.style.overflow = '';
      });
    });
  }

  // --- Scroll Reveal (Intersection Observer) ---
  const revealElements = document.querySelectorAll('[data-reveal]');

  if (revealElements.length > 0) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('revealed');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
    );

    revealElements.forEach(el => observer.observe(el));
  }

  // --- Active Nav Link on Scroll ---
  const sections = document.querySelectorAll('section[id]');
  const navAnchors = document.querySelectorAll('.nav-links a[href^="#"]');

  if (sections.length > 0 && navAnchors.length > 0) {
    const sectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            const id = entry.target.getAttribute('id');
            navAnchors.forEach(a => {
              a.classList.toggle('active', a.getAttribute('href') === `#${id}`);
            });
          }
        });
      },
      { threshold: 0.3, rootMargin: '-80px 0px -40% 0px' }
    );

    sections.forEach(section => sectionObserver.observe(section));
  }

  // --- Smooth Scroll for Anchor Links ---
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        const offset = 80; // header height
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  // --- Terminal Typing Effect (restart on visibility) ---
  function initTerminalAnimation() {
    const terminalLines = document.querySelectorAll('.terminal-line');
    if (terminalLines.length === 0) return;

    // Reset and replay
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            terminalLines.forEach((line, i) => {
              line.style.animation = 'none';
              line.offsetHeight; // force reflow
              line.style.animation = `terminalFadeIn 0.4s ease forwards ${0.3 + i * 0.5}s`;
            });
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.5 }
    );

    const terminal = document.querySelector('.terminal');
    if (terminal) observer.observe(terminal);
  }

  initTerminalAnimation();

  // --- Header Background on Scroll ---
  const header = document.querySelector('.site-header');
  if (header) {
    let ticking = false;
    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          header.style.borderBottomColor =
            window.scrollY > 50 ? 'var(--border)' : 'var(--border-subtle)';
          ticking = false;
        });
        ticking = true;
      }
    });
  }

  // --- Keyboard: Escape closes mobile nav ---
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && navLinks && navLinks.classList.contains('open')) {
      navToggle.classList.remove('active');
      navLinks.classList.remove('open');
      document.body.style.overflow = '';
    }
  });

})();
