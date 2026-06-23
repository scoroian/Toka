import {
  buildNewMemberDoc,
  readMemberProfileFields,
  sanitizeMemberPhone,
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

  it("incluye opcionales si se proporcionan (teléfono solo si se comparte)", () => {
    const doc = buildNewMemberDoc({
      ...base,
      photoUrl: "https://x.y/p.jpg",
      phone: "+34600111222",
      phoneVisibility: "sameHomeMembers",
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

  it("NO denormaliza el teléfono cuando la visibilidad es hidden (Hallazgo #01)", () => {
    // Privacidad: aunque el usuario tenga teléfono, si optó por ocultarlo el
    // doc de miembro (legible por todo el hogar) debe guardar null. El número
    // sigue accesible para el propio usuario desde users/{uid}.
    const doc = buildNewMemberDoc({
      ...base,
      phone: "+34600999888",
      phoneVisibility: "hidden",
    });
    expect(doc["phone"]).toBeNull();
    expect(doc["phoneVisibility"]).toBe("hidden");
  });

  it("NO denormaliza el teléfono cuando no se especifica visibilidad (default hidden)", () => {
    const doc = buildNewMemberDoc({ ...base, phone: "+34600999888" });
    expect(doc["phone"]).toBeNull();
    expect(doc["phoneVisibility"]).toBe("hidden");
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

  it("es un lector FIEL: devuelve el teléfono aunque la visibilidad sea oculta", () => {
    // readMemberProfileFields lee users/{uid} tal cual (incluye el número real
    // y su visibilidad). El SANEADO de privacidad (no escribirlo si está oculto)
    // ocurre en el punto de ESCRITURA del doc de miembro: sanitizeMemberPhone /
    // buildNewMemberDoc. Ver tests de sanitizeMemberPhone más abajo.
    const fields = readMemberProfileFields({
      nickname: "Carol",
      phone: "+34600999888",
      phoneVisibility: "hidden",
    });
    expect(fields.phone).toBe("+34600999888");
    expect(fields.phoneVisibility).toBe("hidden");
  });
});

describe("sanitizeMemberPhone (Hallazgo #01)", () => {
  it("devuelve el teléfono cuando la visibilidad es sameHomeMembers", () => {
    expect(sanitizeMemberPhone("+34600111222", "sameHomeMembers")).toBe(
      "+34600111222"
    );
  });

  it("devuelve null cuando la visibilidad es hidden", () => {
    expect(sanitizeMemberPhone("+34600111222", "hidden")).toBeNull();
  });

  it("devuelve null para visibilidades desconocidas o nulas (fail-closed)", () => {
    expect(sanitizeMemberPhone("+34600111222", undefined)).toBeNull();
    expect(sanitizeMemberPhone("+34600111222", null)).toBeNull();
    expect(sanitizeMemberPhone("+34600111222", "otraCosa")).toBeNull();
  });

  it("devuelve null cuando no hay teléfono aunque se comparta", () => {
    expect(sanitizeMemberPhone(null, "sameHomeMembers")).toBeNull();
    expect(sanitizeMemberPhone(undefined, "sameHomeMembers")).toBeNull();
  });
});
