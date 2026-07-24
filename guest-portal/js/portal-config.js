// ==================== PORTAL-CONFIG.JS ====================
// Конфигурация Supabase для Guest Portal
// ВАЖНО: Этот файл должен быть подключен ПЕРВЫМ в HTML

(function() {
'use strict';

// Определяем окружение по домену
// ВАЖНО: localhost / file:// / vercel preview / dev-* домены считаем DEV
const hostname = window.location.hostname;

const isFileProtocol = window.location.protocol === 'file:';
const isLocalhost =
  hostname === 'localhost' ||
  hostname === '127.0.0.1' ||
  hostname.startsWith('192.168.') ||
  hostname.startsWith('10.') ||
  hostname.startsWith('172.');

const isDev =
  isFileProtocol ||
  isLocalhost ||
  hostname.includes('vercel.app') ||
  hostname.includes('dev-ab-kitchen') ||
  hostname.includes('dev.') ||
  hostname.includes('-dev');

const env = window.ABK_CONFIG;
if (!env?.SUPABASE_URL || !env?.SUPABASE_ANON_KEY) {
    throw new Error('AB Kitchen: Supabase runtime configuration is missing');
}

window.PORTAL_CONFIG = {
    ...env,
    ENV: isDev ? 'development' : 'production',
    IS_DEV: isDev,

    // Цвета портала
    COLORS: {
        GREEN: '#147D30',
        ORANGE: '#FFBA47',
        BG: '#F5F3EF'
    },

    // Storage bucket для фото
    PHOTO_BUCKET: 'vaishnava-photos',

    // Telegram бот
    TELEGRAM_BOT_NAME: 'rupaseva_bot'
};

// NB: debug() определён в utils.js, но portal-config грузится отдельным стеком.
// [ENV] лог всегда виден — намеренно, помогает диагностировать окружение.
console.log('[ENV]', window.PORTAL_CONFIG.ENV + ':', location.hostname || 'file://', '→', window.PORTAL_CONFIG.SUPABASE_URL);

// Создаём ЕДИНСТВЕННЫЙ экземпляр Supabase клиента
if (typeof window.supabase !== 'undefined') {
    window.portalSupabase = window.supabase.createClient(
        window.PORTAL_CONFIG.SUPABASE_URL,
        window.PORTAL_CONFIG.SUPABASE_ANON_KEY
    );
}

})();
