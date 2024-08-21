// Mobile menu functionality
const mobileMenu = document.querySelector('#mobile-menu');
const mobileMenuButton = document.querySelector('#mobile-menu-button');
const closeMenuButton = document.querySelector('#close-menu-button');

if (!mobileMenu || !mobileMenuButton || !closeMenuButton) {
    console.error('menu html elements missing');
} else {
    const toggleMobileMenu = () => {
        mobileMenu.classList.toggle('hidden');
        document.body.classList.toggle('overflow-hidden');
    };

    mobileMenuButton.addEventListener('click', (e) => {
        e.preventDefault();
        toggleMobileMenu();
    });

    closeMenuButton.addEventListener('click', (e) => {
        e.preventDefault();
        toggleMobileMenu();
    });

    mobileMenu.querySelectorAll('a').forEach(link => 
        link.addEventListener('click', toggleMobileMenu)
    );
}

const header = document.querySelector('#main-header');
let lastScrollY = window.scrollY;

window.addEventListener('scroll', () => {
    if (mobileMenu.classList.contains('hidden')) {
        const currentScrollY = window.scrollY;
        
        if (currentScrollY > lastScrollY && currentScrollY > 75) {
            header.classList.add('-translate-y-full', 'opacity-0');
        } else {
            header.classList.remove('-translate-y-full', 'opacity-0');
        }

        lastScrollY = currentScrollY;
    }
});
