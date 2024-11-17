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

// code block copy functionality
const initializeCopyCode = () => {
  const codeBlocks = document.querySelectorAll('.copy-code-block');
  if (!codeBlocks.length) return;

  const feedbackEl = document.createElement('div');
  feedbackEl.className = 'fixed top-5 left-1/2 -translate-x-1/2 bg-purple-200 text-gray-800 px-4 py-2 rounded-lg hidden z-50 shadow-md transition-opacity duration-200';
  feedbackEl.textContent = 'Copied command. Let\'s go!';
  document.body.appendChild(feedbackEl);

  codeBlocks.forEach(block => {
    block.classList.add('cursor-pointer');
    block.addEventListener('click', async () => {
      const textToCopy = block.querySelector('.command-text')?.textContent?.trim();
      if (!textToCopy) return;

      try {
        await navigator.clipboard.writeText(textToCopy);
        feedbackEl.classList.remove('hidden');
        setTimeout(() => {
          feedbackEl.classList.add('hidden');
        }, 2000);
      } catch (err) {
        console.error('Failed to copy text:', err);
      }
    });

    block.addEventListener('mouseenter', () => {
      const copyIcon = block.querySelector('.copy-icon');
      if (copyIcon) copyIcon.classList.remove('text-gray-500');
    });

    block.addEventListener('mouseleave', () => {
      const copyIcon = block.querySelector('.copy-icon');
      if (copyIcon) copyIcon.classList.add('text-gray-500');
    });
  });
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeCopyCode);
} else {
  initializeCopyCode();
}
