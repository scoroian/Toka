import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions/v2";

admin.initializeApp();
setGlobalOptions({ invoker: "public" });

export * from "./entitlement";
export * from "./tasks";
export * from "./homes";
export * from "./notifications";
export * from "./jobs";
