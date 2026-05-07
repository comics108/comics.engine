# Implementation Plan: C# Unity + Web CSS Render Engines

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-05-08
> Specifications: `specifications.md`

## Summary

Два независимых рендер-движка реализуются параллельно:
- **Unity/C#**: Unity Package в `unity-comics-viewer/`
- **Web/JS+CSS**: Standalone библиотека в `web-comics-viewer/`

Оба используют одинаковые .comics архивы и алгоритмы анимации.

---

## Task Breakdown

### Phase 1: Project Setup

#### Task 1.1: Create Unity Package Structure
- **Description**: Инициализация Unity Package с правильной структурой
- **Files**:
  - `unity-comics-viewer/package.json` - Create
  - `unity-comics-viewer/Runtime/` - Create directory
  - `unity-comics-viewer/Editor/` - Create directory
  - `unity-comics-viewer/Samples~/` - Create directory
- **Dependencies**: None
- **Verification**: Package импортируется в Unity без ошибок
- **Complexity**: Low

#### Task 1.2: Create Web Project Structure
- **Description**: Инициализация web-проекта
- **Files**:
  - `web-comics-viewer/src/comics-engine.js` - Create
  - `web-comics-viewer/src/comics-viewer.css` - Create
  - `web-comics-viewer/index.html` - Create (demo)
  - `web-comics-viewer/package.json` - Create (optional npm)
- **Dependencies**: None
- **Verification**: index.html открывается в браузере
- **Complexity**: Low

#### Task 1.3: Copy Sample .comics Archive
- **Description**: Подготовить тестовый архив для обоих проектов
- **Files**:
  - `samples/test-comics.comics` - Copy from existing
- **Dependencies**: None
- **Verification**: Архив содержит data.json, layers/, sounds/
- **Complexity**: Low

---

### Phase 2: Data Models

#### Task 2.1: Unity Data Models
- **Description**: C# классы для JSON десериализации
- **Files**:
  - `unity-comics-viewer/Runtime/Models/Comics.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Layer.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Image.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Sound.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Animations/Anim.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Animations/TranslateAnim.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Animations/RotateAnim.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Animations/ScaleAnim.cs` - Create
  - `unity-comics-viewer/Runtime/Models/Animations/AlphaAnim.cs` - Create
- **Dependencies**: Task 1.1
- **Verification**: JSON парсится корректно в Unity
- **Complexity**: Medium

#### Task 2.2: Web Data Parsing
- **Description**: JS парсинг и подготовка анимаций
- **Files**:
  - `web-comics-viewer/src/models.js` - Create
- **Dependencies**: Task 1.2
- **Verification**: console.log показывает parsed data
- **Complexity**: Low

---

### Phase 3: Animation System

#### Task 3.1: Unity Animation Logic
- **Description**: Интерполяция и применение трансформаций
- **Files**:
  - `unity-comics-viewer/Runtime/Core/AnimationProcessor.cs` - Create
- **Dependencies**: Task 2.1
- **Verification**: Unit test: cubic easing, matrix composition
- **Complexity**: Medium

#### Task 3.2: Web Animation Logic
- **Description**: JS интерполяция с cubic easing
- **Files**:
  - `web-comics-viewer/src/animation.js` - Create
- **Dependencies**: Task 2.2
- **Verification**: console.log показывает interpolated values
- **Complexity**: Medium

---

### Phase 4: Tile Rendering

#### Task 4.1: Unity Tile System
- **Description**: Загрузка тайлов из ZIP, viewport culling
- **Files**:
  - `unity-comics-viewer/Runtime/Rendering/TileRenderer.cs` - Create
  - `unity-comics-viewer/Runtime/Rendering/TileCache.cs` - Create
  - `unity-comics-viewer/Runtime/IO/ZipArchiveProvider.cs` - Create
- **Dependencies**: Task 3.1
- **Verification**: Тайлы появляются при скролле
- **Complexity**: High

#### Task 4.2: Web Tile System
- **Description**: Lazy loading тайлов с IntersectionObserver
- **Files**:
  - `web-comics-viewer/src/tile-loader.js` - Create
- **Dependencies**: Task 3.2
- **Verification**: Network tab показывает lazy loading
- **Complexity**: Medium

---

### Phase 5: Main Components

#### Task 5.1: Unity ComicsViewer MonoBehaviour
- **Description**: Главный компонент для Unity
- **Files**:
  - `unity-comics-viewer/Runtime/ComicsViewer.cs` - Create
  - `unity-comics-viewer/Runtime/ComicsScrollHandler.cs` - Create
- **Dependencies**: Task 4.1
- **Verification**: Демо сцена работает
- **Complexity**: Medium

#### Task 5.2: Web ComicsViewer Class
- **Description**: Главный JS класс
- **Files**:
  - `web-comics-viewer/src/comics-viewer.js` - Create (main entry)
- **Dependencies**: Task 4.2
- **Verification**: index.html отображает комикс
- **Complexity**: Medium

---

### Phase 6: Sound System

