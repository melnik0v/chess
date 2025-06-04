<script setup>
import { ref, computed, nextTick, watch } from 'vue';
import { Chess } from 'chess.js';
import api from '@/config/api';
import { useGameStore } from '@/stores/game';

// Import SVG images
import wPSvg from '@/images/wP.svg';
import wNSvg from '@/images/wN.svg';
import wBSvg from '@/images/wB.svg';
import wRSvg from '@/images/wR.svg';
import wQSvg from '@/images/wQ.svg';
import wKSvg from '@/images/wK.svg';
import bPSvg from '@/images/bP.svg';
import bNSvg from '@/images/bN.svg';
import bBSvg from '@/images/bB.svg';
import bRSvg from '@/images/bR.svg';
import bQSvg from '@/images/bQ.svg';
import bK from '@/images/bK.svg';

// Make the game instance reactive
const game = ref(new Chess());
// Удаляем boardState, так как будем использовать game.value.board() напрямую для отображения
// const boardState = ref(JSON.parse(JSON.stringify(game.board())));

const selectedSquare = ref(null); // State for selected square (used for click-to-move)
const possibleMoves = ref([]); // State for possible moves (used for click)
// isFlipped теперь вычисляется на основе currentPlayerColor
// const isFlipped = ref(false);
const showPromotionPopup = ref(false); // State to control promotion popup visibility
const promotionSquare = ref(null); // State to store the square where promotion occurs

// Add a reactive state to force board updates
const gameStateVersion = ref(0);

const pieceImages = {
  wP: wPSvg,
  wN: wNSvg,
  wB: wBSvg,
  wR: wRSvg,
  wQ: wQSvg,
  wK: wKSvg,
  bP: bPSvg,
  bN: bNSvg,
  bB: bBSvg,
  bR: bRSvg,
  bQ: bQSvg,
  bK: bK,
};

const gameStore = useGameStore();

// Вычисляемое свойство для определения ориентации доски
// Используем currentPlayerColor, который теперь безопасно вычисляется
const isFlipped = computed(() => gameStore.currentPlayerColor === 'b');

// Watch for changes in gameStore.gameData.fen and update the chess.js instance
watch(() => gameStore.gameData?.fen, (newFen) => {
  console.log('FEN changed in store:', newFen);
  if (newFen) {
    try {
      game.value.load(newFen);
      console.log('Chess.js board loaded with new FEN:', newFen);
      gameStateVersion.value++; // Принудительное обновление доски

      // Check game-ending conditions and check status after loading new FEN
      if (game.value.isCheckmate()) {
        gameStore.gameStatus = 'checkmate';
        gameStore.winner = game.value.turn() === 'w' ? 'b' : 'w';
        console.log('Checkmate! Winner:', gameStore.winner);
      } else if (game.value.isStalemate()) {
        gameStore.gameStatus = 'stalemate';
        console.log('Stalemate! Draw');
      } else if (game.value.isThreefoldRepetition()) {
        gameStore.gameStatus = 'draw';
        console.log('Draw by threefold repetition');
      } else if (game.value.isInsufficientMaterial()) {
        gameStore.gameStatus = 'draw';
        console.log('Draw by insufficient material');
      } else if (game.value.isDrawByFiftyMoves()) {
        gameStore.gameStatus = 'draw';
        console.log('Draw by 50-move rule');
      } else if (game.value.inCheck()) {
        gameStore.gameStatus = 'check';
        console.log('Check!');
      } else {
        gameStore.gameStatus = 'playing';
        console.log('Game continues');
      }
    } catch (e) {
      console.error('Failed to load FEN or determine game status:', e);
    }
  }
}, { immediate: true });

// Watch for changes in currentPlayerColor and force board re-render
watch(() => gameStore.currentPlayerColor, (newColor) => {
  console.log('currentPlayerColor changed:', newColor);
  gameStateVersion.value++; // Принудительное обновление доски при смене цвета
});

