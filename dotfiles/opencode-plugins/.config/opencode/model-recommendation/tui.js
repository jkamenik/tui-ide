// Display the top recommended model in the OpenCode TUI footer
// and toast banner on startup if a test report exists.

import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const SOURCE = "opencode:model-recommendation";

function getRecommendedModel() {
  const file = path.join(os.homedir(), ".cache", "opencode", "recommended-model.json");
  if (!fs.existsSync(file)) return null;
  try {
    const data = JSON.parse(fs.readFileSync(file, "utf8"));
    const workhorse = data.recommendations?.find((r) => r.archetype.includes("Workhorse"));
    return workhorse || data.recommendations?.[0] || null;
  } catch {
    return null;
  }
}

export default {
  id: SOURCE,
  async setup(context) {
    const rec = getRecommendedModel();
    if (!rec) return;

    const shortName = rec.model.split("/").pop();
    const costStr = rec.costBlended != null ? `$${rec.costBlended.toFixed(2)}/M` : "";

    // 1. Toast notification on startup
    try {
      if (context.ui?.toast?.show) {
        setTimeout(() => {
          try {
            context.ui.toast.show({
              title: "Recommended Model",
              message: `Daily Driver: ${shortName} (${costStr})`,
              variant: "info",
              duration: 5000,
            });
          } catch {}
        }, 400).unref?.();
      }
    } catch {}

    // 2. Footer slots (Home screen and Chat prompt screen)
    try {
      const { createElement, createTextNode, insert } = await import("@opentui/solid");

      const renderStatus = () => {
        const textEl = createElement("text");
        const mutedColor = context.theme?.text?.muted || "#888888";
        textEl.fg = mutedColor;
        insert(textEl, createTextNode(`[Model: ${shortName}]`));
        return textEl;
      };

      if (context.ui?.slot) {
        // Landing page footer
        context.ui.slot({
          append: "home.footer.status",
          render: renderStatus,
        });

        // Chat prompt footer
        context.ui.slot({
          append: "prompt.footer.status",
          render: renderStatus,
        });
      }
    } catch (err) {
      // Fallback: toast already displayed
    }
  },
};
