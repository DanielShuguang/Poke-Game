# Spec: Doudizhu Game

斗地主游戏能力规范，定义游戏核心功能需求。

## ADDED Requirements

### Requirement: Initialize game with AI opponents

The system SHALL initialize a new game session with 2 AI opponents.

#### Scenario: Start new game

- **WHEN** user starts a new game from homepage
- **THEN** system creates a game session with:
  - 1 human player (user)
  - 2 AI players
  - Standard 54-card deck (including jokers)

#### Scenario: Shuffle and deal cards

- **WHEN** game session is created
- **THEN** system shuffles the deck
- **AND** deals 17 cards to each player
- **AND** reserves 3 cards as landlord cards (底牌)

---

### Requirement: Call landlord phase

The system SHALL provide a call landlord (叫地主) phase before gameplay.

#### Scenario: Start call landlord phase

- **WHEN** cards are dealt
- **THEN** system prompts the first player to call landlord
- **AND** displays call/pass buttons

#### Scenario: Player calls landlord

- **WHEN** player taps "叫地主" button
- **THEN** system sets the player as landlord
- **AND** gives the 3 reserved cards to the landlord
- **AND** starts the playing phase

#### Scenario: Player passes on calling

- **WHEN** player taps "不叫" button
- **THEN** system moves to next player for call decision

#### Scenario: No one calls landlord

- **WHEN** all 3 players pass on calling
- **THEN** system reshuffles and restarts the game

---

### Requirement: Display player hands

The system SHALL display cards in the player's hand with interactive selection.

#### Scenario: Show human player cards

- **WHEN** game is in progress
- **THEN** system displays user's cards face-up at the bottom
- **AND** cards are sorted by rank and suit

#### Scenario: Show AI player card count

- **WHEN** game is in progress
- **THEN** system displays AI players' card backs
- **AND** shows remaining card count for each AI

#### Scenario: Select cards to play

- **WHEN** user taps on a card in hand
- **THEN** system toggles the card's selected state
- **AND** raises selected cards visually

---

### Requirement: Validate card combinations

The system SHALL validate played card combinations according to Doudizhu rules.

#### Scenario: Valid single card

- **WHEN** user selects one card and plays
- **THEN** system accepts the play if it beats the previous play

#### Scenario: Valid pair

- **WHEN** user selects two cards of the same rank and plays
- **THEN** system accepts the play as a pair

#### Scenario: Valid triple

- **WHEN** user selects three cards of the same rank and plays
- **THEN** system accepts the play as a triple

#### Scenario: Valid triple with single

- **WHEN** user selects three cards of same rank plus one single card and plays
- **THEN** system accepts the play as "三带一"

#### Scenario: Valid triple with pair

- **WHEN** user selects three cards of same rank plus one pair and plays
- **THEN** system accepts the play as "三带二"

#### Scenario: Valid straight

- **WHEN** user selects 5+ consecutive cards (min rank 3) and plays
- **THEN** system accepts the play as a straight (顺子)

#### Scenario: Valid bomb

- **WHEN** user selects four cards of the same rank and plays
- **THEN** system accepts the play as a bomb (炸弹)
- **AND** bomb beats any non-bomb combination

#### Scenario: Valid rocket

- **WHEN** user selects both jokers and plays
- **THEN** system accepts the play as a rocket (王炸)
- **AND** rocket beats any other combination

#### Scenario: Invalid combination

- **WHEN** user plays an invalid card combination
- **THEN** system rejects the play
- **AND** displays an error message

---

### Requirement: Play cards in turn

The system SHALL enforce turn-based gameplay.

#### Scenario: Human player turn

- **WHEN** it's the human player's turn
- **THEN** system enables play and pass buttons
- **AND** highlights the player's area

#### Scenario: AI player turn

- **WHEN** it's an AI player's turn
- **THEN** system disables all controls
- **AND** AI plays after a short delay (1-2 seconds)

#### Scenario: Pass turn

- **WHEN** player taps "不出" button and previous play exists
- **THEN** system skips the player's turn
- **AND** moves to next player

#### Scenario: Must play when starting

- **WHEN** no previous play exists (new round)
- **THEN** system does NOT allow passing
- **AND** player must play cards

---

### Requirement: AI opponent behavior

The system SHALL provide intelligent AI opponents.

#### Scenario: AI plays valid cards

- **WHEN** it's AI's turn to play
- **THEN** AI analyzes the game state
- **AND** plays a valid card combination or passes

#### Scenario: AI calls landlord decision

- **WHEN** AI is prompted to call landlord
- **THEN** AI evaluates hand strength
- **AND** decides to call or pass based on strategy

---

### Requirement: Determine winner

The system SHALL determine the winner when a player runs out of cards.

#### Scenario: Landlord wins

- **WHEN** landlord plays all cards first
- **THEN** system declares landlord as winner
- **AND** displays victory animation

#### Scenario: Peasants win

- **WHEN** any peasant plays all cards first
- **THEN** system declares both peasants as winners
- **AND** displays victory animation

#### Scenario: Human player loses

- **WHEN** AI plays all cards first and human is on the losing side
- **THEN** system displays defeat screen
- **AND** shows play again option

---

### Requirement: End game options

The system SHALL provide options after game ends.

#### Scenario: Play again

- **WHEN** game ends and user taps "再来一局"
- **THEN** system starts a new game session

#### Scenario: Return to homepage

- **WHEN** game ends and user taps "返回首页"
- **THEN** system navigates back to homepage

---

### Requirement: Display game info

The system SHALL display relevant game information during play.

#### Scenario: Show current turn indicator

- **WHEN** game is in progress
- **THEN** system highlights the current player's position

#### Scenario: Show landlord indicator

- **WHEN** landlord is determined
- **THEN** system displays "地主" badge on landlord's avatar

#### Scenario: Show played cards

- **WHEN** any player plays cards
- **THEN** system displays the played cards in the center area
- **AND** shows which player played them

---

### Requirement: Support game mode extensibility

The system SHALL support future extension to LAN multiplayer mode.

#### Scenario: Game mode abstraction

- **WHEN** game session is initialized
- **THEN** system uses Player interface for all players
- **AND** AI player and future NetworkPlayer implement same interface

#### Scenario: Event-driven architecture

- **WHEN** any game action occurs (deal, call, play)
- **THEN** system emits corresponding GameEvent
- **AND** event processor handles the event uniformly