const board = computed(() => {
  // Depend on gameStateVersion to force reactivity
  console.log('Board computed property is updating. Game State Version:', gameStateVersion.value);

  const rows = [];
  // Используем game.value.board() напрямую
  const currentBoard = game.value.board();

  // Visual rows and columns always go from 0 to 7 (top to bottom, left to right)
  for (let i = 0; i < 8; i++) { // Visual row index (0-7 from top to bottom)
    const row = [];
    for (let j = 0; j < 8; j++) { // Visual column index (0-7 from left to right)
      let rankIndexChessJs, fileIndexChessJs;

      // Map visual indices (i, j) to chess.js board indices based on orientation
      if (!isFlipped.value) { // White at bottom: Visual row i corresponds to chess.js rank 8-i (index i), Visual col j corresponds to chess.js file j (index j)
        rankIndexChessJs = i; // chess.js rank index (0-7) for rows 8 down to 1
        fileIndexChessJs = j; // chess.js file index (0-7) for files a to h
      } else { // Black at bottom: Visual row i corresponds to chess.js rank i+1 (index 7-i), Visual col j corresponds to chess.js file h-j (index 7-j)
        rankIndexChessJs = 7 - i; // chess.js rank index (0-7) for rows 1 up to 8
        fileIndexChessJs = 7 - j; // chess.js file index (0-7) for files h down to a
      }

      // Determine the algebraic square name from the chess.js indices
      const squareName = `${String.fromCharCode(97 + fileIndexChessJs)}${8 - rankIndexChessJs}`;

      // Get the piece from the currentBoard state using chess.js indices
      // Check if the rank exists before accessing the file index
      const piece = currentBoard[rankIndexChessJs] ? currentBoard[rankIndexChessJs][fileIndexChessJs] : null;

      row.push({
        square: squareName,
        piece: piece ? { type: piece.type, color: piece.color } : null,
      });
    }
    rows.push(row);
  }
  return rows;
});

