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

const addPlatformStyles = () => {
  const style = document.createElement('style');
  style.textContent = `
    .platform-btn {
      padding: 0.25rem 0.5rem;
      color: #6B7280;
      cursor: pointer;
      transition: all 0.2s;
      position: relative;
      background: none;
    }
    .platform-btn:hover {
      color: #111827;
    }
    .platform-btn.selected {
      color: #111827;
    }
    .platform-btn.selected::after {
      content: '';
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 2px;
      background-color: #6B7280;
      border-radius: 1px;
    }
  `;
  document.head.appendChild(style);
};

// switch functionality
const initializePlatformSwitch = () => {
  const platformBtns = document.querySelectorAll('.platform-btn');
  const commandTexts = document.querySelectorAll('.command-text');
  const promptTexts = document.querySelectorAll('.platform-prompt');

  if (!platformBtns.length) return;

  // Ensure first button is selected by default
  platformBtns[0].classList.add('selected');
  
  platformBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      // Update button styles
      platformBtns.forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');

      // update command text
      const platform = btn.dataset.platform;
      commandTexts.forEach(commandText => {
        const newCommand = commandText.dataset[platform];
        if (newCommand) {
          commandText.textContent = newCommand;
        }
      });
      
      promptTexts.forEach(promptText => {
        if (promptText) {
          promptText.textContent = platform === 'windows' ? '>' : '$';
        }
      });
    });
  });
};

// code block copy functionality
const initializeCopyCode = () => {
  const codeBlocks = document.querySelectorAll('.copy-code-block');
  if (!codeBlocks.length) return;

  codeBlocks.forEach(block => {
    // Create feedback element inside each code block
    const feedbackEl = document.createElement('div');
    feedbackEl.className = 'absolute inset-0 flex items-center justify-center bg-gray-800 bg-opacity-90 hidden font-thin text-purple-600';
    feedbackEl.innerHTML = 'Copied to clipboard.';
    block.style.position = 'relative'; // Ensure absolute positioning works
    block.appendChild(feedbackEl);

    block.classList.add('cursor-pointer');
    block.addEventListener('click', async () => {
      const textToCopy = block.querySelector('.command-text')?.textContent?.trim();
      if (!textToCopy) return;
      try {
        await navigator.clipboard.writeText(textToCopy);
        feedbackEl.classList.remove('hidden');
        setTimeout(() => {
          feedbackEl.classList.add('hidden');
        }, 1000); // Reduced time since it's more visible now
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

// initialize all components
const initializeAll = () => {
  addPlatformStyles();
  initializeCopyCode();
  initializePlatformSwitch();
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeAll);
} else {
  initializeAll();
}
