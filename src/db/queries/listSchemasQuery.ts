import { DbClient } from "../client.js";
import { env } from "../../config/env.js";

type SchemaRow = {
    name: string;
}

export async function listSchemasQuery(
    db: DbClient
): Promise<Array<{ name: string }>> {
    const params: unknown[] = [];

    let sql = `
        SELECT schema_name AS name
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('pg_catalog',
        'information_schema')
    `;

    if (env.ALLOWED_SCHEMAS.length > 0) {
        sql += ` AND schema_name = ANY($${params.length + 1}::text[])`;
        params.push(env.ALLOWED_SCHEMAS);
    }

    sql += " ORDER BY schema_name";

    const { rows } = await db.query<SchemaRow>(sql, params);
    return rows;
};