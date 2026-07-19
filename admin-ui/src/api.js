import axios from 'axios';

const API_BASE = process.env.REACT_APP_API_BASE_URL || '';

export const api = axios.create({
  baseURL: API_BASE,
});

// Add request interceptor to set Content-Type only for JSON
api.interceptors.request.use((config) => {
  // Only set JSON content-type if body is not FormData
  if (!(config.data instanceof FormData)) {
    config.headers['Content-Type'] = 'application/json';
  }
  return config;
});

export const get = (path) => api.get(path);
export const post = (path, body) => api.post(path, body);
export const put = (path, body) => api.put(path, body);
export const remove = (path) => api.delete(path);
export const API_BASE_URL = API_BASE;
