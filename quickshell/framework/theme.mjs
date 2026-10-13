// DE-neutral appearance contract. Kept identical in extension/lib/theme.mjs.
export function buttonStateKey(enabled, hovered, down, checked, focus) {
    if (!enabled) return 'disabled';
    return [checked && 'checked', down && 'pressed', hovered && 'hover', focus && 'focus'].filter(Boolean).join('+') || 'normal';
}
export const buttonStateKeys = Array.from({length:16}, (_, n) =>
    buttonStateKey(true, Boolean(n & 2), Boolean(n & 4), Boolean(n & 8), Boolean(n & 1))).concat('disabled');
const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const color = v => typeof v === 'string' && /^#[0-9a-f]{8}$/i.test(v);
const number = (v, min, max) => typeof v === 'number' && Number.isFinite(v) && v >= min && v <= max;
export function validateButtons(v) {
    if (!object(v) || !object(v.metrics) || !object(v.font) || !object(v.states)) return false;
    const m=v.metrics, f=v.font;
    if (!['radius','paddingTop','paddingRight','paddingBottom','paddingLeft'].every(k=>number(m[k],0,128))
        || !number(m.minimumHeight,0,256) || !number(m.transitionMs,0,1000)
        || typeof f.family !== 'string' || !f.family.length || f.family.length > 256
        || !number(f.pixelSize,1,256) || !Number.isInteger(f.weight) || !number(f.weight,1,1000)
        || typeof f.italic !== 'boolean') return false;
    return buttonStateKeys.every(key => {
        const s=v.states[key];
        return object(s) && ['background','foreground','borderColor','focusColor'].every(k=>color(s[k]))
            && number(s.borderWidth,0,64) && number(s.focusWidth,0,64);
    });
}
export function validateTheme(v) {
    return object(v) && color(v.background) && color(v.foreground)
        && (v.buttons === undefined || validateButtons(v.buttons));
}
