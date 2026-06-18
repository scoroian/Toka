import {
  buildNewMemberDoc,
  readMemberProfileFields,
  type NewMemberRole,
} from "./member_factory";

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

  it("respeta phoneVisibility cuando el usuario optó por compartir", () => {
    // Regresión bug #4 (QA 2026-06-16): al unirse a un hogar, un usuario que
    // activó "Mostrar mi teléfono" quedaba con phoneVisibility:"hidden".
    const doc = buildNewMemberDoc({
      ...base,
      phone: "+34600111222",
      phoneVisibility: "sameHomeMembers",
    });
    expect(doc["phone"]).toBe("+34600111222");
    expect(doc["phoneVisibility"]).toBe("sameHomeMembers");
  });

  it("phoneVisibility default es hidden si no se proporciona", () => {
    const doc = buildNewMemberDoc(base);
    expect(doc["phoneVisibility"]).toBe("hidden");
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

describe("readMemberProfileFields", () => {
  it("lee los 4 campos de perfil de un usuario completo", () => {
    const fields = readMemberProfileFields({
      nickname: "Alice",
      photoUrl: "https://x.y/p.jpg",
      phone: "+34600111222",
      phoneVisibility: "sameHomeMembers",
      // Campos que NO deben filtrarse al doc de miembro:
      email: "alice@test.dev",
      baseHomeSlots: 2,
    });
    expect(fields).toEqual({
      nickname: "Alice",
      photoUrl: "https://x.y/p.jpg",
      phone: "+34600111222",
      phoneVisibility: "sameHomeMembers",
    });
  });

  it("aplica defaults cuando faltan campos", () => {
    const fields = readMemberProfileFields({ nickname: "Bob" });
    expect(fields).toEqual({
      nickname: "Bob",
      photoUrl: null,
      phone: null,
      phoneVisibility: "hidden",
    });
  });

  it("usa defaults seguros con userData undefined", () => {
    const fields = readMemberProfileFields(undefined);
    expect(fields).toEqual({
      nickname: "",
      photoUrl: null,
      phone: null,
      phoneVisibility: "hidden",
    });
  });

  it("preserva teléfono con visibilidad oculta (caso opt-out)", () => {
    const fields = readMemberProfileFields({
      nickname: "Carol",
      phone: "+34600999888",
      phoneVisibility: "hidden",
    });
    expect(fields.phone).toBe("+34600999888");
    expect(fields.phoneVisibility).toBe("hidden");
  });
});
