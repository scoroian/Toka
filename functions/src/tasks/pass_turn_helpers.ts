// functions/src/tasks/pass_turn_helpers.ts

export function getNextEligibleMember(
  order: string[],
  currentUid: string,
  frozenUids: string[]
): string {
  if (!order.length) return currentUid;
  const currentIdx = order.indexOf(currentUid);
  for (let i = 1; i < order.length; i++) {
    const candidate = order[(currentIdx + i) % order.length];
    if (!frozenUids.includes(candidate)) return candidate;
  }
  return currentUid;
}