const ranks = computed(() => isFlipped.value ? [1, 2, 3, 4, 5, 6, 7, 8] : [8, 7, 6, 5, 4, 3, 2, 1]);
const files = computed(() => isFlipped.value ? ['h', 'g', 'f', 'e', 'd', 'c', 'b', 'a'] : ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']);

// Function to check if a king on a given square is in check
function isKingInCheck(square) {
  // Check if there is a king on the square
  if (!square.piece || square.piece.type !== 'k') {
    return false;
  }
  // Check if the game is currently in a check state and it is this king's turn
  // chess.js's inCheck() checks if the player *whose turn it is* is in check.
  // So, we check if the current turn matches the king's color AND if the game is in check.
  // Используем game.value
  return game.value.inCheck() && square.piece.color === game.value.turn();
}

// Function to handle square click (for selecting pieces)
function onSquareClick(square) {
  // Добавляем проверку: может ли текущий пользователь делать ход?
  // Теперь currentPlayerColor безопасно вычисляется из стора
  if (gameStore.currentPlayerColor !== game.value.turn()) {
    console.log('Не ваш ход или вы не игрок.');
    return; // Выходим, если не ход текущего игрока или пользователь не игрок
  }

  // Prevent moves if the game is over
  // Используем gameStore.gameStatus
  if (gameStore.gameStatus === 'checkmate' || gameStore.gameStatus === 'stalemate' || gameStore.gameStatus === 'draw') {
    return;
  }

  // Проверяем состояние игры через стор
  if (gameStore.gameData?.state !== 'in_progress') return;

  // Если уже выбрана фигура
  if (selectedSquare.value) {
    // Если кликнули по той же клетке, снимаем выделение
    if (selectedSquare.value.square === square.square) {
      selectedSquare.value = null;
      possibleMoves.value = [];
    } else if (square.piece && square.piece.color === gameStore.currentPlayerColor) {
      selectedSquare.value = square;
      possibleMoves.value = game.value.moves({ square: square.square, verbose: true }).map(move => move.to);
      if (gameStore.gameStatus !== 'checkmate' && gameStore.gameStatus !== 'stalemate' && gameStore.gameStatus !== 'draw') {
        gameStore.gameStatus = 'playing';
      }
    } else {
      // Проверка на превращение пешки
      const piece = game.value.get(selectedSquare.value.square);
      const targetRank = square.square[1];
      const isPromotion = piece && piece.type === 'p' && ((piece.color === 'w' && targetRank === '8') || (piece.color === 'b' && targetRank === '1'));

      if (isPromotion) {
        showPromotionPopup.value = true;
        promotionSquare.value = square.square;
      } else {
        // Пытаемся сделать обычный ход
        console.log(`Attempting move from ${selectedSquare.value.square} to ${square.square}`);
        const move = game.value.move({
          from: selectedSquare.value.square,
          to: square.square,
        });

        if (move) {
          console.log('Move made:', move);
          // Обновляем gameData в сторе напрямую после успешного локального хода
          // В дальнейшем, после отправки на бэкенд, стор будет обновлен извне через polling
          gameStore.gameData = { ...gameStore.gameData, fen: game.value.fen() };
          gameStateVersion.value++; // Принудительное обновление доски

          selectedSquare.value = null;
          possibleMoves.value = [];

          // Здесь вызываем action стора для отправки хода на бэкенд
          // Нет необходимости emit'ить move-made
           gameStore.updateGame(gameStore.gameId, game.value.fen());

        } else {
          console.log('Invalid move (click)');
          console.log(`Move from ${selectedSquare.value.square} to ${square.square} is invalid according to chess.js.`);
          selectedSquare.value = null;
          possibleMoves.value = [];
        }
      }
    }
  } else if (square.piece && square.piece.color === gameStore.currentPlayerColor && game.value.turn() === square.piece.color) { // Выбираем фигуру, только если она принадлежит текущему игроку и сейчас его ход
    selectedSquare.value = square;
    possibleMoves.value = game.value.moves({ square: square.square, verbose: true }).map(move => move.to);
     // Обновляем gameStatus в сторе, если он не указывает на завершение игры
    if (gameStore.gameStatus !== 'checkmate' && gameStore.gameStatus !== 'stalemate' && gameStore.gameStatus !== 'draw') {
        gameStore.gameStatus = 'playing';
    }
  } else {
     console.log('Нельзя выбрать фигуру противника или пустую клетку (если фигура не выбрана).');
  }
}

// Удаляем функции, связанные с drag-and-drop
// function onDragStart(event, square) { ... }
// function onDragOver(event) { ... }
// function onDrop(event, toSquare) { ... }
// function onDragEnd(event) { ... }

// Function to reset the game - вызывает action стора
function resetGame() {
  gameStore.resetGame();
  // При сбросе через стор, локальная chess.js игра тоже должна сброситься
  game.value = new Chess();
   selectedSquare.value = null;
   possibleMoves.value = [];
   gameStateVersion.value = 0;
}

// Function to handle promotion piece selection
async function selectPromotionPiece(pieceType) {
  // Construct the move with the selected promotion piece
  const move = game.value.move({
    from: selectedSquare.value.square,
    to: promotionSquare.value,
    promotion: pieceType, // Specify the promotion piece type
  });

  if (move) {
    console.log('Promotion move made:', move);

    // Обновляем gameData в сторе напрямую после успешного локального хода с превращением
    gameStore.gameData = { ...gameStore.gameData, fen: game.value.fen() };

    gameStateVersion.value++; // Принудительное обновление доски

    // Hide the promotion popup and reset states after move
    showPromotionPopup.value = false;
    promotionSquare.value = null;
    selectedSquare.value = null; // Reset selected square after move
    possibleMoves.value = []; // Clear possible moves after move
  } else {
    console.log('Invalid promotion move');
    // Handle unexpected invalid promotion moves if necessary

    // Hide the promotion popup and reset states even on invalid move attempt
    showPromotionPopup.value = false;
    promotionSquare.value = null;
    selectedSquare.value = null; // Reset selected square after move
    possibleMoves.value = []; // Clear possible moves after move
  }

  // Здесь вызываем action стора для отправки хода с превращением на бэкенд
  await gameStore.updateGame(gameStore.gameId, game.value.fen());
}

</script>

<template>
  <div class="chess-container">
    <div :class="['rank-labels', isFlipped ? 'flipped' : '']">
      <div v-for="rank in ranks" :key="rank" class="label">{{ rank }}</div>
    </div>
    <div class="chess-board">
      <div v-for="(row, rowIndex) in board" :key="rowIndex" class="board-row">
        <div
          v-for="(square, colIndex) in row"
          :key="colIndex"
          :class="[
            'square',
            (rowIndex + colIndex) % 2 === 0 ? 'light' : 'dark',
            { 'selected': selectedSquare && selectedSquare.square === square.square },
            { 'possible-move': possibleMoves.includes(square.square) },
          ]"
          :data-square-name="square.square"
          @click="onSquareClick(square)"
        >
          <img
            v-if="square.piece"
            :src="pieceImages[square.piece.color + square.piece.type.toUpperCase()]"
            :alt="`${square.piece.color} ${square.piece.type}`"
            class="piece-image"
          />
          <span v-if="isKingInCheck(square)" class="check-indicator">#</span>
        </div>
      </div>
    </div>
    <div :class="['file-labels', isFlipped ? 'flipped' : '']">
      <div v-for="file in files" :key="file" class="label">{{ file }}</div>
    </div>

    <!-- Статус игры теперь берется из стора -->
    <div v-if="gameStore.gameStatus === 'checkmate' || gameStore.gameStatus === 'stalemate' || gameStore.gameStatus === 'draw'" class="game-over-overlay">
      <div class="game-over-modal">
        <h3 v-if="gameStore.gameStatus === 'checkmate'">Мат! {{ gameStore.winner === 'w' ? 'Белые' : 'Черные' }} выиграли!</h3>
        <h3 v-else-if="gameStore.gameStatus === 'stalemate'">Пат! Ничья.</h3>
        <h3 v-else-if="gameStore.gameStatus === 'draw'">Ничья.</h3>
        <h3 v-else-if="gameStore.gameStatus === 'insufficient'">Недостаточно материала для мата! Ничья.</h3>
        <h3 v-else-if="gameStore.gameStatus === 'threefold'">Троекратное повторение! Ничья.</h3>
        <h3 v-else-if="gameStore.gameStatus === 'fifty-move'">Правило 50 ходов! Ничья.</h3>
        <button @click="resetGame">Сыграть снова</button>
      </div>
    </div>

    <div v-if="showPromotionPopup" class="promotion-overlay">
      <div class="promotion-modal">
        <h4>Выберите фигуру для превращения:</h4>
        <div class="promotion-pieces">
          <img :src="pieceImages[game.turn() + 'Q']" alt="Queen" @click="selectPromotionPiece('q')"/>
          <img :src="pieceImages[game.turn() + 'R']" alt="Rook" @click="selectPromotionPiece('r')"/>
          <img :src="pieceImages[game.turn() + 'B']" alt="Bishop" @click="selectPromotionPiece('b')"/>
          <img :src="pieceImages[game.turn() + 'N']" alt="Knight" @click="selectPromotionPiece('n')"/>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
