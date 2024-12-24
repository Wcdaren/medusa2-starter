// import { cn } from "src/utilities/cn"
import { cn } from "@lib/util/cn"
import { Button } from "@medusajs/ui"
import Link from "next/link"
import React from "react"
import type { Page, Post } from "types/payload-types"

// 基于 Button 获取 ButtonProps 类型
type ButonProps = React.ComponentProps<typeof Button>

type CMSLinkType = {
  appearance?: "inline"
  children?: React.ReactNode
  className?: string
  label?: string | null
  newTab?: boolean | null
  reference?: {
    relationTo: "pages" | "posts"
    value: Page | Post | string | number
  } | null
  size?: ButonProps["size"] | undefined
  type?: "custom" | "reference" | null
  url?: string | null
}

export const CMSLink: React.FC<CMSLinkType> = (props) => {
  const {
    type,
    appearance = "inline",
    children,
    className,
    label,
    newTab,
    reference,
    size: sizeFromProps,
    url,
  } = props

  const href =
    type === "reference" &&
    typeof reference?.value === "object" &&
    reference.value.slug
      ? `${
          reference?.relationTo !== "pages" ? `/${reference?.relationTo}` : ""
        }/${reference.value.slug}`
      : url

  if (!href) return null

  const size = appearance === "inline" ? "base" : sizeFromProps
  const newTabProps = newTab
    ? { rel: "noopener noreferrer", target: "_blank" }
    : {}

  /* Ensure we don't break any styles set by richText */
  if (appearance === "inline") {
    return (
      <Link className={cn(className)} href={href || url || ""} {...newTabProps}>
        {label && label}
        {children && children}
      </Link>
    )
  }

  return (
    <Button asChild className={className} size={size} variant={appearance}>
      <Link className={cn(className)} href={href || url || ""} {...newTabProps}>
        {label && label}
        {children && children}
      </Link>
    </Button>
  )
}