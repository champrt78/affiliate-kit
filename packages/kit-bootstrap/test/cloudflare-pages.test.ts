import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { createPagesProject } from "../src/cloudflare-pages.js";
import * as wrangler from "../src/wrangler.js";

describe("createPagesProject", () => {
  let runWranglerSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    runWranglerSpy = vi
      .spyOn(wrangler, "runWrangler")
      .mockResolvedValue({ exitCode: 1, stderr: "already exists", stdout: "" });
  });

  afterEach(() => {
    runWranglerSpy.mockRestore();
  });

  it("treats 'already exists' as success", async () => {
    await expect(
      createPagesProject({
        projectName: "test",
        productionBranch: "main",
        apiToken: "t",
        accountId: "a",
      })
    ).resolves.not.toThrow();
  });
});
