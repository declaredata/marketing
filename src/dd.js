const mobileMenu = document.querySelector('#mobile-menu');
const mobileMenuButton = document.querySelector('#mobile-menu-button');
const closeMenuButton = document.querySelector('#close-menu-button');
const header = document.querySelector('#main-header');

if (!mobileMenu || !mobileMenuButton || !closeMenuButton || !header) {
  console.error('One or more required HTML elements are missing');
} else {
  const toggleMenu = () => {
    mobileMenu.classList.toggle('hidden');
    document.body.classList.toggle('overflow-hidden');
  };

  mobileMenuButton.addEventListener('click', toggleMenu);
  closeMenuButton.addEventListener('click', toggleMenu);

  mobileMenu.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      toggleMenu();
      // Small delay to allow menu closing animation
      setTimeout(() => {}, 150);
    });
  });

  let lastScrollY = window.scrollY;
  window.addEventListener('scroll', () => {
    if (mobileMenu.classList.contains('hidden')) {
      const currentScrollY = window.scrollY;
      const isScrollingDown = currentScrollY > lastScrollY;
      
      header.classList.toggle('-translate-y-full', isScrollingDown && currentScrollY > 75);
      header.classList.toggle('opacity-0', isScrollingDown && currentScrollY > 75);

      lastScrollY = currentScrollY;
    }
  });
}
