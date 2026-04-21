# 🐉 Snake Dragon Game (龍之森林)

A Flutter web game where your snake evolves into a dragon!

## Play Online
**https://yangpeng9572-commits.github.io/snake-dragon-game/**

## Auto-Deploy Setup
This repo uses GitHub Actions for automatic deployment:
- Push to `main` branch triggers Flutter web build
- Built files are deployed to `gh-pages` branch
- Game is served at: https://yangpeng9572-commits.github.io/snake-dragon-game/

## Development
```bash
flutter pub get
flutter run -d chrome
```

## Build
```bash
flutter build web --base-href /snake-dragon-game/
```
