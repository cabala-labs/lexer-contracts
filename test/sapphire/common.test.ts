import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { _initialDeploymentFixture, _initialSettingsFixture } from "./utils";

describe("Sapphire Engine", function () {
  describe("Deployment", function () {
    it("initial deployment", async function () {
      await loadFixture(_initialDeploymentFixture);
    });

    it("trial initial settings", async function () {
      await loadFixture(_initialSettingsFixture);
    });
  });
});
