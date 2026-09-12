export type CalendarProfile = "MODERN_VIETNAM" | "HISTORICAL_VIETNAM_TIME4J_REFERENCE";
export interface DailyQuota { limit: number; remaining: number; resetEpochSeconds: number }
export interface LunarDate { day: number; month: number; year: number; isLeapMonth: boolean; yearCanChi?: string; dayCanChi?: string }
export interface SolarDate { day: number; month: number; year: number }
export interface Provenance { calendarVersion: string; engineVersion: string; profile: CalendarProfile; overrideSource: string | null; overridePublishedOn: string | null }
export class LunarApiError extends Error { status?: number; code?: string; retryAfter?: number | null; quota?: DailyQuota | null }
export class VietnameseLunarClient {
  constructor(options: { apiKey: string; baseUrl?: string; fetch?: typeof globalThis.fetch; timeoutMs?: number; allowBrowser?: boolean });
  lastQuota: DailyQuota | null;
  toLunar(date: string, profile?: CalendarProfile): Promise<Provenance & { lunar: LunarDate }>;
  toSolar(input: { day: number; month: number; year: number; isLeapMonth?: boolean; profile?: CalendarProfile }): Promise<Provenance & { solar: SolarDate }>;
  solarTerms(year: number, profile?: CalendarProfile): Promise<Provenance & { year: number; terms: unknown[] }>;
  toLunarBatch(dates: string[], profile?: CalendarProfile): Promise<Provenance & { results: Array<{ date: string; lunar: LunarDate }> }>;
}
