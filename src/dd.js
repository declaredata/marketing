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
  mobileMenu.querySelectorAll('a').forEach((link) => {
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
      background-color: #E0B0FF;
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

  platformBtns[0].classList.add('selected');

  platformBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      platformBtns.forEach((b) => b.classList.remove('selected'));
      btn.classList.add('selected');

      const platform = btn.dataset.platform;
      commandTexts.forEach((commandText) => {
        const newCommand = commandText.dataset[platform];
        if (newCommand) {
          commandText.textContent = newCommand;
        }
      });

      promptTexts.forEach((promptText) => {
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

  codeBlocks.forEach((block) => {
    const feedbackEl = document.createElement('div');
    feedbackEl.className =
      'absolute inset-0 flex items-center justify-center bg-gray-800 bg-opacity-90 hidden font-normal text-white text-sm rounded-md';
    feedbackEl.innerHTML = 'Copied to clipboard.';
    block.style.position = 'relative';
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
        }, 1000);
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

const initializeSpeedComparison = () => {
  const fuseBar = document.getElementById('fuseProgress');
  const sparkBar = document.getElementById('sparkProgress');
  const sparkLoadingDots = document.getElementById('sparkLoadingDots');
  const fuseTimer = document.getElementById('fuseTimer');
  const sparkTimer = document.getElementById('sparkTimer');

  if (!fuseBar || !sparkBar || !sparkLoadingDots || !fuseTimer || !sparkTimer) return;

  let fuseInterval, sparkInterval;

  const animateNumber = (element, start, end, duration, decimals = 1) => {
    const startTimestamp = performance.now();
    const step = (currentTimestamp) => {
      const progress = Math.min((currentTimestamp - startTimestamp) / duration, 1);
      const current = progress * (end - start) + start;
      element.textContent = current.toFixed(decimals);

      if (progress < 1) {
        requestAnimationFrame(step);
      }
    };
    requestAnimationFrame(step);
  };

  const resetBars = () => {
    if (fuseInterval) clearInterval(fuseInterval);
    if (sparkInterval) clearInterval(sparkInterval);

    fuseBar.style.transition = 'none';
    sparkBar.style.transition = 'none';
    fuseBar.style.width = '0%';
    sparkBar.style.width = '0%';
    sparkLoadingDots.style.opacity = '0';
    fuseTimer.textContent = '0.0';
    sparkTimer.textContent = '0.0';

    fuseBar.offsetHeight;
    sparkBar.offsetHeight;

    fuseBar.style.transition = 'width 700ms ease-out';
    sparkBar.style.transition = 'width 3000ms linear';
    sparkLoadingDots.style.transition = 'opacity 300ms ease-out';
  };

  const startAnimation = () => {
    resetBars();

    // speed up fuse progress
    setTimeout(() => {
      fuseBar.style.width = '15%';
      animateNumber(fuseTimer, 0, 15.2, 1500, 1);
    }, 100);

    // slow down spark progress
    setTimeout(() => {
      sparkBar.style.width = '30%';
      sparkLoadingDots.style.opacity = '1';
      animateNumber(sparkTimer, 0, 36.0, 3000, 1);
    }, 100);

    // reset after animation
    setTimeout(() => {
      sparkLoadingDots.style.opacity = '0';
      setTimeout(resetBars, 250);
    }, 3500);
  };

  // start animation when in view
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          startAnimation();
          const intervalId = setInterval(startAnimation, 4500);

          const exitObserver = new IntersectionObserver((exitEntries) => {
            if (!exitEntries[0].isIntersecting) {
              clearInterval(intervalId);
              observer.observe(entry.target);
              exitObserver.disconnect();
            }
          });
          exitObserver.observe(entry.target);
        }
      });
    },
    {
      threshold: 0.5,
    }
  );

  observer.observe(document.querySelector('.space-y-6'));
};

