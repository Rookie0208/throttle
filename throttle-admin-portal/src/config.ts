const fallbackApiBaseUrl = 'http://localhost:8080/api/v1';

export const API_BASE_URL =
  (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim() ||
  fallbackApiBaseUrl;

export const MANAGEMENT_BASE_URL =
  (import.meta.env.VITE_MANAGEMENT_BASE_URL as string | undefined)?.trim() ||
  API_BASE_URL.replace(/\/api\/v1\/?$/, '');
