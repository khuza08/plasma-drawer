# Plasma Drawer: Project Summary

## Project Overview
Plasma Drawer is a fullscreen application launcher for KDE Plasma 6. It mimics the behavior of a mobile app drawer or macOS Launchpad, providing a centralized, customizable space to launch applications and perform system actions.

## Project Structure

- `metadata.json`: Plasmoid metadata, author info, and dependencies.
- `contents/ui/`: Contains all QML UI components.
    - `main.qml`: Entry point, model initialization.
    - `MenuRepresentation.qml`: Top-level dashboard window, search handling.
    - `AppsGridView.qml`: Application browsing with folder support.
    - `ItemGridView.qml`: Custom grid component with spatial navigation.
    - `RunnerResultsView.qml`: KRunner search result display.
- `contents/code/`: JavaScript utilities.
    - `tools.js`: Shared logic for actions and context menus.

## Key Technical Features

### 1. Model-Driven Architecture
The launcher relies heavily on KDE's private `Kicker` models:
- **`Kicker.AppsModel`**: Handles the list of installed applications.
- **`Kicker.RunnerModel`**: Integrates with KRunner for persistent search results.
- **`Kicker.SystemModel`**: Provides system-level actions (logout, shut down, etc.).

### 2. Folder Navigation
Uses a `StackView` inside `AppsGridView.qml` to allow users to drill down into application categories (folders) and navigate back seamlessly.

### 3. Advanced Input Handling
- **Spatial Navigation**: The grid implementation allows for intuitive arrow-key navigation across rows and columns.
- **Instant Search**: Typing any character immediately focuses the search field.

### 4. Customization
Features a dedicated `DrawerTheme.qml` and various configuration options (ConfigGeneral, ConfigSearch) to adjust icon sizes, background styles, and animations.