const initializeCodeTyping = () => {
  const codeDisplay = document.getElementById('codeDisplay');
  const cursor = document.getElementById('codeCursor');

  if (!codeDisplay || !cursor) return;

  const code = [
    'df = spark.read.parquet("s3://data/sales.parquet")',
    'result = df.groupBy("category")\\',
    '         .agg(sum("amount").alias("total"))\\',
    '         .orderBy("total", ascending=False)',
    'df.alias("a").join(df.alias("b"), col("a.id") == col("b.id"))\\',
    '  .select("a.id", "b.id")\\',
    '  .window(Window.partitionBy("a.id").orderBy("b.id")\\',
    '         .rowsBetween(-1, 1))\\',
    '  .agg(sum("a.id").alias("sum"))',
    '',
  ].join('\n');

  let currentText = '';
  let currentIndex = 0;

  const updateCursorPosition = () => {
    const lines = currentText.split('\n');
    const lastLine = lines[lines.length - 1];
    const lastLineElement = Array.from(codeDisplay.childNodes).pop();

    if (lastLineElement) {
      const lineHeight = parseInt(window.getComputedStyle(codeDisplay).lineHeight);
      const totalLines = lines.length;
      cursor.style.top = `${(totalLines - 1) * lineHeight + 16}px`; // 16px for padding
      cursor.style.left = `${lastLine.length * 7.8 + 16}px`; // Approximate character width + padding
    }
  };

  const resetAnimation = () => {
    currentText = '';
    currentIndex = 0;
    codeDisplay.textContent = '';
    cursor.style.opacity = '1';
    cursor.style.top = '16px';
    cursor.style.left = '16px';
  };

  const typeCode = () => {
    if (currentIndex < code.length) {
      currentText += code[currentIndex];
      codeDisplay.textContent = currentText;
      updateCursorPosition();
      currentIndex++;
      setTimeout(typeCode, 40); // Slightly faster typing
    } else {
      setTimeout(resetAnimation, 2000);
    }
  };

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          typeCode();
          const intervalId = setInterval(() => {
            resetAnimation();
            setTimeout(typeCode, 500);
          }, 8000);

          const exitObserver = new IntersectionObserver((exitEntries) => {
            if (!exitEntries[0].isIntersecting) {
              clearInterval(intervalId);
              resetAnimation();
              observer.observe(entry.target);
              exitObserver.disconnect();
            }
          });
          exitObserver.observe(entry.target);
        }
      });
    },
    {
      threshold: 0.5,
    }
  );

  observer.observe(codeDisplay.parentElement);
};

const initializeDevCycle = () => {
  const indicator = document.getElementById('cycleIndicator');
  if (!indicator) return;

  const animateCycle = () => {
    indicator.style.opacity = '1';
    indicator.style.transform = 'translate(-50%, -50%) translateX(-16px)';

    setTimeout(() => {
      indicator.style.transform = 'translate(-50%, -50%) translateX(150px)';
    }, 100);

    setTimeout(() => {
      indicator.style.opacity = '0';
    }, 800);

    setTimeout(() => {
      indicator.style.transition = 'none';
      indicator.style.transform = 'translate(-50%, -50%) translateX(-16px)';
      setTimeout(() => {
        indicator.style.transition = 'all 700ms ease-in-out';
      }, 50);
    }, 1000);
  };

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setTimeout(() => {
            indicator.style.transition = 'all 700ms ease-in-out';
            animateCycle();
            const intervalId = setInterval(animateCycle, 2000);

            const exitObserver = new IntersectionObserver((exitEntries) => {
              if (!exitEntries[0].isIntersecting) {
                clearInterval(intervalId);
                observer.observe(entry.target);
                exitObserver.disconnect();
              }
            });
            exitObserver.observe(entry.target);
          }, 500);
        }
      });
    },
    {
      threshold: 0.5,
    }
  );

  observer.observe(indicator.parentElement);
};

const initializeScrollFade = () => {
  const observerOptions = {
    threshold: 0.25,
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('opacity-100');
        observer.unobserve(entry.target); // Only animate once
      }
    });
  }, observerOptions);

  document.querySelectorAll('[data-aos]').forEach((element) => {
    observer.observe(element);
  });
};

// initialize all components
const initializeAll = () => {
  addPlatformStyles();
  initializeCopyCode();
  initializeSpeedComparison();
  initializeCodeTyping();
  initializeDevCycle();
  initializePlatformSwitch();
  initializeScrollFade();
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeAll);
} else {
  initializeAll();
}
