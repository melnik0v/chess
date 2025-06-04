import { defineStore } from 'pinia';
import FingerprintJS from '@fingerprintjs/fingerprintjs';

export const useDeviceStore = defineStore('device', {
  state: () => ({
    fingerprint: null,
  }),
  getters: {
    getFingerprint: (state) => state.fingerprint,
  },
  actions: {
    async loadFingerprint() {
      if (this.fingerprint) {
        return this.fingerprint; // Уже загружен
      }
      try {
        const fp = await FingerprintJS.load();
        const result = await fp.get();
        this.fingerprint = result.visitorId;
        console.log('Device fingerprint loaded:', this.fingerprint); // Для отладки
        return this.fingerprint;
      } catch (error) {
        console.error('Error loading device fingerprint:', error);
        this.fingerprint = 'unknown'; // Устанавливаем значение по умолчанию в случае ошибки
        return 'unknown';
      }
    },
  },
});
