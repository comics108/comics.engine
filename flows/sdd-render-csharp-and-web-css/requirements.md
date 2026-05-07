# Requirements: C# Unity + Web CSS Render Engines

> Version: 1.0
> Status: APPROVED
> Last Updated: 2026-05-08
> Base specs: `../sdd-render-engine-native/03-specifications-ru.md`

## Problem Statement

Текущий рендер-движок flutter_comics работает только на Android/iOS через Flutter. Для расширения охвата аудитории требуется:

1. **Unity-версия (C#)** — для игровых приложений на PC, Mac, консолях, VR/AR устройствах
2. **Web-версия (HTML/CSS)** — для браузерного просмотра без установки приложений

Обе версии должны корректно отображать существующие .comics архивы с тем же визуальным результатом.

## User Stories

### Unity/C#

**As a** Unity game developer
**I want** встроить комикс-контент в своё приложение
**So that** пользователи могут просматривать интерактивные комиксы внутри игры/приложения

### Web/HTML/CSS

**As a** web visitor
**I want** просматривать комиксы в браузере без скачивания приложения
**So that** получить мгновенный доступ к контенту на любом устройстве

### Content Creator

**As a** создатель контента
**I want** один формат архива (.comics) работающий везде
**So that** не нужно готовить разные версии контента для разных платформ

## Acceptance Criteria

### Must Have

1. **Given** .comics архив с тайловыми слоями
   **When** загружен в Unity/Web рендер
   **Then** отображается идентично Android/iOS версии

2. **Given** scroll-driven анимации в data.json
   **When** пользователь скроллит контент
   **Then** анимации применяются с cubic easing `(f-1)³+1`

3. **Given** многоязычный контент (images[] массив)
   **When** выбран конкретный язык
   **Then** отображаются соответствующие изображения с fallback

4. **Given** звуковые триггеры в data.json
   **When** скролл достигает указанного offset
   **Then** звук воспроизводится (point) или зацикливается (range)

### Should Have

- Hit-testing по альфа-каналу для интерактивности
- Zoom/pan поддержка (опционально)
- Responsive layout для разных размеров экрана
- **Web: Offline режим** через Service Worker + IndexedDB (опция)

### Won't Have (v1.0) — запланировано на v2.0

- Конвертация .comics в другие форматы
- Редактор контента
- Мультиплеер/синхронизация между устройствами
- Unity VR/XR режим
- Web постраничный режим (pagination)

---

## Режим скролла (Web v1.0)

**Бесконечный скролл** — основной режим, как в Facebook/Instagram feed:
- Пользователь контролирует скорость скролла
- Анимации слоёв привязаны к scroll offset
- Lazy-loading тайлов по мере скролла
- Touch и mouse wheel поддержка

```
┌─────────────────────┐
│  ↑ scroll up        │
├─────────────────────┤
│                     │
│   [Контент]         │  ← бесконечная лента
│                     │
├─────────────────────┤
│  ↓ scroll down      │
└─────────────────────┘
```

## Постраничный режим (v2.0 future)

Опциональный режим для "книжного" UX — запланирован на будущее.

## Constraints

### Unity/C#
- **Версия Unity**: 2021.3+ LTS или новее
- **Render Pipeline**: URP/HDRP/Built-in — универсальная поддержка
- **Платформы**: Windows, macOS, Linux, iOS, Android, WebGL, консоли
- **Память**: Viewport-aware загрузка тайлов (как в нативной версии)

### Web/HTML/CSS + minimal JS
- **Браузеры**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Mobile**: iOS Safari, Chrome Mobile
- **Архитектура**: CSS transforms + vanilla JS (~15-20KB gzipped)
- **Режим скролла**: Бесконечный скролл (как Facebook feed), контролируемый пользователем
- **Производительность**: 60 FPS скролл на mid-range устройствах
- **Без фреймворков**: Нет React/Vue/Angular зависимостей

### Общие
- **Tile size**: 512x512 px (неизменяемо)
- **Tile naming**: `{0}_{1}_{2}` формат (zoom*1000, col, row)
- **Animation order**: Scale → Rotate → Translate
- **Archive format**: ZIP с data.json + layers/ + sounds/

## Decisions (Resolved Questions)

- [x] **Unity: Canvas UI vs camera-based** → **WorldSpace rendering** (камера + 3D плоскости) — готовность к VR в будущем
- [x] **Unity: VR/XR поддержка** → Не в v1.0, запланировано как v2.0 feature
- [x] **Web: Offline Service Worker** → Да, как опциональная функция
- [x] **Web: Режим скролла** → Бесконечный скролл (как Facebook), постраничный режим как v2.0 опция
- [x] **ZIP распаковка** → Unity: при первом запуске; Web: на лету с lazy loading + IndexedDB кэш

## Open Questions

- [x] ~~Web: Жесты для листания~~ → v2.0, основной режим — бесконечный скролл
- [ ] Unity: Формат распространения — Asset Store package или Git submodule?
- [ ] Web: Нужен ли npm package или только standalone JS файл?

## References

- [Спецификации нативного движка](../sdd-render-engine-native/03-specifications-ru.md)
- [Legacy Bhagavadgita Web (CreateJS)](../../legacy/legacy-bhagavadgita-render-engine-web-css/)
- [Legacy Mahabharata Android (Java)](../../legacy/legacy-mahabharata-render-engine-android-java/)
- [Legacy Mahabharata iOS (Swift)](../../legacy/legacy-mahabharata-render-engine-ios-swift/)

---

## Approval

- [x] Reviewed by: Anton
- [x] Approved on: 2026-05-08
- [x] Notes: Distribution format (Asset Store/npm) to be decided later
