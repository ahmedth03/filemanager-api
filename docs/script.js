/* ═══════════════════════════════════════════════
   HARFIDAR — Landing Page Script
   ═══════════════════════════════════════════════ */

/* ── Navbar scroll effect ── */
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 40);
}, { passive: true });

/* ── Hamburger menu ── */
const hamburger = document.getElementById('hamburger');
const navLinks  = document.getElementById('navLinks');
hamburger.addEventListener('click', () => {
  navLinks.classList.toggle('open');
});
document.addEventListener('click', e => {
  if (!navbar.contains(e.target)) navLinks.classList.remove('open');
});

/* ── Intersection Observer for animations ── */
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry, i) => {
    if (entry.isIntersecting) {
      setTimeout(() => entry.target.classList.add('visible'), i * 80);
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 });

document.querySelectorAll('[data-animate]').forEach(el => observer.observe(el));

/* ── Counter animation ── */
function animateCounter(el, target) {
  const duration = 1800;
  const start    = performance.now();
  const step = now => {
    const t = Math.min((now - start) / duration, 1);
    const ease = t < .5 ? 2*t*t : -1+(4-2*t)*t;
    el.textContent = Math.floor(ease * target).toLocaleString('ar-DZ');
    if (t < 1) requestAnimationFrame(step);
    else el.textContent = target.toLocaleString('ar-DZ');
  };
  requestAnimationFrame(step);
}

const counterObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      document.querySelectorAll('.stat-num').forEach(el => {
        animateCounter(el, parseInt(el.dataset.target, 10));
      });
      counterObserver.disconnect();
    }
  });
}, { threshold: 0.5 });

const statsEl = document.querySelector('.hero-stats');
if (statsEl) counterObserver.observe(statsEl);

/* ── Testimonials carousel ── */
const track = document.getElementById('testimonialsTrack');
const dots   = document.querySelectorAll('.nav-dot');

function scrollTestimonial(index) {
  const card  = track?.querySelector('.testimonial-card');
  if (!card) return;
  const width = card.offsetWidth + 24;
  track.scrollTo({ left: index * width, behavior: 'smooth' });
  dots.forEach((d, i) => d.classList.toggle('active', i === index));
}

if (track) {
  let autoIdx = 0;
  const autoScroll = setInterval(() => {
    autoIdx = (autoIdx + 1) % dots.length;
    scrollTestimonial(autoIdx);
  }, 4000);

  track.addEventListener('scroll', () => {
    const card  = track.querySelector('.testimonial-card');
    if (!card) return;
    const idx = Math.round(track.scrollLeft / (card.offsetWidth + 24));
    dots.forEach((d, i) => d.classList.toggle('active', i === idx));
    autoIdx = idx;
  }, { passive: true });

  track.addEventListener('mouseenter', () => clearInterval(autoScroll));
}

window.scrollTestimonial = scrollTestimonial;

/* ── Contact form ── */
function handleContact(e) {
  e.preventDefault();
  const btn     = e.target.querySelector('.btn-submit');
  const success = document.getElementById('formSuccess');
  btn.textContent = '...جارٍ الإرسال';
  btn.disabled    = true;

  setTimeout(() => {
    btn.textContent = 'تم الإرسال ✓';
    btn.style.background = '#2E7D52';
    if (success) success.style.display = 'block';
    e.target.reset();
    setTimeout(() => {
      btn.textContent      = 'إرسال الرسالة ✉️';
      btn.style.background = '';
      btn.disabled         = false;
      if (success) success.style.display = 'none';
    }, 4000);
  }, 1200);
}
window.handleContact = handleContact;

/* ── Language toggle (placeholder) ── */
document.getElementById('langToggle')?.addEventListener('click', function () {
  this.textContent = this.textContent === 'FR' ? 'AR' : 'FR';
});

/* ── Smooth scroll for nav links ── */
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    const id = link.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if (el) {
      e.preventDefault();
      el.scrollIntoView({ behavior: 'smooth' });
      navLinks.classList.remove('open');
    }
  });
});

/* ── Active nav link highlight on scroll ── */
const sections = document.querySelectorAll('section[id]');
const navAnchors = document.querySelectorAll('.nav-links a[href^="#"]');

const sectionObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      navAnchors.forEach(a => {
        a.style.color = a.getAttribute('href') === `#${entry.target.id}` ? 'var(--primary)' : '';
      });
    }
  });
}, { threshold: 0.4 });

sections.forEach(s => sectionObserver.observe(s));
