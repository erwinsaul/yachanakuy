// Author: ErwinSaul

(function() {
    'use strict';

    const TRANSITION_DURATION = 800;
    const DEBOUNCE_TIME = 1000;
    
    let SWIPE_THRESHOLD = 30;
    let sections = [];
    let currentVerticalIndex = 0;
    let currentHorizontalIndexes = [];
    let isAnimating = false;
    let touchStartY = 0;
    let touchStartX = 0;
    let currentScreenSize = 'desktop';
    let usedColors = new Set();
    let baseColors = [ '#FFFFFF', '#144D85', '#B33536'];

    function initFreePage() {
        sections = Array.from(document.querySelectorAll('.section'));
        
        if (sections.length === 0) {
            console.error('FreePage.js: No se encontraron secciones con clase .section');
            return;
        }

        const container = document.getElementById('fullscreen-container');
        const baseColorsAttr = container?.getAttribute('data-base-colors');
        if (baseColorsAttr) {
            baseColors = baseColorsAttr.split(',').map(c => c.trim()).filter(c => c);
        }

        currentHorizontalIndexes = sections.map(() => 0);
        setupHorizontalSlides();
        setupVideos();
        positionSections();

        const hash = window.location.hash;
        if (hash) {
            const targetSection = document.querySelector(hash);
            if (targetSection) {
                currentVerticalIndex = sections.indexOf(targetSection);
            }
        }

        updateActiveSection();
        updateColors();
        updateArrows();
        updateMenuIndicator();
        bindEvents();
        handleResponsive();

        console.log('FreePage.js iniciado correctamente');
    }

    function setupHorizontalSlides() {
        sections.forEach((section, index) => {
            if (section.classList.contains('horizontal-slides')) {
                const slides = Array.from(section.querySelectorAll('.slide'));
                
                if (slides.length > 0) {
                    const wrapper = document.createElement('div');
                    wrapper.className = 'slides-wrapper';
                    
                    slides.forEach(slide => {
                        wrapper.appendChild(slide);
                    });
                    
                    section.innerHTML = '';
                    section.appendChild(wrapper);
                }
            }
        });
    }

    function setupVideos() {
        sections.forEach(section => {
            const videoUrl = section.getAttribute('data-video');
            if (videoUrl) {
                const iframe = document.createElement('iframe');
                iframe.src = `${videoUrl}?autoplay=1&loop=1&mute=1&controls=0&playlist=${extractVideoId(videoUrl)}`;
                iframe.frameBorder = '0';
                iframe.allow = 'autoplay; encrypted-media';
                iframe.allowFullscreen = false;
                
                section.insertBefore(iframe, section.firstChild);
                section.classList.add('light-text');
            }
        });
    }

    function extractVideoId(url) {
        const match = url.match(/embed\/([^?]+)/);
        return match ? match[1] : '';
    }

    function positionSections() {
        sections.forEach((section, index) => {
            if (index === currentVerticalIndex) {
                section.style.transform = 'translateY(0)';
                section.classList.add('active');
            } else if (index < currentVerticalIndex) {
                section.style.transform = 'translateY(-100vh)';
            } else {
                section.style.transform = 'translateY(100vh)';
            }
        });
    }

    function moveVertical(direction) {
        if (isAnimating) return;

        const oldIndex = currentVerticalIndex;
        const newIndex = (currentVerticalIndex + direction + sections.length) % sections.length;
        
        if (newIndex === currentVerticalIndex) return;

        isAnimating = true;

        const isLoopingDown = (oldIndex === sections.length - 1 && direction === 1);
        const isLoopingUp = (oldIndex === 0 && direction === -1);
        
        const currentSection = sections[oldIndex];
        
        if (isLoopingDown) {
            currentSection.classList.add('rotating-right');
        } else if (isLoopingUp) {
            currentSection.classList.add('rotating-left');
        }

        sections.forEach((section, index) => {
            if (index === newIndex) {
                section.style.transform = 'translateY(0)';
                section.classList.add('active');
            } else if (index === oldIndex) {
                section.style.transform = direction > 0 ? 'translateY(-100vh)' : 'translateY(100vh)';
                section.classList.remove('active');
            }
        });

        currentVerticalIndex = newIndex;

        updateColors();
        updateArrows();
        updateHash();
        updateMenuIndicator();

        setTimeout(() => {
            currentSection.classList.remove('rotating-right', 'rotating-left');
            isAnimating = false;
        }, TRANSITION_DURATION);
    }

    function moveHorizontal(direction) {
        if (isAnimating) return;

        const currentSection = sections[currentVerticalIndex];
        
        if (!currentSection.classList.contains('horizontal-slides')) return;

        const wrapper = currentSection.querySelector('.slides-wrapper');
        const slides = wrapper.querySelectorAll('.slide');
        
        if (slides.length <= 1) return;

        isAnimating = true;

        const currentSlideIndex = currentHorizontalIndexes[currentVerticalIndex];
        const newSlideIndex = (currentSlideIndex + direction + slides.length) % slides.length;

        const isLoopingRight = (currentSlideIndex === slides.length - 1 && direction === 1);
        const isLoopingLeft = (currentSlideIndex === 0 && direction === -1);
        
        if (isLoopingRight) {
            wrapper.classList.add('rotating-horizontal-right');
        } else if (isLoopingLeft) {
            wrapper.classList.add('rotating-horizontal-left');
        }

        currentHorizontalIndexes[currentVerticalIndex] = newSlideIndex;
        wrapper.style.transform = `translateX(-${newSlideIndex * 100}%)`;

        updateArrows();

        setTimeout(() => {
            wrapper.classList.remove('rotating-horizontal-right', 'rotating-horizontal-left');
            isAnimating = false;
        }, TRANSITION_DURATION);
    }

    function pushTransition(targetIndex) {
        if (isAnimating || targetIndex === currentVerticalIndex) return;

        isAnimating = true;

        const direction = targetIndex > currentVerticalIndex ? 1 : -1;
        const steps = Math.abs(targetIndex - currentVerticalIndex);

        let currentStep = 0;

        function animateStep() {
            if (currentStep >= steps) {
                isAnimating = false;
                return;
            }

            const nextIndex = currentVerticalIndex + direction;
            
            sections.forEach((section, index) => {
                if (index === nextIndex) {
                    section.style.transform = 'translateY(0)';
                    section.classList.add('active');
                } else if (index === currentVerticalIndex) {
                    section.style.transform = direction > 0 ? 'translateY(-100vh)' : 'translateY(100vh)';
                    section.classList.remove('active');
                }
            });

            currentVerticalIndex = nextIndex;
            updateColors();
            updateArrows();
            updateMenuIndicator();

            currentStep++;

            if (currentStep < steps) {
                setTimeout(animateStep, 200);
            } else {
                updateHash();
                setTimeout(() => {
                    isAnimating = false;
                }, TRANSITION_DURATION);
            }
        }

        animateStep();
    }

    function generateUniqueColor() {
        if (baseColors.length > 0) {
            return generateVariantFromBase();
        }
        
        let color, r, g, b, brightness;
        let attempts = 0;
        const maxAttempts = 50;
        
        do {
            r = Math.floor(Math.random() * 256);
            g = Math.floor(Math.random() * 256);
            b = Math.floor(Math.random() * 256);
            
            brightness = (r + g + b) / 3;
            
            color = '#' + [r, g, b].map(x => {
                const hex = x.toString(16);
                return hex.length === 1 ? '0' + hex : hex;
            }).join('');
            
            attempts++;
            
        } while ((usedColors.has(color) || brightness < 60 || brightness > 220) && attempts < maxAttempts);
        
        usedColors.add(color);
        return color;
    }

    function generateVariantFromBase() {
        const baseColor = baseColors[Math.floor(Math.random() * baseColors.length)];
        let hsv = hexToHSV(baseColor);
        let color;
        let attempts = 0;
        const maxAttempts = 100;
        
        do {
            const hueVar = (Math.random() - 0.5) * 0.2;
            const satVar = (Math.random() - 0.5) * 0.4;
            const valVar = (Math.random() - 0.5) * 0.3;
            
            let newH = (hsv.h + hueVar + 1) % 1;
            let newS = Math.max(0.3, Math.min(1, hsv.s + satVar));
            let newV = Math.max(0.3, Math.min(0.9, hsv.v + valVar));
            
            color = hsvToHex(newH, newS, newV);
            attempts++;
            
        } while (usedColors.has(color) && attempts < maxAttempts);
        
        usedColors.add(color);
        return color;
    }

    function hexToHSV(hex) {
        const r = parseInt(hex.slice(1, 3), 16) / 255;
        const g = parseInt(hex.slice(3, 5), 16) / 255;
        const b = parseInt(hex.slice(5, 7), 16) / 255;
        
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const delta = max - min;
        
        let h = 0;
        if (delta !== 0) {
            if (max === r) h = ((g - b) / delta) % 6;
            else if (max === g) h = (b - r) / delta + 2;
            else h = (r - g) / delta + 4;
            h /= 6;
            if (h < 0) h += 1;
        }
        
        const s = max === 0 ? 0 : delta / max;
        const v = max;
        
        return { h, s, v };
    }

    function hsvToHex(h, s, v) {
        const i = Math.floor(h * 6);
        const f = h * 6 - i;
        const p = v * (1 - s);
        const q = v * (1 - f * s);
        const t = v * (1 - (1 - f) * s);
        
        let r, g, b;
        switch (i % 6) {
            case 0: r = v; g = t; b = p; break;
            case 1: r = q; g = v; b = p; break;
            case 2: r = p; g = v; b = t; break;
            case 3: r = p; g = q; b = v; break;
            case 4: r = t; g = p; b = v; break;
            case 5: r = v; g = p; b = q; break;
        }
        
        const toHex = x => {
            const hex = Math.round(x * 255).toString(16);
            return hex.length === 1 ? '0' + hex : hex;
        };
        
        return '#' + toHex(r) + toHex(g) + toHex(b);
    }

    function updateColors() {
        const currentSection = sections[currentVerticalIndex];
        
        if (currentSection.hasAttribute('data-video')) {
            updateArrowContrast('#000000');
            return;
        }

        const bgColor = generateUniqueColor();
        currentSection.style.backgroundColor = bgColor;

        const luminance = calculateLuminance(bgColor);
        
        if (luminance < 0.5) {
            currentSection.classList.remove('dark-text');
            currentSection.classList.add('light-text');
        } else {
            currentSection.classList.remove('light-text');
            currentSection.classList.add('dark-text');
        }
        
        updateArrowContrast(bgColor);
    }

    function updateArrowContrast(bgColor) {
        const arrows = document.querySelectorAll('.arrow');
        const luminance = calculateLuminance(bgColor);
        
        arrows.forEach(arrow => {
            if (luminance < 0.5) {
                arrow.classList.remove('arrow-dark');
                arrow.classList.add('arrow-light');
            } else {
                arrow.classList.remove('arrow-light');
                arrow.classList.add('arrow-dark');
            }
        });
    }

    function calculateLuminance(color) {
        const hex = color.replace('#', '');
        const r = parseInt(hex.substr(0, 2), 16) / 255;
        const g = parseInt(hex.substr(2, 2), 16) / 255;
        const b = parseInt(hex.substr(4, 2), 16) / 255;
        
        return (r * 0.299 + g * 0.587 + b * 0.114);
    }

    function updateMenuIndicator() {
        const menuLinks = document.querySelectorAll('.menu a');
        
        menuLinks.forEach((link, index) => {
            if (index === currentVerticalIndex) {
                link.classList.add('active');
            } else {
                link.classList.remove('active');
            }
        });
    }

    function updateArrows() {
        const arrowUp = document.getElementById('arrow-up');
        const arrowDown = document.getElementById('arrow-down');
        const arrowLeft = document.getElementById('arrow-left');
        const arrowRight = document.getElementById('arrow-right');

        if (sections.length <= 1) {
            arrowUp.classList.add('hidden');
            arrowDown.classList.add('hidden');
        } else {
            arrowUp.classList.remove('hidden');
            arrowDown.classList.remove('hidden');
        }

        const currentSection = sections[currentVerticalIndex];
        
        if (currentSection.classList.contains('horizontal-slides')) {
            const wrapper = currentSection.querySelector('.slides-wrapper');
            const slides = wrapper ? wrapper.querySelectorAll('.slide') : [];
            
            if (slides.length > 1) {
                arrowLeft.style.display = 'block';
                arrowRight.style.display = 'block';
            } else {
                arrowLeft.style.display = 'none';
                arrowRight.style.display = 'none';
            }
        } else {
            arrowLeft.style.display = 'none';
            arrowRight.style.display = 'none';
        }
    }

    function updateHash() {
        const currentSection = sections[currentVerticalIndex];
        const sectionId = currentSection.id;
        
        if (sectionId) {
            history.replaceState(null, null, `#${sectionId}`);
        }
    }

    function updateActiveSection() {
        sections.forEach((section, index) => {
            if (index === currentVerticalIndex) {
                section.classList.add('active');
            } else {
                section.classList.remove('active');
            }
        });
    }

    function handleResponsive() {
        const handleResize = () => {
            const width = window.innerWidth;
            const height = window.innerHeight;
            const isPortrait = height > width;
            const isLandscape = width > height;
            
            if (width < 480) {
                SWIPE_THRESHOLD = 25;
                currentScreenSize = 'mobile-small';
            } else if (width < 768) {
                SWIPE_THRESHOLD = 30;
                currentScreenSize = 'mobile';
            } else if (width < 1200) {
                SWIPE_THRESHOLD = 35;
                currentScreenSize = 'tablet';
            } else {
                SWIPE_THRESHOLD = 40;
                currentScreenSize = 'desktop';
            }
            
            const paddingBottom = isPortrait ? Math.max(100, height * 0.12) : Math.max(60, height * 0.08);
            const paddingTop = isPortrait ? Math.max(70, height * 0.08) : Math.max(60, height * 0.06);
            
            document.documentElement.style.setProperty('--padding-bottom', `${paddingBottom}px`);
            document.documentElement.style.setProperty('--padding-top', `${paddingTop}px`);
            
            document.body.classList.toggle('landscape-mode', isLandscape && width <= 1024);
            document.body.classList.toggle('portrait-mode', isPortrait);
            
            scaleContent();
            updateArrows();
        };
        
        window.addEventListener('resize', handleResize);
        window.addEventListener('orientationchange', handleResize);
        handleResize();
    }

    function scaleContent() {
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        document.body.classList.remove('screen-mobile-small', 'screen-mobile', 'screen-tablet', 'screen-desktop');
        document.body.classList.add(`screen-${currentScreenSize}`);
        
        positionSections();
    }

    function bindEvents() {
        let wheelTimeout;
        window.addEventListener('wheel', (e) => {
            if (wheelTimeout) return;
            
            e.preventDefault();
            
            if (e.deltaY > 0) {
                moveVertical(1);
            } else if (e.deltaY < 0) {
                moveVertical(-1);
            }
            
            wheelTimeout = setTimeout(() => {
                wheelTimeout = null;
            }, DEBOUNCE_TIME);
        }, { passive: false });

        window.addEventListener('keydown', (e) => {
            switch(e.key) {
                case 'ArrowDown':
                    e.preventDefault();
                    moveVertical(1);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    moveVertical(-1);
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    moveHorizontal(-1);
                    break;
                case 'ArrowRight':
                    e.preventDefault();
                    moveHorizontal(1);
                    break;
            }
        });

        let touchStartTime = 0;
        
        window.addEventListener('touchstart', (e) => {
            touchStartY = e.touches[0].clientY;
            touchStartX = e.touches[0].clientX;
            touchStartTime = Date.now();
        }, { passive: true });

        window.addEventListener('touchend', (e) => {
            const touchEndY = e.changedTouches[0].clientY;
            const touchEndX = e.changedTouches[0].clientX;
            const touchEndTime = Date.now();
            
            const deltaY = touchStartY - touchEndY;
            const deltaX = touchStartX - touchEndX;
            const deltaTime = touchEndTime - touchStartTime;

            const minVelocity = currentScreenSize === 'mobile-small' ? 0.2 : 0.3;
            const velocityY = Math.abs(deltaY) / deltaTime;
            const velocityX = Math.abs(deltaX) / deltaTime;

            if (Math.abs(deltaY) > Math.abs(deltaX)) {
                if (Math.abs(deltaY) > SWIPE_THRESHOLD || velocityY > minVelocity) {
                    if (deltaY > 0) {
                        moveVertical(1);
                    } else {
                        moveVertical(-1);
                    }
                }
            } else {
                if (Math.abs(deltaX) > SWIPE_THRESHOLD || velocityX > minVelocity) {
                    if (deltaX > 0) {
                        moveHorizontal(1);
                    } else {
                        moveHorizontal(-1);
                    }
                }
            }
        }, { passive: true });

        document.getElementById('arrow-up').addEventListener('click', () => moveVertical(-1));
        document.getElementById('arrow-down').addEventListener('click', () => moveVertical(1));
        document.getElementById('arrow-left').addEventListener('click', () => moveHorizontal(-1));
        document.getElementById('arrow-right').addEventListener('click', () => moveHorizontal(1));

        const menuLinks = document.querySelectorAll('.menu a');
        menuLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const targetIndex = parseInt(link.getAttribute('data-index'));
                
                if (!isNaN(targetIndex) && targetIndex >= 0 && targetIndex < sections.length) {
                    pushTransition(targetIndex);
                }
            });
        });

        window.addEventListener('resize', () => {
            positionSections();
            scaleContent();
        });
    }

    // Exportar funciones para uso externo
    window.FreePage = {
        init: initFreePage
    };

    // Auto-inicializar solo si no es una página LiveView
    if (!document.querySelector('[data-phx-main]')) {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initFreePage);
        } else {
            initFreePage();
        }
    }

})();