# Go Fish — Liberty BASIC Edition

A playable version of **Go Fish** implemented in Liberty BASIC, featuring a graphical interface, a state-machine game engine, and an AI opponent with simple memory-based strategies.

---

## 🎲 Game Rules (Short Version)

- Players take turns asking an opponent for a specific card rank they hold in their hand.
- If the opponent has cards of that rank, they must surrender them. The asking player goes again.
- If not, the player must “Go Fish” and draw from the deck.
- If the drawn card matches the rank they just asked for, they go again.
- Players lay down **books** (sets of 4 cards of the same rank) as they collect them.
- The first player to complete **7 books** wins (house rule in this implementation).
- When a player runs out of cards, they draw up to 5 new cards if the deck allows.

This implementation follows official Go Fish rules with some house modifications for gameplay flow.

---

## 🖥 How It Works

- Written entirely in **Liberty BASIC**.
- Uses a **state machine** architecture:
  - Each game phase (player turn, AI turn, message boxes, etc.) is a distinct state.
  - State transitions are driven by actions queued in a message system.
- Graphical display includes:
  - Visual hand of cards for the player.
  - Deck and counters for books and cards remaining.
  - Simple message box system for game events.
  - Debug mode displays all cards held by the computer and deck contents for testing.

The AI uses basic memory:
- Remembers ranks the player previously asked for.
- Prefers to ask for ranks it holds multiple cards of.
- Tries not to repeat failed requests unnecessarily.
- Favors ranks it recently fished from the deck.

---

## 📦 Requirements

- **Liberty BASIC v4.5 or newer.**
- No external libraries required.
- Game currently depends on embedded graphics code for drawing cards, but no external images are used yet.

> **Note:** You may optionally add custom card graphics. This would involve loading image files and adjusting the drawing code.

**Liberty BASIC GoFish** will run in Just BASIC with a small modification.  There is a DLL call to remove the scrollbars on the graphics window at line 698.  Comment out the DLL call to run in Just BASIC.

---

## 🖼️ Screenshot

<img width="705" height="492" alt="gofish" src="https://github.com/user-attachments/assets/cb0d7ec8-a392-417c-99ba-beff5b30a834" />

---

## 🚀 Future Improvements

Here are some enhancements that could take this project to the next level:

- **Custom Card Art:**
  - Replace basic card boxes with graphic images for suits and ranks.
- **Sound Effects:**
  - Add audio feedback for dealing cards, making books, and game results.
- **Statistics Tracking:**
  - Win/loss counts, longest game streaks, AI performance metrics.
- **More Sophisticated AI:**
  - Better memory management.
  - Probability-based inference of player hand.
- **Multiplayer Support:**
  - Local two-player mode.
- **Difficulty Levels:**
  - “Easy” or “Hard” AI settings.
- **Animations:**
  - Animate card movements or books being laid down.

---

## 📝 License

This game is provided as open source. Feel free to fork, modify, or contribute improvements.

Happy Fishing!

