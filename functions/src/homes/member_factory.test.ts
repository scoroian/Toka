import { buildNewMemberDoc, type NewMemberRole } from "./member_factory";

describe("buildNewMemberDoc", () => {
  const base = {
    uid: "u1",
    nickname: "Alice",
    role: "member" as NewMemberRole,
  };

  it("genera campos default correctos", () => {
    const doc = buildNewMemberDoc(base);
    expect(doc["nickname"]).toBe("Alice");
    expect(doc["role"]).toBe("member");
    expect(doc["status"]).toBe("active");
    expect(doc["tasksCompleted"]).toBe(0);
    expect(doc["passedCount"]).toBe(0);
    expect(doc["complianceRate"]).toBe(0.0);
    expect(doc["currentStreak"]).toBe(0);
    expect(doc["averageScore"]).toBe(0);
    expect(doc["phoneVisibility"]).toBe("hidden");
    expect(doc["photoUrl"]).toBeNull();
    expect(doc["bio"]).toBeNull();
    expect(doc["phone"]).toBeNull();
  });

  it("incluye opcionales si se proporcionan", () => {
    const doc = buildNewMemberDoc({
      ...base,
      photoUrl: "https://x.y/p.jpg",
      phone: "+34600111222",
      bio: "Hola",
    });
    expect(doc["photoUrl"]).toBe("https://x.y/p.jpg");
    expect(doc["phone"]).toBe("+34600111222");
    expect(doc["bio"]).toBe("Hola");
  });

  it("role owner se preserva", () => {
    const doc = buildNewMemberDoc({ ...base, role: "owner" });
    expect(doc["role"]).toBe("owner");
  });

  it("joinedAt es un FieldValue.serverTimestamp sentinel", () => {
    const doc = buildNewMemberDoc(base);
    // FieldValue.serverTimestamp() devuelve un sentinel; solo verificamos
    // que sea un objeto (no undefined ni null).
    expect(doc["joinedAt"]).toBeDefined();
    expect(doc["joinedAt"]).not.toBeNull();
  });
});
