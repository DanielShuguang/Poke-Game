# Spec: Game Homepage

游戏首页能力规范，定义应用主入口的功能需求。

## ADDED Requirements

### Requirement: Display game list

The system SHALL display a list of available games on the homepage.

#### Scenario: Display games with different statuses

- **WHEN** user opens the application
- **THEN** system displays game cards showing:
  - Game name
  - Game icon
  - Status badge (available / coming soon / planned)
  - Play button for available games

---

### Requirement: Navigate to game page

The system SHALL allow users to navigate to a specific game page from the homepage.

#### Scenario: Navigate to available game

- **WHEN** user taps on a game card with status "available"
- **THEN** system navigates to the corresponding game page

#### Scenario: Handle unavailable game tap

- **WHEN** user taps on a game card with status "coming soon" or "planned"
- **THEN** system displays a snackbar message indicating the game is not yet available

---

### Requirement: Display game categories

The system SHALL organize games by categories for easy navigation.

#### Scenario: Display categorized games

- **WHEN** user views the homepage
- **THEN** system displays games grouped by category:
  - Card Games (扑克牌类)
  - Board Games (棋类)
  - Other Games (其他)

---

### Requirement: Support pull-to-refresh

The system SHALL support pull-to-refresh gesture to reload game list.

#### Scenario: Refresh game list

- **WHEN** user pulls down on the game list
- **THEN** system shows refresh indicator
- **AND** system reloads the game list

---

### Requirement: Display app title and branding

The system SHALL display the app title and branding elements on the homepage.

#### Scenario: Display header

- **WHEN** user views the homepage
- **THEN** system displays:
  - App title "扑克游戏合集"
  - App logo
  - Settings button (optional)
