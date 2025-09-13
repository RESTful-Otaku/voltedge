import { afterEach } from "vitest";
import { cleanup } from "@testing-library/svelte";
import "@testing-library/jest-dom";

// Cleanup after each test
afterEach(() => {
  cleanup();
});
