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

export function buildNewMemberDoc(p: NewMemberParams): Record<string, unknown> {
  return {
    nickname: p.nickname,
    photoUrl: p.photoUrl ?? null,
    bio: p.bio ?? null,
    phone: p.phone ?? null,
    phoneVisibility: p.phoneVisibility ?? "hidden",
    role: p.role,
    status: "active",
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
