const config = {
	entry: "./src/main.ms",
	build: { target: "js" },
	fmt: { useTabs: true },
	globalImports: ["../../neon/src/converters"],
};
export default config;
