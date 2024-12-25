import type { Metadata } from "next"

import configPromise from "@payload-config"
import { getPayload } from "payload"
import { draftMode } from "next/headers"
import React, { cache } from "react"

import type { Page as PageType } from "@payload-types"
import { generateMeta } from "@lib/util/generateMeta"
import { PayloadRedirects } from "@modules/payload/components/PayloadRedirects"
import { RenderHero } from "@modules/payload/heros/RenderHero"
import { RenderBlocks } from "@modules/payload/blocks/RenderBlocks"

// import PageClient from "./page.client"

const queryPageBySlug = cache(async ({ slug }: { slug: string }) => {
  const { isEnabled: draft } = await draftMode()

  const payload = await getPayload({ config: configPromise })

  const result = await payload.find({
    collection: "pages",
    draft,
    limit: 1,
    pagination: false,
    overrideAccess: draft,
    where: {
      slug: {
        equals: slug,
      },
    },
  })

  return result.docs?.[0] || null
})

export async function generateStaticParams() {
  try {
    const payload = await getPayload({ config: configPromise })
    const pages = await payload.find({
      collection: "pages",
      draft: false,
      limit: 1000,
      overrideAccess: false,
      pagination: false,
      select: {
        slug: true,
      },
    })

    const params = pages.docs
      ?.filter((doc) => {
        return doc.slug !== "home"
      })
      .map(({ slug }) => {
        return { slug }
      })

    return params
  } catch (error) {
    console.error(error)
    return []
  }
}

type Args = {
  params: Promise<{
    slug?: string
  }>
}

export default async function Page({ params: paramsPromise }: Args) {
  const { slug = "home" } = await paramsPromise
  const url = "/" + slug

  let page: PageType | null

  page = await queryPageBySlug({
    slug,
  })

  if (!page) {
    return <PayloadRedirects url={url} />
  }

  const { hero, layout } = page

  return (
    <article className="pt-16 pb-24">
      {/* <PageClient /> */}
      {/* Allows redirects for valid pages too */}
      <PayloadRedirects disableNotFound url={url} />

      <RenderHero {...hero} />
      <RenderBlocks blocks={layout} />
    </article>
  )
}

export async function generateMetadata({
  params: paramsPromise,
}): Promise<Metadata> {
  const { slug = "home" } = await paramsPromise
  const page = await queryPageBySlug({
    slug,
  })

  return generateMeta({ doc: page })
}
