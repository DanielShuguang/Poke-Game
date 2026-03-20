# 斗地主游戏规范（增量）

## 修改需求

### Requirement: Initialize game with AI opponents

The system SHALL initialize a new game session with 2 AI opponents in single-player mode, or with human players in LAN multiplayer mode.

#### Scenario: Start new single-player game

- **WHEN** user starts a new game from homepage in single-player mode
- **THEN** system creates a game session with:
  - 1 human player (user)
  - 2 AI players
  - Standard 54-card deck (including jokers)

#### Scenario: Start new LAN multiplayer game

- **WHEN** user starts a new game in LAN multiplayer mode
- **THEN** system creates a game session with:
  - 3 human players (connected via LAN)
  - No AI players
  - Standard 54-card deck (including jokers)

#### Scenario: Shuffle and deal cards

- **WHEN** game session is created
- **THEN** system shuffles the deck
- **AND** deals 17 cards to each player
- **AND** reserves 3 cards as landlord cards (底牌)

---

### Requirement: Call landlord phase

The system SHALL provide a call landlord (叫地主) phase before gameplay. In LAN mode, the host player must validate and broadcast call decisions.

#### Scenario: Start call landlord phase

- **WHEN** cards are dealt
- **THEN** system prompts the first player to call landlord
- **AND** displays call/pass buttons

#### Scenario: Player calls landlord (Single-player)

- **WHEN** player taps "叫地主" button in single-player mode
- **THEN** system sets the player as landlord
- **AND** gives the 3 reserved cards to the landlord
- **AND** starts the playing phase

#### Scenario: Player calls landlord (LAN multiplayer)

- **WHEN** player taps "叫地主" button in LAN multiplayer mode
- **THEN** client sends call request to host
- **AND** host validates the request
- **AND** host broadcasts landlord assignment to all players
- **AND** gives the 3 reserved cards to the landlord
- **AND** starts the playing phase

#### Scenario: Player passes on calling

- **WHEN** player taps "不叫" button
- **THEN** system moves to next player for call decision

#### Scenario: No one calls landlord (Single-player with human mode disabled)

- **WHEN** all 3 players pass on calling in single-player mode with `GameConfig.isHumanVsAi = false`
- **THEN** system reshuffles and restarts the game

#### Scenario: No one calls landlord (Human vs AI mode)

- **WHEN** all 3 players pass on calling in single-player mode with `GameConfig.isHumanVsAi = true`
- **THEN** the last AI player MUST call landlord

#### Scenario: No one calls landlord (LAN multiplayer mode)

- **WHEN** all 3 players pass on calling in LAN multiplayer mode
- **THEN** system reshuffles and restarts the game

---

### Requirement: Display player hands

The system SHALL display cards in the player's hand with interactive selection. In LAN mode, only the player's own cards must be visible to that player.

#### Scenario: Show human player cards (Single-player)

- **WHEN** single-player game is in progress
- **THEN** system displays user's cards face-up at the bottom
- **AND** cards are sorted by rank and suit

#### Scenario: Show player cards (LAN multiplayer)

- **WHEN** LAN multiplayer game is in progress
- **THEN** system displays current player's own cards face-up
- **AND** hides other players' cards (shows card backs)
- **AND** shows remaining card count for each player

#### Scenario: Show AI player card count

- **WHEN** game is in progress with AI opponents
- **THEN** system displays AI players' card backs
- **AND** shows remaining card count for each AI

#### Scenario: Select cards to play

- **WHEN** user taps on a card in hand
- **THEN** system toggles the card's selected state
- **AND** raises selected cards visually

---

### Requirement: Play cards in turn

The system SHALL enforce turn-based gameplay. In LAN mode, the host must validate and broadcast all play actions.

#### Scenario: Human player turn (Single-player)

- **WHEN** it's the human player's turn in single-player mode
- **THEN** system enables play and pass buttons
- **AND** highlights the player's area

#### Scenario: Human player turn (LAN multiplayer)

- **WHEN** it's a player's turn in LAN multiplayer mode
- **THEN** client enables play and pass buttons
- **AND** highlights the player's area
- **AND** other players see "waiting for Player X" indicator

#### Scenario: AI player turn

- **WHEN** it's an AI player's turn
- **THEN** system disables all controls
- **AND** AI plays after a short delay (1-2 seconds)

#### Scenario: Pass turn (Single-player)

- **WHEN** player taps "不出" button and previous play exists in single-player mode
- **THEN** system skips the player's turn
- **AND** moves to next player

#### Scenario: Pass turn (LAN multiplayer)

- **WHEN** player taps "不出" button and previous play exists in LAN multiplayer mode
- **THEN** client sends pass request to host
- **AND** host validates and broadcasts the pass action
- **AND** system moves to next player

#### Scenario: Must play when starting

- **WHEN** no previous play exists (new round)
- **THEN** system does NOT allow passing
- **AND** player must play cards

---

### Requirement: AI opponent behavior

The system SHALL provide intelligent AI opponents in single-player mode. In LAN multiplayer mode, AI opponents MUST be disabled.

#### Scenario: AI plays valid cards

- **WHEN** it's AI's turn to play in single-player mode
- **THEN** AI analyzes the game state
- **AND** plays a valid card combination or passes

#### Scenario: AI calls landlord decision

- **WHEN** AI is prompted to call landlord in single-player mode
- **THEN** AI evaluates hand strength
- **AND** decides to call or pass based on strategy

#### Scenario: No AI in LAN mode

- **WHEN** game is initialized in LAN multiplayer mode
- **THEN** system MUST NOT create AI players
- **AND** all players MUST be human players connected via network

---

## ADDED Requirements

### Requirement: Support Player Interface abstraction

The system MUST abstract all players (AI and human) behind a common Player Interface to support both single-player and multiplayer modes.

#### Scenario: Player Interface implementation

- **WHEN** game session is initialized
- **THEN** system creates player instances implementing Player Interface
- **AND** AIPlayer implements Player Interface for single-player mode
- **AND** RemotePlayer implements Player Interface for LAN multiplayer mode

#### Scenario: Uniform player interaction

- **WHEN** game logic interacts with any player
- **THEN** system uses Player Interface methods
- **AND** game logic MUST NOT differentiate between AI and remote players

---

### Requirement: Support game state serialization

The system MUST serialize and deserialize game state for network transmission in LAN multiplayer mode.

#### Scenario: Serialize game state

- **WHEN** game state changes in LAN multiplayer mode
- **THEN** system serializes state to JSON format
- **AND** includes: current player, played cards, remaining cards, landlord

#### Scenario: Deserialize game state

- **WHEN** client receives serialized game state
- **THEN** system deserializes JSON to game state objects
- **AND** updates local game view accordingly

---

### Requirement: Support disconnection handling in LAN mode

The system MUST handle player disconnections gracefully in LAN multiplayer mode.

#### Scenario: Player disconnects during game

- **WHEN** a player loses connection during LAN game
- **THEN** host detects disconnection via heartbeat timeout
- **AND** system pauses game
- **AND** gives disconnected player 60 seconds to reconnect

#### Scenario: Player reconnects

- **WHEN** disconnected player reconnects within 60 seconds
- **THEN** host sends current game state
- **AND** player resumes playing

#### Scenario: Player fails to reconnect

- **WHEN** disconnected player fails to reconnect within 60 seconds
- **THEN** system declares disconnected player as loser
- **AND** ends the game
- **AND** notifies remaining players
