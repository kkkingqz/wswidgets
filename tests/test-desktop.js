import {applyDesktopLine, initialDesktop} from '../quickshell/framework/desktop.mjs';
const assert = (value, message) => {if (!value) throw Error(message);};
const line = frame => JSON.stringify(frame);
const snapshot = facts => line({snapshot: true, revision: 1, provider: 'fake', version: 1, capabilities: [], facts, windows: []});

export const tests = {
    'snapshot sets the facts'() {
        const state = applyDesktopLine(initialDesktop, snapshot({'session.locked': true, 'appearance.scheme': 'dark', 'focus.app': 'x'}));
        assert(state.connected && state.locked && state.scheme === 'dark', JSON.stringify(state));
    },
    'snapshot without the facts keeps the defaults'() {
        const state = applyDesktopLine(initialDesktop, snapshot({}));
        assert(state.connected && !state.locked && state.scheme === '', JSON.stringify(state));
    },
    'changes and removals apply'() {
        let state = applyDesktopLine(initialDesktop, snapshot({'appearance.scheme': 'light'}));
        state = applyDesktopLine(state, line({revision: 2, facts: {'session.locked': true}, removed: ['appearance.scheme']}));
        assert(state.locked && state.scheme === '', JSON.stringify(state));
        state = applyDesktopLine(state, line({revision: 3, facts: {}, removed: ['session.locked']}));
        assert(!state.locked, 'removed lock stays');
    },
    'window changes and bad values are ignored'() {
        let state = applyDesktopLine(initialDesktop, snapshot({'session.locked': false, 'appearance.scheme': 'dark'}));
        const before = state;
        state = applyDesktopLine(state, line({revision: 2, windows: [], removed: ['session.locked']}));
        assert(state === before, 'window removal touched the facts');
        state = applyDesktopLine(state, line({revision: 3, facts: {'session.locked': 'yes', 'appearance.scheme': 'blue'}, removed: []}));
        assert(!state.locked && state.scheme === 'dark', JSON.stringify(state));
        for (const bad of ['', 'not json', '[]', 'null'])
            assert(applyDesktopLine(state, bad) === state, `accepted ${bad}`);
    },
    'changes before a snapshot and after loss are ignored'() {
        const change = line({revision: 2, facts: {'session.locked': true}, removed: []});
        assert(applyDesktopLine(initialDesktop, change) === initialDesktop, 'change without a snapshot');
        let state = applyDesktopLine(initialDesktop, snapshot({'session.locked': true}));
        state = applyDesktopLine(state, line({lost: true}));
        assert(state === initialDesktop, 'loss keeps the facts');
        assert(applyDesktopLine(state, change) === initialDesktop, 'change after loss');
    },
};
