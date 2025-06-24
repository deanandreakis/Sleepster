# Code Style and Conventions

## Swift Conventions
- **Architecture**: MVVM pattern with SwiftUI Views and ViewModels
- **Naming**: 
  - PascalCase for types (classes, structs, enums)
  - camelCase for variables, functions, and properties
  - Descriptive names with full words
- **Documentation**: 
  - Header comments with file name, project name, and creation info
  - MARK comments for organizing code sections
  - DocString-style comments for public APIs
- **Code Organization**:
  - Use `// MARK: -` for major sections
  - Group related functionality together
  - Separate dependencies, published properties, private properties, and methods

## File Structure
- **ViewModels/**: ObservableObject classes with @Published properties
- **Views/**: SwiftUI view components
- **Services/**: Business logic and utility classes (singletons common)
- **Models/**: Core Data entities and data models
- **Managers/**: System-level management classes

## Swift Patterns
- `@MainActor` for UI-related classes
- `@Published` properties for observable state
- Dependency injection through ServiceContainer
- Async/await for asynchronous operations
- Combine framework for reactive programming
- Error handling with custom Error types

## Audio Architecture
- Uses "nuclear option" approach for reliable audio stopping
- Immediate UI response, then engine restart for reliability
- Comprehensive error handling with fallback mechanisms