// Desktop facts from `wsdbus-ctl --json watch` (the wsdbus Desktop1
// contract): only session.locked and appearance.scheme (wsdbus W10).
export const initialDesktop = Object.freeze({connected: false, locked: false, scheme: ''});

const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
const FACTS = {
    'session.locked': ['locked', v => typeof v === 'boolean', false],
    'appearance.scheme': ['scheme', v => v === 'light' || v === 'dark', ''],
};
// The QML engine has no object spread and no Object.hasOwn.
const known = name => Object.prototype.hasOwnProperty.call(FACTS, name);

function withFacts(state, facts, removed) {
    const next = Object.assign({}, state);
    for (const name of removed)
        if (typeof name === 'string' && known(name)) next[FACTS[name][0]] = FACTS[name][2];
    for (const [name, value] of Object.entries(facts)) {
        if (!known(name)) continue;
        const [key, valid] = FACTS[name];
        // A known fact with a wrong value is dropped, the rest applies.
        if (valid(value)) next[key] = value;
    }
    return next;
}

/** The desktop state after one JSON line of `watch`. */
export function applyDesktopLine(state, line) {
    let frame;
    try { frame = JSON.parse(line); } catch (_) { return state; }
    if (!object(frame)) return state;
    if (frame.lost === true) return initialDesktop;
    if (frame.snapshot === true)
        return withFacts(Object.assign({}, initialDesktop, {connected: true}), object(frame.facts) ? frame.facts : {}, []);
    // Window changes carry no facts; their removed are window ids.
    if (!state.connected || !object(frame.facts)) return state;
    return withFacts(state, frame.facts, Array.isArray(frame.removed) ? frame.removed : []);
}
