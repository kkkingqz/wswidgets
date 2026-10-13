import {buttonStateKeys, validateButtons} from './theme.mjs';

export function qtColor(color) {
    return '#' + [color.alpha, color.red, color.green, color.blue]
        .map(value => value.toString(16).padStart(2, '0')).join('');
}

// nodeFor supplies the native theme boundary; no GNOME types enter the wire data.
export function readButtonTheme(nodeFor, scale, resolution = 96) {
    if (!Number.isFinite(scale) || scale <= 0) throw Error('Invalid Shell theme scale');
    const normal=nodeFor(''), font=normal.get_font();
    const states={};
    for (const key of buttonStateKeys) {
        const pseudo=key === 'normal' ? '' : key.replace('disabled','insensitive').replace('pressed','active').replaceAll('+',' ');
        const node=nodeFor(pseudo), shadow=node.get_box_shadow();
        const focus=key.includes('focus');
        const inset=focus && shadow?.inset && shadow.spread > 0;
        states[key]={background:qtColor(node.get_background_color()), foreground:qtColor(node.get_foreground_color()),
            borderColor:qtColor(node.get_border_color(0)), borderWidth:node.get_border_width(0)/scale,
            focusColor:inset ? qtColor(shadow.color) : qtColor(node.get_outline_color()),
            focusWidth:focus ? (inset ? shadow.spread : node.get_outline_width())/scale : 0};
    }
    const result={states, metrics:{radius:normal.get_border_radius(0)/scale,
        paddingTop:normal.get_padding(0)/scale,paddingRight:normal.get_padding(1)/scale,
        paddingBottom:normal.get_padding(2)/scale,paddingLeft:normal.get_padding(3)/scale,
        // St's CSS min-height is the content box; the QML minimum is outer size.
        minimumHeight:(Math.max(0,normal.get_min_height()) + normal.get_padding(0) + normal.get_padding(2)
            + normal.get_border_width(0) + normal.get_border_width(2))/scale,
        transitionMs:normal.get_transition_duration()},
        font:{family:font.get_family(),pixelSize:font.get_size()/1024 * (font.get_size_is_absolute() ? 1 : resolution/72) / scale,
            weight:font.get_weight(),italic:font.get_style()!==0}};
    if (!validateButtons(result)) throw Error('Unsupported native button metrics');
    return result;
}