/* Стили для основного контейнера доски */
.chess-container {
  display: grid;
  grid-template-columns: auto 1fr auto;
  grid-template-rows: 1fr auto;
  gap: 0;
  max-height: calc(100vh - 60px - 100px);
  max-width: calc(100vh - 60px - 100px);
  min-width: 100px;
  min-height: 100px;
  aspect-ratio: 1 / 1;
  box-sizing: border-box;
  width: 100%;
}

/* Стили для меток рангов (цифры) */
.rank-labels {
  grid-column: 1 / 2; /* Размещаем в первой колонке (слева) */
  grid-row: 1 / 2;    /* Размещаем в первой строке (той же, что и доска) */
  display: flex;
  flex-direction: column; /* Цифры должны идти друг под другом */
  justify-content: space-around; /* Распределяем пространство между цифрами */
  height: 100%; /* Занимаем всю доступную высоту в ячейке Grid */
}

.rank-labels.flipped {
  flex-direction: column-reverse; /* Инвертируем порядок для перевернутой доски */
}

/* Стили для самой доски */
.chess-board {
  grid-column: 2 / 3; /* Размещаем во второй колонке (по центру) */
  grid-row: 1 / 2;    /* Размещаем в первой строке (той же, что и метки рангов) */
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  grid-template-rows: repeat(8, 1fr);
  width: 100%; /* Занимаем всю ширину ячейки Grid */
  height: 100%; /* Занимаем всю высоту ячейки Grid */
  border: 1px solid #000;
  box-sizing: border-box;
  user-select: none; /* Предотвращаем выделение текста */
  -webkit-user-select: none; /* Для Webkit-браузеров */
  -ms-user-select: none; /* Для Internet Explorer/Edge */
}

