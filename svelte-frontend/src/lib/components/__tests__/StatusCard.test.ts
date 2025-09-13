import { render, screen } from "@testing-library/svelte";
import { expect, test } from "vitest";
import "@testing-library/jest-dom";
import StatusCard from "../StatusCard.svelte";

test("renders status card with correct title and value", () => {
  render(StatusCard, {
    props: {
      title: "Test Status",
      value: "100",
      unit: "MW",
      status: "normal",
    },
  });

  expect(screen.getByText("Test Status")).toBeInTheDocument();
  expect(screen.getByText("100")).toBeInTheDocument();
  expect(screen.getByText("MW")).toBeInTheDocument();
});

test("applies correct status styling", () => {
  const { container } = render(StatusCard, {
    props: {
      title: "Test Status",
      value: "100",
      status: "error",
    },
  });

  const statusElement = container.querySelector(".bg-red-100");
  expect(statusElement).toBeInTheDocument();
});

test("shows trend information when provided", () => {
  render(StatusCard, {
    props: {
      title: "Test Status",
      value: "100",
      trend: "up",
      trendValue: "+5%",
    },
  });

  expect(screen.getByText("+5%")).toBeInTheDocument();
});
