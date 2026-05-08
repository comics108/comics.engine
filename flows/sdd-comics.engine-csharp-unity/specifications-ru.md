# Спецификации: Comics Engine — C# / Unity (тайлинг + слои)

> Версия: 1.0  
> Статус: DRAFT  
> Последнее обновление: 2026-05-08  
> Источник: извлечено из `flows/sdd-render-csharp-and-web-css/specifications.md` и сведено в отдельный Unity-документ
>
> Формат `.comics` (ZIP + `data.json`) — см. `../sdd-comics-format/02-specifications-ru.md`

---

## Обзор

Unity/C# движок отображает `.comics` архивы в Unity (world-space), сохраняя инварианты тайлинга и анимаций из нативных спецификаций.

---

## 1. Инварианты (нельзя менять)

| Параметр | Значение |
|----------|----------|
| TILE_SIZE | 512 px |
| Tile naming | `{0}_{1}_{2}` |
| `{0}` | `Int(zoom * 1000)` |
| Порядок трансформаций | Scale → Rotate → Translate |
| Сглаживание | \( (f-1)^3 + 1 \) |

---

## 2. Архитектура Unity

```
ComicsCamera (Orthographic)
  - zoom: orthographicSize
  - pan: transform.position

ComicsContainer (Empty GO)
  - parent for all layers
  - scroll offset via transform.localPosition.y

LayerN (Quad + Material)
  - TileRenderer (генерация/подмена тайлов)

ComicsArchive (runtime)
  - loads data.json
  - reads tile textures from ZIP
```

---

## 3. Классы C# (контракты)

### 3.1. ComicsViewer.cs

Обязанности:

- загрузка архива
- управление scrollOffset/languageIndex/soundEnabled
- создание и обновление `LayerRenderer`
- hitTest

### 3.2. Data model: Comics / Layer / Image / Anim

Требования:

- `Comics.Prepare()` сортирует/раскладывает анимации
- `Comics.Process(scrollOffset)` вызывает `Layer.BuildMatrixAndAlpha(scrollOffset)`
- `Layer.BuildMatrixAndAlpha`:
  - сбрасывает матрицу
  - применяет анимации в порядке Scale → Rotate → Translate
  - применяет alpha

### 3.3. Anim: fraction + cubic easing

- fraction: clamp по `start..end`
- cubic easing: \( (f-1)^3 + 1 \)

---

## 4. TileRenderer (Unity)

Требования:

- TILE_SIZE = 512
- вычисление имени тайла:

```
template
  .Replace("{0}", ((int)(zoom * 1000)).ToString())
  .Replace("{1}", col.ToString())
  .Replace("{2}", row.ToString());
```

- загрузка тайлов из ZIP асинхронно (coroutines) с дедупликацией
- выгрузка тайлов вне viewport + margin

---

## 5. Scroll handling (Unity)

- scrollOffset меняется от wheel/touch drag
- clamp в диапазон 0..maxScroll
- после изменения: `viewer.SetScrollOffset(offset)` и `viewer.comics.Process(offset)`

---

---

## 6. Shared Core Refactoring

> Добавлено 2026-05-08

### 6.1 IComicsSource Abstraction

Текущая реализация тесно связана с `ZipArchiveProvider`. Для поддержки редактора требуется абстракция:

```csharp
interface IComicsSource
{
    Comics LoadData();
    Texture2D LoadTile(string path);
    AudioClip LoadSound(string path);
    bool IsReadOnly { get; }
    void Invalidate();
}
```

### 6.2 Implementations

| Source | Context | IsReadOnly |
|--------|---------|------------|
| `ZipArchiveSource` | Runtime (standalone) | true |
| `FolderSource` | Editor (temp workspace) | false |

### 6.3 Migration

- `ZipArchiveProvider` → `ZipArchiveSource : IComicsSource`
- Add `ComicsViewer.Initialize(IComicsSource)`
- Add `ComicsViewer.LoadFolder(string)` for editor

### Related

- Detailed specs: `../sdd-comics.engine-shared-core/02-specifications.md`
- ADR: `../adr-006-transform-composition-order/adr.md`

---

## Утверждение

- [ ] Reviewed by: [name]
- [ ] Approved on: [date]
- [ ] Notes: [conditions/clarifications]

