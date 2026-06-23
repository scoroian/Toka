// functions/src/shared/log.test.ts
//
// Hallazgo #17: logging estructurado consistente. Permite reconstruir el
// historial de un usuario/hogar correlacionando por homeId/uid/correlationId.

import * as logger from "firebase-functions/logger";
import { newCorrelationId, logEvent } from "./log";

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
}));

describe("newCorrelationId", () => {
  it("devuelve una cadena no vacía", () => {
    const id = newCorrelationId();
    expect(typeof id).toBe("string");
    expect(id.length).toBeGreaterThan(0);
  });

  it("dos llamadas devuelven ids distintos", () => {
    expect(newCorrelationId()).not.toBe(newCorrelationId());
  });
});

describe("logEvent", () => {
  beforeEach(() => jest.clearAllMocks());

  it("info: llama logger.info con {event, ...campos} estructurados", () => {
    logEvent("info", "fcm_send", {
      homeId: "h1",
      uid: "u1",
      correlationId: "c1",
    });
    expect(logger.info).toHaveBeenCalledWith("fcm_send", {
      event: "fcm_send",
      homeId: "h1",
      uid: "u1",
      correlationId: "c1",
    });
  });

  it("warn/error usan el nivel correspondiente", () => {
    logEvent("warn", "fcm_failed", { homeId: "h1" });
    expect(logger.warn).toHaveBeenCalledWith("fcm_failed", {
      event: "fcm_failed",
      homeId: "h1",
    });

    logEvent("error", "fatal", {});
    expect(logger.error).toHaveBeenCalledWith("fatal", { event: "fatal" });
  });

  it("sin campos extra solo emite {event}", () => {
    logEvent("info", "ping");
    expect(logger.info).toHaveBeenCalledWith("ping", { event: "ping" });
  });
});
