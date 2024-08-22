const elements = {
  mobileMenu: document.querySelector('#mobile-menu'),
  mobileMenuButton: document.querySelector('#mobile-menu-button'),
  closeMenuButton: document.querySelector('#close-menu-button'),
  header: document.querySelector('#main-header')
};

if (Object.values(elements).some(el => !el)) {
  console.error('One or more required HTML elements are missing');
} else {
  let isMenuOpen = false;
  let lastScrollY = window.scrollY;

  const toggleMobileMenu = () => {
    isMenuOpen = !isMenuOpen;
    elements.mobileMenu.classList.toggle('hidden', !isMenuOpen);
    document.body.classList.toggle('overflow-hidden', isMenuOpen);
  };

  const handleButtonClick = (e) => {
    e.preventDefault();
    toggleMobileMenu();
  };

  const handleLinkClick = (e) => {
    e.preventDefault();
    const href = e.currentTarget.getAttribute('href');
    toggleMobileMenu();
    setTimeout(() => { window.location.href = href; }, 300);
  };

  const handleScroll = () => {
    if (isMenuOpen) return;
    
    const currentScrollY = window.scrollY;
    const shouldHideHeader = currentScrollY > lastScrollY && currentScrollY > 75;
    
    elements.header.classList.toggle('-translate-y-full', shouldHideHeader);
    elements.header.classList.toggle('opacity-0', shouldHideHeader);
    
    lastScrollY = currentScrollY;
  };

  elements.mobileMenuButton.addEventListener('click', handleButtonClick);
  elements.closeMenuButton.addEventListener('click', handleButtonClick);
  elements.mobileMenu.querySelectorAll('a').forEach(link => 
    link.addEventListener('click', handleLinkClick)
  );

  window.addEventListener('scroll', _.throttle(handleScroll, 100));
}
