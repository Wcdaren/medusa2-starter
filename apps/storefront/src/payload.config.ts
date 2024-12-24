// storage-adapter-import-placeholder
import { postgresAdapter } from "@payloadcms/db-postgres"
import { payloadCloudPlugin } from "@payloadcms/payload-cloud"
import { lexicalEditor } from "@payloadcms/richtext-lexical"
import path from "path"
import { buildConfig } from "payload"
import { fileURLToPath } from "url"
import sharp from "sharp"

import { Users } from "@modules/payload/collections/Users"
import { Media } from "@modules/payload/collections/Media"
import { Footer } from "@modules/payload/Footer/config"
import { defaultLexical } from "@modules/payload/fields/defaultLexical"
import { Pages } from "@modules/payload/collections/Pages"
import { Posts } from "@modules/payload/collections/Posts"
import { Categories } from "modules/payload/collections/Categories"
const filename = fileURLToPath(import.meta.url)
const dirname = path.dirname(filename)

export default buildConfig({
  admin: {
    user: Users.slug,
    importMap: {
      baseDir: path.resolve(dirname),
    },
  },
  collections: [Users, Media, Pages, Posts, Categories],
  editor: lexicalEditor(),
  // This config helps us configure global or default features that the other editors can inherit
  // editor: defaultLexical,
  secret: process.env.PAYLOAD_SECRET || "",
  typescript: {
    outputFile: path.resolve(dirname, "types/payload-types.ts"),
  },
  // database-adapter-config-start
  db: postgresAdapter({
    pool: {
      connectionString: process.env.DATABASE_URI || "",
    },
  }),
  // database-adapter-config-end
  // This config helps us configure global or default features that the other editors can inherit
  sharp,
  plugins: [
    payloadCloudPlugin(),
    // storage-adapter-placeholder
  ],
  globals: [Footer],
})
