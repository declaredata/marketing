const mobileMenuButton = document.querySelector('#mobile-menu-button');
const closeMenuButton = document.querySelector('#close-menu-button');
const mobileMenu = document.querySelector('#mobile-menu');

if (mobileMenuButton && closeMenuButton && mobileMenu) {
    const toggleMobileMenu = () => {
        mobileMenu.classList.toggle('active');
        document.body.classList.toggle('menu-open');
    };

    mobileMenuButton.addEventListener('click', toggleMobileMenu);
    closeMenuButton.addEventListener('click', toggleMobileMenu);

    mobileMenu.querySelectorAll('a').forEach(link => 
        link.addEventListener('click', toggleMobileMenu)
    );

} else {
    console.error('elements not found');
}