#### Task 6.1: Unity Sound Triggers
- **Description**: Воспроизведение звуков по scroll offset
- **Files**:
  - `unity-comics-viewer/Runtime/Audio/SoundManager.cs` - Create
- **Dependencies**: Task 5.1
- **Verification**: Звуки играют при скролле
- **Complexity**: Medium

#### Task 6.2: Web Sound Triggers
- **Description**: Web Audio API для звуков
- **Files**:
  - `web-comics-viewer/src/sound-manager.js` - Create
- **Dependencies**: Task 5.2
- **Verification**: Звуки играют в браузере
- **Complexity**: Medium

---

### Phase 7: Polish & Samples

#### Task 7.1: Unity Sample Scene
- **Description**: Демонстрационная сцена
- **Files**:
  - `unity-comics-viewer/Samples~/BasicViewer/BasicViewer.unity` - Create
  - `unity-comics-viewer/Samples~/BasicViewer/Scripts/DemoController.cs` - Create
- **Dependencies**: Task 6.1
- **Verification**: Sample работает из Package Manager
- **Complexity**: Low

#### Task 7.2: Web Demo Page
- **Description**: Полная демо страница с UI
- **Files**:
  - `web-comics-viewer/index.html` - Modify
  - `web-comics-viewer/demo.css` - Create
- **Dependencies**: Task 6.2
- **Verification**: Демо работает в браузере
- **Complexity**: Low

#### Task 7.3: Web Offline Support
- **Description**: Service Worker для offline
- **Files**:
  - `web-comics-viewer/sw.js` - Create
- **Dependencies**: Task 7.2
- **Verification**: Работает без сети (после первой загрузки)
- **Complexity**: Low

---

## Dependency Graph

```
Phase 1 (Setup)
  1.1 Unity ──┐
  1.2 Web ────┤
  1.3 Sample ─┘
       │
       ▼
Phase 2 (Models)
  2.1 Unity ──→ 3.1 Animation ──→ 4.1 Tiles ──→ 5.1 Viewer ──→ 6.1 Sound ──→ 7.1 Sample
  2.2 Web ────→ 3.2 Animation ──→ 4.2 Tiles ──→ 5.2 Viewer ──→ 6.2 Sound ──→ 7.2 Demo
                                                                              ↓
                                                                           7.3 Offline
```

**Unity и Web можно разрабатывать параллельно!**

---

## File Change Summary

### Unity Package (`unity-comics-viewer/`)

| File | Action | Lines (est.) |
|------|--------|--------------|
| `Runtime/Models/*.cs` | Create | ~300 |
| `Runtime/Core/AnimationProcessor.cs` | Create | ~150 |
| `Runtime/Rendering/TileRenderer.cs` | Create | ~200 |
| `Runtime/Rendering/TileCache.cs` | Create | ~80 |
| `Runtime/IO/ZipArchiveProvider.cs` | Create | ~60 |
| `Runtime/ComicsViewer.cs` | Create | ~150 |
| `Runtime/ComicsScrollHandler.cs` | Create | ~80 |
| `Runtime/Audio/SoundManager.cs` | Create | ~100 |
| `Samples~/BasicViewer/*` | Create | ~100 |
| **Total** | | **~1220** |

### Web Library (`web-comics-viewer/`)

| File | Action | Lines (est.) |
|------|--------|--------------|
| `src/comics-engine.js` | Create | ~400 |
| `src/comics-viewer.css` | Create | ~50 |
| `src/sound-manager.js` | Create | ~80 |
| `index.html` | Create | ~50 |
| `sw.js` | Create | ~30 |
| **Total** | | **~610** |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Unity ZIP library issues | Low | Medium | Use System.IO.Compression (built-in) |
| Web memory on large comics | Medium | High | Aggressive tile unloading, LRU cache |
| Animation visual mismatch | Medium | High | Golden tests comparing renders |
| Browser compatibility | Low | Medium | Test on Chrome, Firefox, Safari |

---

## Rollback Strategy

1. Оба проекта в отдельных директориях — просто удалить
2. Git branch для каждого: `feature/unity-viewer`, `feature/web-viewer`
3. Нет изменений в существующем коде flutter_comics

---

## Checkpoints

### After Phase 2:
- [ ] data.json парсится в обоих движках
- [ ] Структуры данных идентичны

### After Phase 4:
- [ ] Тайлы отображаются корректно
- [ ] Lazy loading работает

### After Phase 6:
- [ ] Scroll-driven анимации работают
- [ ] Звуки проигрываются

### After Phase 7:
- [ ] Visual comparison: Unity vs Web vs Native Flutter
- [ ] Performance: 60 FPS scroll

---

## Open Implementation Questions

- [x] Unity ZIP: System.IO.Compression (built-in .NET)
- [x] Web ZIP: fflate (~8KB gzip, самый быстрый)
- [ ] Unity: Какой JSON парсер? (Unity JsonUtility vs Newtonsoft)
- [ ] Публикация: OpenUPM, npm, или просто GitHub releases?

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [any conditions or clarifications]
