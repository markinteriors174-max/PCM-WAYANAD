/**
 * PCM WAYANAD - Client Portal: Core DB & Shared State Module
 */
(function (window) {
  'use strict';

  function getSupabase() {
    return window.supabase || window.supabaseClient || (typeof supabase !== 'undefined' ? supabase : null);
  }

  function getSafeString(val, fallback = '') {
    return val != null ? String(val).trim() : fallback;
  }

  function getCleanPhone10(rawPhone) {
    const digits = getSafeString(rawPhone).replace(/\D/g, '');
    return digits.length >= 10 ? digits.slice(-10) : digits;
  }

  window.getSupabase = getSupabase;
  window.getSafeString = getSafeString;
  window.getCleanPhone10 = getCleanPhone10;
})(window);
