import { FieldValue } from "firebase-admin/firestore";

export type NewMemberRole = "owner" | "admin" | "member";

export interface NewMemberParams {
  uid: string;
  nickname: string;
  role: NewMemberRole;
  photoUrl?: string | null;
  phone?: string | null;
  phoneVisibility?: string | null;
  bio?: string | null;
  /**
   * Proyección del eje Toka Plus del usuario (`users/{uid}/entitlements/plus`
   * .active), denormalizada en el doc de miembro para que los co-miembros
   * vigentes puedan leerla. Por defecto false; el alta la backfillea leyendo el
   * doc de Plus. Solo el backend la escribe.
   */
  plusActive?: boolean;
}

/**
 * Campos del perfil del usuario (users/{uid}) que se denormalizan en el doc de
 * miembro (homes/{homeId}/members/{uid}) para que otros miembros del hogar los
 * lean (no tienen acceso de lectura a users/{uid}). La visibilidad del teléfono
 * es una preferencia GLOBAL del usuario; aquí se snapshotea por hogar.
 */
export interface MemberProfileFields {
  nickname: string;
  photoUrl: string | null;
  phone: string | null;
  phoneVisibility: string;
}

/**
 * Lee del documento users/{uid} los campos de perfil que deben propagarse al
 * doc de miembro. Centraliza los defaults para que joinHome, joinHomeByCode,
 * createHome, repairMemberDocument y syncMemberProfile sean coherentes.
 */
export function readMemberProfileFields(
  userData: Record<string, unknown> | undefined
): MemberProfileFields {
  const data = userData ?? {};
  return {
    nickname: (data["nickname"] as string | undefined) ?? "",
    photoUrl: (data["photoUrl"] as string | undefined) ?? null,
    phone: (data["phone"] as string | undefined) ?? null,
    phoneVisibility:
      (data["phoneVisibility"] as string | undefined) ?? "hidden",
  };
}

/**
 * Decide qué teléfono se denormaliza en el doc de miembro
 * (homes/{homeId}/members/{uid}), que es legible por todo el hogar.
 *
 * PRIVACIDAD (Hallazgo #01): el doc de miembro NUNCA debe contener el teléfono
 * si la visibilidad es 'hidden'. El filtrado vivía solo en cliente
 * (member.dart phoneForViewer), por lo que cualquier co-miembro podía leer el
 * número en claro saltándose la UI. Aquí lo cortamos en el ORIGEN (servidor):
 * si la visibilidad no es 'sameHomeMembers', el campo se escribe a null. El
 * usuario sigue viendo su propio teléfono desde users/{uid} (doc privado).
 */
export function sanitizeMemberPhone(
  phone: string | null | undefined,
  phoneVisibility: string | null | undefined
): string | null {
  return phoneVisibility === "sameHomeMembers" ? phone ?? null : null;
}

export function buildNewMemberDoc(p: NewMemberParams): Record<string, unknown> {
  return {
    nickname: p.nickname,
    photoUrl: p.photoUrl ?? null,
    bio: p.bio ?? null,
    phone: sanitizeMemberPhone(p.phone, p.phoneVisibility),
    phoneVisibility: p.phoneVisibility ?? "hidden",
    role: p.role,
    status: "active",
    plusActive: p.plusActive ?? false,
    joinedAt: FieldValue.serverTimestamp(),
    // Campos canónicos que lee el cliente (member_model.dart): tasksCompleted
    // y averageScore. No usar completedCount/avgReviewScore: el cliente no los
    // lee y dejaría el perfil mostrando 0 (regresión del bug #26).
    tasksCompleted: 0,
    completions60d: 0,
    passedCount: 0,
    complianceRate: 0.0,
    currentStreak: 0,
    averageScore: 0.0,
  };
}
