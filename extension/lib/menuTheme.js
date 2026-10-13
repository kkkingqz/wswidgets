import GLib from 'gi://GLib';
import {qtColor} from './buttonTheme.js';
import {validateTheme} from './theme.mjs';
export class MenuTheme {
    constructor(client, actor, context, readButtons = () => undefined) {
        this.client = client; this.actor = actor; this.context = context;
        this.readButtons = readButtons;
        this.idle = 0; this.signature = null; this.stopped = false; this.reading = false;
        this.actorSignal = actor.connect('style-changed', () => this.schedule());
        this.contextSignal = context.connect('changed', () => this.schedule());
    }
    schedule() {
        if (this.stopped || this.reading || this.idle) return;
        this.idle = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this.idle = 0; this.sync(); return GLib.SOURCE_REMOVE;
        });
    }
    sync() {
        if (this.stopped || !this.client.snapshot) return;
        let palette;
        this.reading = true;
        try {
            const node = this.actor.get_theme_node();
            palette = {background: qtColor(node.get_background_color()), foreground: qtColor(node.get_foreground_color())};
            // An unsupported user button stylesheet must not break the adapter.
            try { const buttons=this.readButtons(); if (buttons) palette.buttons=buttons; } catch (_) {}
            if (!validateTheme(palette)) return;
        } catch (_) { return;
        } finally { this.reading = false; }
        const signature = `${this.client.snapshot.instanceId}:${this.client.generation}:${JSON.stringify(palette)}`;
        if (this.signature === signature) return;
        this.signature = signature;
        this.client.call('setTheme', palette).catch(() => {
            if (this.signature === signature) this.signature = null;
        });
    }
    destroy() {
        if (this.stopped) return;
        this.stopped = true;
        if (this.idle) GLib.source_remove(this.idle);
        this.idle = 0;
        this.actor.disconnect(this.actorSignal); this.context.disconnect(this.contextSignal);
    }
}
