// Display the top recommended model in the OpenCode TUI footer
// and toast banner on startup if a test report exists.
//
// Automatically loaded from ~/.config/opencode/plugins/

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
  setup(ctx) {
    // Server lifecycle
  },
  async tui(api) {
    const rec = getRecommendedModel();
    if (!rec) return;

    const shortName = rec.model.split("/").pop();
    const costStr = rec.costBlended != null ? `$${rec.costBlended.toFixed(2)}/M` : "";

    // 1. Toast notification on startup
    try {
      if (api.ui?.toast?.show) {
        api.ui.toast.show({
          title: "Recommended Model",
          message: `Daily Driver: ${shortName} (${costStr})`,
          variant: "info",
          duration: 5000,
        });
      }
    } catch {}

    // 2. Footer status slot on home screen
    try {
      if (api.ui?.slot) {
        api.ui.slot({
          append: "home.footer.status",
          render: () => `[Model: ${shortName}]`,
        });
      }
    } catch {}
  },
};
