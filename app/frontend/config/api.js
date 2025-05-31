import axios from 'axios';

const apiClient = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Функция для получения CSRF токена из мета-тегов Rails
const getCSRFToken = () => {
  const token = document.querySelector('meta[name="csrf-token"]');
  return token ? token.content : '';
};

// Добавление интерсептора для включения CSRF токена в заголовки запросов
apiClient.interceptors.request.use(
  (config) => {
    const csrfToken = getCSRFToken();
    if (csrfToken) {
      config.headers['X-CSRF-Token'] = csrfToken;
    }
    // Добавление JWT токена, если он есть в localStorage
    const jwt = localStorage.getItem('jwt');
    if (jwt) {
      config.headers['Authorization'] = `Bearer ${jwt}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

const api = {
  get: (url, params) => apiClient.get(url, { params }),
  post: (url, data) => apiClient.post(url, data),
  put: (url, data) => apiClient.put(url, data),
  delete: (url) => apiClient.delete(url),
  // Добавьте другие методы при необходимости (patch и т.д.)
};

export default api;
