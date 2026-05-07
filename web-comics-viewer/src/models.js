/**
 * Comics Data Models
 * Parses data.json into structured JavaScript objects
 */

export function parseComicsData(json) {
  return {
    width: json.width || 1080,
    height: json.height || 1920,
    layers: (json.layers || []).map(parseLayer),
    sounds: (json.sounds || []).map(parseSound)
  };
}

function parseLayer(json) {
  return {
    id: json.id || null,
    x: json.x || 0,
    y: json.y || 0,
    width: json.width || 0,
    height: json.height || 0,
    alpha: json.alpha !== undefined ? json.alpha : 1.0,
    images: (json.images || []).map(parseImage),
    animations: (json.anim || []).map(parseAnimation)
  };
}

function parseImage(json) {
  return {
    src: json.src,
    locale: json.locale || null
  };
}

function parseAnimation(json) {
  const base = {
    type: json.type,
    start: json.start || 0,
    end: json.end || 0
  };

  switch (json.type) {
    case 'translate':
      return {
        ...base,
        fromX: json.fromX || 0,
        fromY: json.fromY || 0,
        toX: json.toX || 0,
        toY: json.toY || 0
      };

    case 'rotate':
      return {
        ...base,
        from: json.from || 0,
        to: json.to || 0,
        pivotX: json.pivotX || 0,
        pivotY: json.pivotY || 0
      };

    case 'scale':
      return {
        ...base,
        fromX: json.fromX !== undefined ? json.fromX : 1,
        fromY: json.fromY !== undefined ? json.fromY : 1,
        toX: json.toX !== undefined ? json.toX : 1,
        toY: json.toY !== undefined ? json.toY : 1,
        pivotX: json.pivotX || 0,
        pivotY: json.pivotY || 0
      };

    case 'alpha':
      return {
        ...base,
        from: json.from !== undefined ? json.from : 1,
        to: json.to !== undefined ? json.to : 1
      };

    default:
      return base;
  }
}

function parseSound(json) {
  return {
    src: json.src,
    type: json.type || 'point', // 'point' or 'range'
    start: json.start || 0,
    end: json.end || null,
    volume: json.volume !== undefined ? json.volume : 1.0,
    loop: json.loop || false
  };
}

export default { parseComicsData };
