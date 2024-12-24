// storage-adapter-import-placeholder
import { postgresAdapter } from "@payloadcms/db-postgres"
import { lexicalEditor } from "@payloadcms/richtext-lexical"
import path from "path"
import { buildConfig } from "payload"
import { fileURLToPath } from "url"
import sharp from "sharp"

import { Users } from "@modules/payload/collections/Users"
import { Media } from "@modules/payload/collections/Media"
import { Footer } from "@modules/payload/Footer/config"
import { Pages } from "@modules/payload/collections/Pages"
import { Posts } from "@modules/payload/collections/Posts"
import { Categories } from "modules/payload/collections/Categories"
import { plugins } from "@modules/payload/plugins"
import { en } from "@payloadcms/translations/languages/en"
import { zh } from "@payloadcms/translations/languages/zh"

const filename = fileURLToPath(import.meta.url)
const dirname = path.dirname(filename)

export default buildConfig({
  admin: {
    user: Users.slug,
    importMap: {
      baseDir: path.resolve(dirname),
    },
    livePreview: {
      breakpoints: [
        {
          label: "Mobile",
          name: "mobile",
          width: 375,
          height: 667,
        },
        {
          label: "Tablet",
          name: "tablet",
          width: 768,
          height: 1024,
        },
        {
          label: "Desktop",
          name: "desktop",
          width: 1440,
          height: 900,
        },
      ],
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

  i18n: {
    supportedLanguages: { en, zh },
  },

  // FIXME 现在如果开启的话有问题
  // localization: {
  //   locales: [
  //     {
  //       label: {
  //         en: "English",
  //         zh: "英文",
  //       },
  //       code: "en",
  //     },
  //     {
  //       label: "Chinese",
  //       code: "zh",
  //       // opt-in to setting default text-alignment on Input fields to rtl (right-to-left)
  //       // when current locale is rtl
  //       // rtl: true,
  //     },
  //   ],
  //   defaultLocale: "en", // required
  //   fallback: true, // defaults to true
  // },
  plugins: [
    // payloadCloudPlugin(),
    ...plugins,
    // storage-adapter-placeholder
  ],
  globals: [Footer],
  debug: true,
})
