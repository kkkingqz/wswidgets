import GLib from 'gi://GLib';
import {validateCommand} from '../quickshell/framework/wire.mjs';
const theme = await import('../extension/lib/menuTheme.js').catch(() => ({}));
const contract = await import('../quickshell/framework/theme.mjs').catch(() => ({}));
const native = await import('../extension/lib/buttonTheme.js').catch(() => ({}));
const assert = (value, message) => {if (!value) throw Error(message);};
const delay = () => new Promise(resolve => GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {resolve();return GLib.SOURCE_REMOVE;}));
function emitter() {
    const callbacks = new Map(); let seq = 0;
    return {connect(name, cb) {callbacks.set(++seq, {name, cb});return seq;}, disconnect(id) {callbacks.delete(id);}, emit(name) {for(const {name:n,cb} of callbacks.values())if(n===name)cb();}};
}
async function fixture(run) {
    assert(typeof theme.MenuTheme === 'function', 'native menu theme synchronization is missing');
    let background = {red:32,green:48,blue:64,alpha:128};
    const foreground = {red:240,green:241,blue:242,alpha:255};
    const node = {get_background_color: () => background,get_foreground_color: () => foreground};
    const actor = {...emitter(),get_theme_node: () => node};
    const context = emitter(); const calls = [];
    const client = {snapshot:null,generation:1,call:async (method,args) => {calls.push({method,args});return true;}};
    const sync = new theme.MenuTheme(client,actor,context);
    try {await run({sync,actor,context,client,calls,setBackground:value=>{background=value;}});}
    finally {sync.destroy();}
}
export const tests = {
    buttonStatesPreserveFocusCombinations: () => {
        assert(typeof contract.buttonStateKey === 'function', 'shared button state contract missing');
        assert(contract.buttonStateKey(true,false,false,false,false)==='normal','normal state');
        assert(contract.buttonStateKey(true,true,true,true,true)==='checked+pressed+hover+focus','combined states lose focus');
        assert(contract.buttonStateKey(false,true,true,true,true)==='disabled','disabled precedence');
    },
    buttonThemeRejectsIncompleteAndUnsafePayloads: () => {
        assert(typeof contract.validateTheme === 'function', 'button theme validation missing');
        const value = buttonPalette();
        const command = args => ({protocolVersion:2,type:'command',seq:1,method:'setTheme',args});
        assert(validateCommand(command(value),'adapter'),'full button theme rejected');
        const bad = [];
        for (const n of [-1,Infinity,NaN,5000]) { const v=buttonPalette();v.buttons.metrics.radius=n;bad.push(v); }
        let v=buttonPalette();delete v.buttons.states['hover+focus'];bad.push(v);
        v=buttonPalette();v.buttons.states.disabled.foreground='red';bad.push(v);
        v=buttonPalette();v.buttons.font.pixelSize=0;bad.push(v);
        v=buttonPalette();v.buttons.font.italic='false';bad.push(v);
        v=buttonPalette();v.buttons.states.normal.focusWidth=-1;bad.push(v);
        v=buttonPalette();v.buttons=null;bad.push(v);
        for (const value of bad) assert(!validateCommand(command(value),'adapter'),'unsafe/incomplete button theme accepted');
    },
    nativeButtonMetricsBecomeLogicalOnce: () => {
        assert(typeof native.readButtonTheme==='function','native button extraction missing');
        const colors={red:32,green:48,blue:64,alpha:128};
        const font={get_family:()=> 'Cantarell',get_size:()=> 32*1024,get_size_is_absolute:()=>true,get_weight:()=>400,get_style:()=>0};
        const node=pseudo=>({get_background_color:()=>colors,get_foreground_color:()=>colors,
            get_border_color:()=>colors,get_border_width:()=>2,get_border_radius:()=>24,
            get_padding:side=>[8,24,8,24][side],get_min_height:()=>60,get_transition_duration:()=>150,
            get_font:()=>font,get_outline_width:()=>0,get_outline_color:()=>colors,
            get_box_shadow:()=>pseudo.includes('focus')?{inset:true,spread:4,color:colors}:null});
        const result=native.readButtonTheme(node,2);
        assert(result.metrics.radius===12 && result.metrics.paddingLeft===12 && result.metrics.paddingTop===4 && result.metrics.minimumHeight===40,'native minimum height omits content-box padding/borders');
        assert(result.font.pixelSize===16 && result.metrics.transitionMs===150,'font/time unit conversion');
        assert(result.states.normal.background==='#80203040' && result.states.normal.borderWidth===1,'alpha/border conversion');
        assert(result.states['checked+pressed+hover+focus'].focusWidth===2,'combined focus ring lost');
        assert(result.states['checked+pressed+hover+focus'].focusColor==='#80203040','focus alpha lost');
    },
    buttonExtractionFailureKeepsAdapterAndPopupPalette: () => fixture(async ({sync: original,client,actor,context,calls}) => {
        original.destroy();
        const sync=new theme.MenuTheme(client,actor,context,()=>{throw Error('unsupported button style');});
        try { client.snapshot={instanceId:'one'};sync.sync();await delay();
            assert(calls.length===1 && calls[0].args.background==='#80203040','button error blocks popup theme');
            assert(calls[0].args.buttons===undefined,'failed extraction sends invalid button data');
        } finally {sync.destroy();}
    }),
    adapterPublishesButtonChangesAndRecoversFromExtractionFailure: () => fixture(async ({sync: original,client,actor,context,calls}) => {
        original.destroy();
        let value=buttonPalette().buttons;
        const sync=new theme.MenuTheme(client,actor,context,()=>{if(value===null)throw Error('unsupported');return value;});
        try {
            client.snapshot={instanceId:'one'};sync.sync();await delay();
            assert(calls.length===1 && calls[0].args.buttons.states.normal.background==='#80203040','adapter omits button state snapshot');
            value=null;context.emit('changed');await delay();
            assert(calls.length===2 && !calls[1].args.buttons,'failed extraction does not return to fallback');
            value=buttonPalette().buttons;value.states.normal.background='#ff123456';context.emit('changed');await delay();
            assert(calls.length===3 && calls[2].args.buttons.states.normal.background==='#ff123456','native button extraction does not recover');
        }finally{sync.destroy();}
    }),
    themeCommandValidatesRoleAndColors: () => {
        const command = args => ({protocolVersion:2,type:'command',seq:1,method:'setTheme',args});
        const colors = {background:'#80203040',foreground:'#fff0f1f2'};
        assert(validateCommand(command(colors),'adapter'),'adapter theme command rejected');
        assert(!validateCommand(command(colors),'cli'),'CLI can replace desktop theme');
        for(const args of [{},{...colors,background:'red'},{...colors,foreground:'#fff'},{...colors,background:'#gg203040'},{...colors,foreground:null}])assert(!validateCommand(command(args),'adapter'),'malformed color accepted');
    },
    nativeColorsKeepAlphaAndQtChannelOrder: () => fixture(async ({sync,client,calls}) => {
        sync.sync();assert(calls.length===0,'sends before adapter connects');
        client.snapshot={instanceId:'one'};sync.sync();await delay();
        assert(calls.length===1 && calls[0].method==='setTheme','theme not sent');
        assert(calls[0].args.background==='#80203040' && calls[0].args.foreground==='#fff0f1f2','RGBA becomes wrong Qt color');
        sync.sync();await delay();assert(calls.length===1,'unchanged theme generates traffic');
    }),
    themeChangeCoalescesAndReconnectResends: () => fixture(async ({sync,actor,context,client,calls,setBackground}) => {
        client.snapshot={instanceId:'one'};sync.sync();await delay();
        setBackground({red:246,green:245,blue:244,alpha:255});context.emit('changed');actor.emit('style-changed');
        await delay();assert(calls.length===2 && calls[1].args.background==='#fff6f5f4','theme change not coalesced/applied');
        client.generation++;sync.sync();await delay();assert(calls.length===3,'reconnect to same runtime loses current theme');
        await delay();assert(calls.length===3,'idle generates theme traffic');
    }),
    destroyCancelsQueuedThemeWork: () => fixture(async ({sync,actor,context,client,calls}) => {
        client.snapshot={instanceId:'one'};actor.emit('style-changed');sync.destroy();context.emit('changed');
        await delay();assert(calls.length===0,'destroyed adapter sends theme');
    }),
};

function buttonPalette() {
    const states={};
    for (const key of ['normal','focus','hover','hover+focus','pressed','pressed+focus','pressed+hover','pressed+hover+focus',
        'checked','checked+focus','checked+hover','checked+hover+focus','checked+pressed','checked+pressed+focus','checked+pressed+hover','checked+pressed+hover+focus','disabled'])
        states[key]={background:'#80203040',foreground:'#fff0f1f2',borderColor:'#ff123456',borderWidth:1,focusColor:'#ffabcdef',focusWidth:0};
    return {background:'#80203040',foreground:'#fff0f1f2',buttons:{states,
        metrics:{radius:12,paddingTop:4,paddingRight:12,paddingBottom:4,paddingLeft:12,minimumHeight:30,transitionMs:150},
        font:{family:'Cantarell',pixelSize:16,weight:400,italic:false}}};
}
