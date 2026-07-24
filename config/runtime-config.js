// Публичная конфигурация отдельного проекта Supabase AB Kitchen.
window.ABK_BASE_PATH = window.location.hostname.endsWith('github.io') ? '/ab-kitchen' : '';
window.abkUrl = function(path) {
    const normalized = path.startsWith('/') ? path : '/' + path;
    return window.ABK_BASE_PATH + normalized;
};

window.ABK_CONFIG = Object.freeze({
    SUPABASE_URL: 'https://bdwexffrbtzszfobzmwk.supabase.co',
    SUPABASE_ANON_KEY: 'sb_publishable_rzWLkmbWGZIwbsx452cWng_XT3Gu0MI'
});
