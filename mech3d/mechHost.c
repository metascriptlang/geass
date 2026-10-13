// Stands in for std/fs readFile, which does not link on emcc:
// ~/metascript/.inbox/compiler/2026-10-10-std-fs-does-not-link-on-emcc.md
#include <stdio.h>
#include <emscripten.h>
#include "mechHost.h"

int64_t mechFileSize(const char *name) {
	FILE *file = fopen(name, "rb");
	if (!file) return -1;
	fseek(file, 0, SEEK_END);
	long size = ftell(file);
	fclose(file);
	return size;
}

int32_t mechFileRead(const char *name, uint8_t *out, int64_t count) {
	FILE *file = fopen(name, "rb");
	if (!file) return 0;
	size_t got = fread(out, 1, (size_t)count, file);
	fclose(file);
	return got == (size_t)count;
}

EM_JS(double, mechScrollProgress, (void), {
	const unfold = parseFloat(document.documentElement.style.getPropertyValue("--scroll"));
	if (!isNaN(unfold)) return unfold;
	const range = document.documentElement.scrollHeight - innerHeight;
	return range > 0 ? Math.min(1, Math.max(0, scrollY / range)) : 0;
});

EM_JS(double, mechPageProgress, (void), {
	const page = parseFloat(document.documentElement.style.getPropertyValue("--page"));
	if (!isNaN(page)) return page;
	const range = document.documentElement.scrollHeight - innerHeight;
	return range > 0 ? Math.min(1, Math.max(0, scrollY / range)) : 0;
});

EM_JS(void, mechReady, (void), {
	Module.canvas.dispatchEvent(new Event("mechready"));
});

EM_JS(double, mechNow, (void), {
	return performance.now();
});

EM_JS(void, mechFetchStage, (int32_t stage), {
	const files = stage == 1 ? ["body.glb.packed", "coreLite.glb.packed"] : ["coreDetail.glb.packed"];
	Module.mechStages = Module.mechStages || {};
	Promise.all(files.map(async (file) => {
		const reply = await fetch("/void/models/" + file);
		if (!reply.ok) throw new Error(file + " answered " + reply.status);
		const bytes = reply.body.pipeThrough(new DecompressionStream("gzip"));
		FS.writeFile(file.slice(0, -".packed".length), new Uint8Array(await new Response(bytes).arrayBuffer()));
	})).then(
		() => { Module.mechStages[stage] = 1; },
		(reason) => {
			console.error("mech view: stage " + stage + " did not load:", reason);
			Module.mechStages[stage] = -1;
		}
	);
});

EM_JS(int32_t, mechStageArrived, (int32_t stage), {
	return (Module.mechStages && Module.mechStages[stage]) || 0;
});

EM_JS(double, mechTuned, (const char *name, double low, double high, double preset), {
	if (Module.mechKnobs === undefined) {
		Module.mechKnobs = null;
		if (new URLSearchParams(location.search).has("tune") && ["127.0.0.1", "localhost"].includes(location.hostname)) {
			const panel = document.createElement("div");
			panel.style.cssText = "position:fixed;left:12px;top:96px;z-index:9999;width:250px;padding:10px 12px;border-radius:6px;background:rgba(18,18,20,.9);color:#eee;font:12px/1.5 ui-monospace,monospace";
			document.body.appendChild(panel);
			Module.mechKnobs = { panel, values: {} };
		}
	}
	const knobs = Module.mechKnobs;
	if (!knobs) return preset;
	const label = UTF8ToString(name);
	if (!(label in knobs.values)) {
		knobs.values[label] = preset;
		const row = document.createElement("label");
		const shown = document.createElement("span");
		const slider = document.createElement("input");
		row.style.cssText = "display:block;margin-bottom:6px";
		slider.type = "range";
		slider.min = low;
		slider.max = high;
		slider.step = (high - low) / 300;
		slider.value = preset;
		slider.style.cssText = "display:block;width:100%";
		const show = () => { shown.textContent = label + "  " + Number(slider.value).toFixed(3); };
		slider.addEventListener("input", () => { knobs.values[label] = Number(slider.value); show(); });
		show();
		row.append(shown, slider);
		knobs.panel.appendChild(row);
	}
	return knobs.values[label];
});
