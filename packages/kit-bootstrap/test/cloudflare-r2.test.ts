import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { createR2Bucket } from "../src/cloudflare-r2.js";
import * as wrangler from "../src/wrangler.js";

describe("createR2Bucket", () => {
  let runWranglerSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    runWranglerSpy = vi
      .spyOn(wrangler, "runWrangler")
      .mockResolvedValue({ exitCode: 0, stdout: "", stderr: "" });
  });

  afterEach(() => {
    runWranglerSpy.mockRestore();
  });

  it("calls wrangler r2 bucket create with the bucket name", async () => {
    await createR2Bucket({ bucketName: "test-images", apiToken: "t", accountId: "a" });
    expect(wrangler.runWrangler).toHaveBeenCalled();
    const call = vi.mocked(wrangler.runWrangler).mock.calls[0];
    expect(call[0]).toContain("test-images");
  });
});
