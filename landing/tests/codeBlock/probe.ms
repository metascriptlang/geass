import { element } from "../../../../neon/src/macros/ui/element";
import { View } from "../../../../neon/src/components/primitives";
import { render } from "../../../../neon/src/render/host";
import { domHost, documentBody } from "../../../../neon/src/platform/browser/dom";
import { CodeBlock } from "../../src/ui/codeBlock";

const SAMPLE = "import { Account } from \"geass/account\";\n\n@program\nexport function deposit(vault: Account, amount: uint64): void {\n\tif (amount == 0) { throw new Error(\"empty deposit\"); }\n\tvault.lamports += amount; // checked add\n}";

render(element(<View><CodeBlock code={SAMPLE} /></View>), domHost(), documentBody());
