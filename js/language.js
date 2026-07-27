// ==========================================================
// language.js — J5 Trading Strategy
// Bilingual EN/ES with localStorage persistence
// ==========================================================

(function() {

    // ─── Config ───
    const DEFAULT_LANG = 'en';
    const STORAGE_KEY = 'j5_lang';

    // ─── DOM refs ───
    const langButtons = document.querySelectorAll('.language-switcher button');
    const allLangElements = document.querySelectorAll('.lang-en, .lang-es');

    // ─── Functions ───
    function setLanguage(lang) {
        // Guardar en localStorage
        try {
            localStorage.setItem(STORAGE_KEY, lang);
        } catch(e) { /* ignore */ }

        // Cambiar atributo html
        document.documentElement.lang = lang;

        // Mostrar/ocultar elementos según idioma
        allLangElements.forEach(el => {
            if (el.classList.contains('lang-' + lang)) {
                el.style.display = '';
            } else {
                el.style.display = 'none';
            }
        });

        // Actualizar botones activos
        langButtons.forEach(btn => {
            btn.classList.remove('active');
            const btnLang = btn.getAttribute('data-lang');
            if (btnLang === lang) {
                btn.classList.add('active');
            }
        });
    }

    function getSavedLanguage() {
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            if (saved === 'en' || saved === 'es') {
                return saved;
            }
        } catch(e) { /* ignore */ }
        return DEFAULT_LANG;
    }

    // ─── Init ───
    function init() {
        // Asignar data-lang a los botones si no lo tienen
        langButtons.forEach(btn => {
            if (!btn.hasAttribute('data-lang')) {
                const text = btn.textContent.trim();
                if (text.includes('EN')) btn.setAttribute('data-lang', 'en');
                else if (text.includes('ES')) btn.setAttribute('data-lang', 'es');
            }
        });

        // Cargar idioma guardado
        const savedLang = getSavedLanguage();
        setLanguage(savedLang);

        // Event listeners
        langButtons.forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                const lang = this.getAttribute('data-lang');
                if (lang) {
                    setLanguage(lang);
                }
            });
        });
    }

    // ─── Ejecutar cuando el DOM esté listo ───
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // ─── Exponer función global para uso inline ───
    window.setLanguage = setLanguage;

})();
