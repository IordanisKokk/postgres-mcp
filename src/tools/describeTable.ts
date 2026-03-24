import { z } from "zod";
import type { DbClient } from "../db/client.js";
import { describeTableQuery } from "../db/introspection.js";
import type { DescribeTableInput, DescribeTableOutput } from "../types/index.js";

export const describeTableInputSchema = z
  .object({
    table: z.string().min(1),
    schema: z.string().min(1).optional()
  })
  .strict();

export async function runDescribeTable(
  db: DbClient,
  input: DescribeTableInput
): Promise<DescribeTableOutput> {
  return describeTableQuery(db, input);
}
