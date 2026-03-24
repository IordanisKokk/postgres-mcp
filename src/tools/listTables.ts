import { z } from "zod";
import type { DbClient } from "../db/client.js";
import { listTablesQuery } from "../db/introspection.js";
import type { ListTablesInput, ListTablesOutput } from "../types/index.js";

export const listTablesInputSchema = z
  .object({
    schema: z.string().min(1).optional(),
    include_views: z.boolean().optional()
  })
  .strict();

export async function runListTables(
  db: DbClient,
  input: ListTablesInput
): Promise<ListTablesOutput> {
  const tables = await listTablesQuery(db, input);
  return { tables };
}
