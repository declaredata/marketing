const mobileMenu = document.querySelector('#mobile-menu');
const mobileMenuButton = document.querySelector('#mobile-menu-button');
const closeMenuButton = document.querySelector('#close-menu-button');
const header = document.querySelector('#main-header');

if (!mobileMenu || !mobileMenuButton || !closeMenuButton || !header) {
    console.error('One or more required HTML elements are missing');
} else {
    let isMenuOpen = false;

    const toggleMobileMenu = () => {
        isMenuOpen = !isMenuOpen;
        mobileMenu.classList.toggle('hidden', !isMenuOpen);
        document.body.classList.toggle('overflow-hidden', isMenuOpen);
    };

    const handleButtonClick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        toggleMobileMenu();
    };

    mobileMenuButton.addEventListener('click', handleButtonClick);
    closeMenuButton.addEventListener('click', handleButtonClick);

    mobileMenu.querySelectorAll('a').forEach(link => 
        link.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
            const href = link.getAttribute('href');
            toggleMobileMenu();
            setTimeout(() => {
                window.location.href = href;
            }, 300); // Adjust this delay if needed to match your CSS transition time
        })
    );

    const debounce = (func, wait) => {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    };

    let lastScrollY = window.scrollY;

    const handleScroll = debounce(() => {
        if (!isMenuOpen) {
            const currentScrollY = window.scrollY;
            
            if (currentScrollY > lastScrollY && currentScrollY > 75) {
                header.classList.add('-translate-y-full', 'opacity-0');
            } else {
                header.classList.remove('-translate-y-full', 'opacity-0');
            }
            lastScrollY = currentScrollY;
        }
    }, 100); // Adjust debounce delay as needed

    window.addEventListener('scroll', handleScroll);
}
