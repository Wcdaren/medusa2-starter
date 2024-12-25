import type { CollectionConfig } from "payload"

import { revalidateDelete, revalidatePage } from "./hooks/revalidatePage"

import {
  MetaDescriptionField,
  MetaImageField,
  MetaTitleField,
  OverviewField,
  PreviewField,
} from "@payloadcms/plugin-seo/fields"
import { getServerSideURL } from "@lib/util/getURL"
import { generatePreviewPath } from "@lib/util/generatePreviewPath"
import { slugField } from "@modules/payload/fields/slug"
import { populatePublishedAt } from "@modules/payload/hooks/populatePublishedAt"
import { hero } from "@modules/payload/heros/config"
// blocks
import { CallToAction } from "@modules/payload/blocks/CallToAction/config"
import { Content } from "@modules/payload/blocks/Content/config"
import { MediaBlock } from "@modules/payload/blocks/MediaBlock/config"
import { Archive } from "@modules/payload/blocks/ArchiveBlock/config"
import { FormBlock } from "@modules/payload/blocks/Form/config"
import { authenticated } from "@modules/payload/access/authenticated"
import { authenticatedOrPublished } from "@modules/payload/access/authenticatedOrPublished"

export const Pages: CollectionConfig<"pages"> = {
  slug: "pages",
  access: {
    create: authenticated,
    delete: authenticated,
    read: authenticatedOrPublished,
    update: authenticated,
  },
  // This config controls what's populated by default when a page is referenced
  // https://payloadcms.com/docs/queries/select#defaultpopulate-collection-config-property
  // Type safe if the collection slug generic is passed to `CollectionConfig` - `CollectionConfig<'pages'>
  defaultPopulate: {
    title: true,
    slug: true,
  },
  admin: {
    defaultColumns: ["title", "slug", "updatedAt"],
    livePreview: {
      url: ({ data }) => {
        const path = generatePreviewPath({
          slug: typeof data?.slug === "string" ? data.slug : "",
          collection: "pages",
        })

        return `${getServerSideURL()}${path}`
      },
    },
    preview: (data) => {
      const path = generatePreviewPath({
        slug: typeof data?.slug === "string" ? data.slug : "",
        collection: "pages",
      })

      console.log(
        "🚀 ~ `${getServerSideURL()}${path}`:",
        `${getServerSideURL()}${path}`
      )
      return `${getServerSideURL()}${path}`
    },
    useAsTitle: "title",
  },
  fields: [
    {
      name: "title",
      type: "text",
      required: true,
    },
    {
      type: "tabs",
      tabs: [
        {
          fields: [hero],
          label: "Hero",
        },
        {
          fields: [
            {
              name: "layout",
              type: "blocks",
              blocks: [CallToAction, Content, MediaBlock, Archive, FormBlock],
              required: true,
            },
          ],
          label: "Content",
        },
        {
          name: "meta",
          label: "SEO",
          fields: [
            OverviewField({
              titlePath: "meta.title",
              descriptionPath: "meta.description",
              imagePath: "meta.image",
            }),
            MetaTitleField({
              hasGenerateFn: true,
            }),
            MetaImageField({
              relationTo: "media",
            }),

            MetaDescriptionField({}),
            PreviewField({
              // if the `generateUrl` function is configured
              hasGenerateFn: true,

              // field paths to match the target field for data
              titlePath: "meta.title",
              descriptionPath: "meta.description",
            }),
          ],
        },
      ],
    },
    {
      name: "publishedAt",
      type: "date",
      admin: {
        position: "sidebar",
      },
    },
    ...slugField(),
  ],
  hooks: {
    afterChange: [revalidatePage],
    beforeChange: [populatePublishedAt],
    // beforeDelete: [revalidateDelete],
  },
  versions: {
    drafts: {
      autosave: {
        interval: 100, // We set this interval for optimal live preview
      },
    },
    maxPerDoc: 50,
  },
}
