import night from "@shikijs/themes/tokyo-night";

const nvim = (scope, foreground) => ({ scope, settings: { foreground } });

export default {
	...night,
	name: "nerdtools-night",
	colors: { ...night.colors, "editor.foreground": "#ABB2BF" },
	tokenColors: [
		...night.tokenColors,
		nvim(["keyword.control", "storage", "storage.type", "storage.type.function", "storage.modifier"], "#B877DB"),
		nvim(["constant.numeric", "constant.language"], "#FF9668"),
		nvim(["entity.name.function", "support.function", "meta.function-call"], "#E95678"),
		nvim(["variable", "variable.other", "variable.parameter", "meta.definition.variable"], "#DBBE7F"),
		nvim(["string", "string.quoted", "string.template"], "#e6a98a"),
		nvim(["entity.name.type", "support.type", "entity.name.class", "support.class"], "#64D1A9"),
		nvim(["meta.decorator", "punctuation.decorator", "meta.preprocessor"], "#d6a786"),
		nvim(["comment", "punctuation.definition.comment"], "#3c3d57"),
	],
};
