# 🚀 flutter_project_booster

A CLI tool to quickly bootstrap your Flutter project's structure, clean up your `pubspec.yaml`, and remove unused dependencies.

Keep your Flutter project lean, organized, and efficient — all from the terminal.

---

## ✨ Features

- 🛠 Create standard folder and file structure from a JSON config.
- 📦 Automatically update and clean `pubspec.yaml`.
- 🧼 Remove unused dependencies from `pubspec.yaml`.
- 💡 Built-in support for dependencies, dev_dependencies, and assets.

---

## 📦 Installation

- Clone the repository and get dependencies:

```bash
git clone https://github.com/3boodev/flutter_project_booster
cd flutter_project_booster
dart pub get
```

## - OR ADD TO dev_dependencies in pubspec.yaml
```bash
  dev_dependencies:
   flutter_project_booster:
    git:
     url: https://github.com/3boodev/flutter_project_booster
```
## - OR USE It as Globally
```bash
  dart pub global activate flutter_project_booster
```
## 🛠 Usage (with out 'dart run' If your Use Globally)

1. Create project structure

```bash
    dart run flutter_project_booster --create
```
This will:

- Create folders and files as defined in assets/project_components.json.
- Clean your pubspec.yaml (remove comments & empty lines).
- Add missing dependencies, dev_dependencies, and assets.

2. Remove unused dependencies

```bash
   dart run flutter_project_booster --remove
```
This will:

- Scan your Dart files.
- Detect dependencies listed in pubspec.yaml but not actually used.
- Remove them automatically.

## 🧾 CLI Options

Option | Description
--create | Generate folder structure & update pubspec.yaml
--remove | Remove unused dependencies
--help | Show help info

## 📁 JSON Config Format

```bash
  {
  "directories": ["lib/screens", "lib/widgets", "lib/services"],
  "files": ["lib/main.dart", "lib/widgets/app_button.dart"],
  "dependencies": ["http", "provider"],
  "dev_dependencies": ["flutter_lints"],
  "assets": ["assets/images/", "assets/icons/"]
}
```
## ✅ Example Output

```bash
    📁 Created directory: lib/screens
    📄 Created file: lib/main.dart
    ✅ Updated pubspec.yaml successfully.
    🚀 Dependencies installed.
```

- For unused dependency removal:

```bash
    Scanning for unused dependencies...
    Removed: fluttertoast
    Removed: shared_preferences
    ✅ pubspec.yaml cleaned successfully.
```

## 📌 Roadmap

- Support for customizable file templates.
- Backup mode for pubspec.yaml before edit.
- Lint integration for consistency checks.

## 👨‍💻 Author

- Built with ❤️ by <a href="https://github.com/3boodev">Abdullah Alamary</a>

## 📝 License

- This project is licensed under the MIT License. See the LICENSE file for details.

