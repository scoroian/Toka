// functions/test/integration/helpers/jest_setup.ts
//
// setupFilesAfterEnv para tests de integración: el flag de tiers se lee de
// Remote Config, que NO tiene emulador. Por defecto lo dejamos OFF y con un
// fetcher local (sin red) para que los tests que no tocan tiers no peguen a RC.
// Cada archivo que necesite el flag ON lo activa con
// __setHomeTiersEnabledForTesting(true) (y lo resetea en afterAll).
import {
  __setHomeTiersEnabledForTesting,
  __setTiersFetcherForTesting,
  __setTokaPlusEnabledForTesting,
  __setPlusFetcherForTesting,
  __setMemberPacksEnabledForTesting,
  __setPacksFetcherForTesting,
} from '../../../src/shared/feature_flags';

__setHomeTiersEnabledForTesting(undefined);
__setTiersFetcherForTesting(async () => false);
// El flag de Toka Plus también se lee de Remote Config (sin emulador): default
// OFF con fetcher local. Cada test que necesite Plus ON lo activa con
// __setTokaPlusEnabledForTesting(true) y lo resetea en afterAll.
__setTokaPlusEnabledForTesting(undefined);
__setPlusFetcherForTesting(async () => false);
// Flag de packs de miembro: mismo patrón (RC sin emulador). Default OFF con
// fetcher local; cada test de packs lo activa con
// __setMemberPacksEnabledForTesting(true) y lo resetea en afterAll.
__setMemberPacksEnabledForTesting(undefined);
__setPacksFetcherForTesting(async () => false);
