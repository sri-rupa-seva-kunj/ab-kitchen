// ==================== CONFIG.JS ====================
// Централизованная конфигурация Supabase
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

window.CONFIG = {
    ...env,
    ENV: isDev ? 'development' : 'production',
    IS_DEV: isDev,
    // Service role никогда не передаётся в браузер.
    SUPABASE_SERVICE_ROLE_KEY: null
};

// NB: debug() определён в utils.js, который грузится ПОСЛЕ config.js.
// На этом этапе его ещё нет — используем console.log напрямую.
// [ENV] лог всегда виден в консоли — намеренно, помогает диагностировать окружение.
console.log('[ENV]', window.CONFIG.ENV + ':', location.hostname || 'file://', '→', window.CONFIG.SUPABASE_URL);


// Создаём ЕДИНСТВЕННЫЙ экземпляр Supabase клиента
// Все модули должны использовать window.supabaseClient вместо создания нового
if (typeof window.supabase !== 'undefined') {
    window.supabaseClient = window.supabase.createClient(
        window.CONFIG.SUPABASE_URL,
        window.CONFIG.SUPABASE_ANON_KEY
    );
}

})();
