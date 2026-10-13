import {acceptSnapshot} from '../extension/lib/protocol.mjs';
import {createState} from '../quickshell/framework/model.mjs';
import {validateCommand} from '../quickshell/framework/wire.mjs';
function assert(v) { if (!v) throw new Error('protocol validation'); }
export const tests = {
    presentationValidationAndPopupDismissalRole: () => {
        const s=createState([{id:'window',enabled:true,presentation:'window',width:400,height:300}], 'one',42);
        assert(acceptSnapshot(null,s)!==null);
        s.selectedId='window';assert(acceptSnapshot(null,s)===null);
        s.selectedId=null;s.widgets.window.presentation='unknown';assert(acceptSnapshot(null,s)===null);
        const command={protocolVersion:2,type:'command',seq:1,method:'hidePopups',args:{}};
        assert(validateCommand(command,'adapter') && !validateCommand(command,'cli'));
    },
    order: () => { const a = createState([], 'one', 42); a.revision = 9; assert(acceptSnapshot(a, {...a, revision: 8}) === null); assert(acceptSnapshot(a, {...a, instanceId: 'two', revision: 0}) !== null); },
    malformed: () => { for (const s of [null, {}, {protocolVersion: 2}, {...createState([], 'one', 42), revision: -1}, {...createState([], 'one', 42), widgets: {bad: {phase: 'oops'}}}]) assert(acceptSnapshot(null, s) === null); },
};
