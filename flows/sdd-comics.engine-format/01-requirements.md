# Requirements: Формат `.comics` (архив + `data.json`)

> Version: 1.0  
> Status: DRAFT  
> Last Updated: 2026-05-08

## Problem Statement

Формат контента `.comics` должен быть **единственным источником правды** для всех рендер-движков:

- Flutter plugin native (Android/iOS)
- Web (JS+CSS)
- Unity (C#)

Чтобы это работало, формат обязан:

- быть переносимым между платформами
- быть стриминг-дружелюбным (ленивая загрузка тайлов)
- гарантировать совместимость с legacy архивами (инварианты тайлов/анимаций)

## User Stories

- **As a** создатель контента  
  **I want** один архив `.comics`  
  **So that** он одинаково работает на Android/iOS/Web/Unity без переконвертации.

- **As a** разработчик рендера  
  **I want** детерминированный формат и инварианты  
  **So that** можно реализовать движок независимо и получить одинаковый визуальный результат.

## Acceptance Criteria

### Must Have

1. **ZIP container**  
   **Given** файл с расширением `.comics`  
   **When** движок открывает его  
   **Then** это ZIP-архив, содержащий минимум `data.json` и ресурсы, на которые он ссылается.

2. **Canonical `data.json` schema (v1)**  
   **Given** `data.json`  
   **When** движок парсит его  
   **Then** он содержит `width`, `height`, `layers[]` и (опционально) `sounds[]`, достаточные для scroll-driven рендера.

3. **Tile invariants (v1)**  
   **Given** тайловый слой  
   **When** движок генерирует имена тайлов  
   **Then** соблюдены инварианты:
   - `TILE_SIZE = 512`
   - filename template использует `{0}`, `{1}`, `{2}`
   - `{0} = Int(zoom * 1000)`, `{1} = col`, `{2} = row`

4. **Animation invariants (v1)**  
   **Given** анимации слоёв (scale/rotate/translate/alpha)  
   **When** scrollOffset меняется  
   **Then** математика интерполяции и порядок применения совместимы между движками:
   - порядок: Scale → Rotate → Translate, alpha отдельно
   - easing: \( (f-1)^3 + 1 \)

5. **Language fallback**  
   **Given** `images[]` массив в слое  
   **When** выбран язык `languageIndex`  
   **Then** берётся `images[languageIndex]`, иначе fallback на первое непустое.

### Should Have

- **Forward-compatible versioning**: поддержка расширений формата через поле `version` (по умолчанию 1).
- **Optional directories**: `sounds/` может отсутствовать, если `sounds[]` пуст.

### Won't Have (v1)

- Обязательная поддержка “v2 расширений” (zDepth, speech bubbles) — допускается как future extension, но не требование v1.

## Constraints

- Формат должен быть простым для реализации без “тяжёлых” зависимостей.
- Формат должен позволять **ленивую** загрузку тайлов по viewport.

## Open Questions

- [ ] Нужен ли строгий JSON Schema (machine-verifiable), или достаточно документированной структуры?
- [ ] Нужна ли нормализация путей (`layers/...`) и запрет `../` для безопасности?

---

## Approval

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

