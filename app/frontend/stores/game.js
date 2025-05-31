import { defineStore } from 'pinia';

export const useGameStore = defineStore('game', {
  state: () => ({
    // Здесь будут храниться данные игры, например:
    gameData: null,
    currentPlayerColor: null,
    currentPlayerColorFull: null
  }),
  actions: {
    // Здесь будут методы для обновления состояния игры
    setGameData(data) {
      this.gameData = data;
    },
    setCurrentPlayerColor(color) {
        this.currentPlayerColor = color;
        this.currentPlayerColorFull = color === 'w' ? 'white' : 'black';
    }
  },
  getters: {
    // Здесь будут геттеры, если нужны вычисляемые свойства
  }
});