.board-row {
  display: contents;
}

.square {
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer; /* Indicate it's interactive */
  position: relative; /* Добавлено для корректного позиционирования индикатора шаха */
  aspect-ratio: 1 / 1
}

.square.light {
  background-color: #f0d9b5; /* Light squares */
}

.square.dark {
  background-color: #b58863; /* Dark squares */
}

.square.selected {
  filter: grayscale(1); /* Применяем черно-белый фильтр к клетке */
}

.square.possible-move {
  /* Removed background color */
  /* background-color: rgba(0, 255, 0, 0.5); */ /* Highlight possible move squares */
  position: relative; /* Нужен для позиционирования псевдоэлемента */
}

.square.possible-move::before {
  content: ''; /* Псевдоэлемент должен иметь content, даже пустой */
  display: block; /* Псевдоэлемент по умолчанию строчный */
  width: 30%; /* 30% от ширины родителя (.square) */
  height: 30%; /* 30% от высоты родителя (.square) */
  background-color: rgba(0, 128, 0, 0.6); /* Цвет точки с полупрозрачностью */
  border-radius: 50%; /* Делаем круглым */
  position: absolute; /* Позиционируем абсолютно */
  top: 50%; /* Смещаем на 50% вниз */
  left: 50%; /* Смещаем на 50% вправо */
  transform: translate(-50%, -50%); /* Точно центрируем */
  pointer-events: none; /* Игнорируем события мыши на псевдоэлементе */
}

.piece-image {
  width: 80%; /* Adjust size as needed */
  height: 80%; /* Adjust size as needed */
  pointer-events: none; /* Keep pointer-events: none; on the image to allow clicking on squares behind it */
}

.file-labels {
  grid-column: 2 / 3; /* Размещаем во второй колонке (той же, что и доска) */
  grid-row: 2 / 3; /* Размещаем во второй строке (под доской) */
  display: flex;
  justify-content: space-around;
  width: 100%; /* Занимаем всю ширину ячейки Grid */
}

.file-labels.flipped {
  flex-direction: row-reverse; /* Инвертируем порядок для перевернутой доски */
}

.label {
  font-size: 0.8em;
  text-align: center;
}

.check-indicator {
    position: absolute;
    top: 5px;
    right: 5px;
    font-size: 1.5em; /* Сделано чуть больше */
    font-weight: bold;
    color: white; /* Цвет текста белый */
    background-color: black; /* Черный фон */
    border-radius: 50%; /* Круглый фон */
    padding: 4px; /* Изменен отступ для создания круглого фона */
    display: flex; /* Используем flexbox для центрирования */
    justify-content: center; /* Центрирование по горизонтали */
    align-items: center; /* Центрирование по вертикали */
    line-height: 1; /* Убираем лишний межстрочный интервал */
    min-width: 1em; /* Гарантируем минимальную ширину/высоту */
    height: 1em; /* Гарантируем, что высота равна шрифту */
    text-align: center; /* Центрируем текст внутри */
}

/* Styles for the game over popup */
.game-over-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7); /* Semi-transparent black background */
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 100; /* Ensure it's on top of other elements */
}

.game-over-modal {
  background-color: #fff;
  padding: 30px;
  border-radius: 10px;
  text-align: center;
}

.game-over-modal h3 {
  margin-top: 0;
  margin-bottom: 15px;
  font-size: 1.5em;
}

.game-over-modal button {
  padding: 10px 20px;
  font-size: 1em;
  cursor: pointer;
}

/* Styles for the promotion popup */
.promotion-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7); /* Semi-transparent black background */
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 100; /* Ensure it's on top of other elements */
}

.promotion-modal {
  background-color: #fff;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
}

.promotion-pieces {
  display: flex;
  justify-content: center;
  gap: 10px; /* Space between piece images */
}

.promotion-pieces img {
  width: 40px; /* Adjust size as needed */
  height: 40px; /* Adjust size as needed */
  cursor: pointer;
}

/* Styles for the game status display */
.game-status {
    text-align: center;
    margin-top: 10px;
    font-size: 1.2em;
    font-weight: bold;
    color: #333;
}

</style>
