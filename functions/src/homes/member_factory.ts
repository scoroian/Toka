import { FieldValue } from "firebase-admin/firestore";

export type NewMemberRole = "owner" | "admin" | "member";

export interface NewMemberParams {
  uid: string;
  nickname: string;
  role: NewMemberRole;
  photoUrl?: string | null;
  phone?: string | null;
  bio?: string | null;
}

export function buildNewMemberDoc(p: NewMemberParams): Record<string, unknown> {
  return {
    nickname: p.nickname,
    photoUrl: p.photoUrl ?? null,
    bio: p.bio ?? null,
    phone: p.phone ?? null,
    phoneVisibility: "hidden",
    role: p.role,
    status: "active",
    joinedAt: FieldValue.serverTimestamp(),
    tasksCompleted: 0,
    passedCount: 0,
    complianceRate: 0.0,
    currentStreak: 0,
    averageScore: 0.0,
  };
}
