import { z } from "zod";
import type { DbClient } from "../db/client.js";
import { listSchemasQuery } from "../db/queries/listSchemasQuery.js";
import type { ListSchemasInput, ListSchemasOutput } from "../types/index.js";

export const listSchemasInputSchema = z.object({}).strict();

export async function runListSchemas(
  db: DbClient,
  _input: ListSchemasInput
): Promise<ListSchemasOutput> {
  const schemas = await listSchemasQuery(db);
  return { schemas };
}
