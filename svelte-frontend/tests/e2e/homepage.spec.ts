import { test, expect } from "@playwright/test";

test.describe("Homepage", () => {
  test("should load the homepage successfully", async ({ page }) => {
    await page.goto("/");

    // Check if the main heading is visible
    await expect(
      page.getByRole("heading", { name: /VoltEdge/i })
    ).toBeVisible();

    // Check if the hero section is present
    await expect(
      page.getByText(/Real-Time Energy Grid Simulator/i)
    ).toBeVisible();
  });

  test("should navigate to dashboard when clicking dashboard button", async ({
    page,
  }) => {
    await page.goto("/");

    // Click the dashboard button
    await page.getByRole("button", { name: /View Dashboard/i }).click();

    // Check if we're on the dashboard page
    await expect(page).toHaveURL("/dashboard");
    await expect(
      page.getByRole("heading", { name: /Dashboard/i })
    ).toBeVisible();
  });

  test("should be responsive on mobile devices", async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto("/");

    // Check if the page is still functional on mobile
    await expect(
      page.getByRole("heading", { name: /VoltEdge/i })
    ).toBeVisible();

    // Check if buttons are still clickable
    await expect(
      page.getByRole("button", { name: /View Dashboard/i })
    ).toBeVisible();
  });

  test("should have proper accessibility attributes", async ({ page }) => {
    await page.goto("/");

    // Check for proper heading hierarchy
    const h1 = page.getByRole("heading", { level: 1 });
    await expect(h1).toBeVisible();

    // Check for proper button roles
    const buttons = page.getByRole("button");
    await expect(buttons).toHaveCount(2); // Create New Simulation and View Dashboard

    // Check for proper link roles
    const links = page.getByRole("link");
    await expect(links).toHaveCount(0); // No links on homepage
  });
});
