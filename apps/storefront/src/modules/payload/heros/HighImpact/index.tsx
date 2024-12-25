"use client"
import React, { useEffect } from "react"
import { Page } from "@payload-types"
import RichText from "@modules/payload/components/RichText"
import { Media } from "@modules/payload/components/Media/index"
import { CMSLink } from "@modules/payload/components/Link"
// import { useHeaderTheme } from "@/providers/HeaderTheme"

export const HighImpactHero: React.FC<Page["hero"]> = ({
  links,
  media,
  richText,
}) => {
  // const { setHeaderTheme } = useHeaderTheme()

  // useEffect(() => {
  //   setHeaderTheme("dark")
  // })

  return (
    <div
      className="relative -mt-[10.4rem] flex items-center justify-center text-white"
      data-theme="dark"
    >
      <div className="container mb-8 z-10 relative flex items-center justify-center">
        <div className="max-w-[36.5rem] text-center">
          {richText && (
            <RichText
              className="mb-6"
              content={richText}
              enableGutter={false}
            />
          )}
          {Array.isArray(links) && links.length > 0 && (
            <ul className="flex justify-center gap-4">
              {links.map(({ link }, i) => {
                return (
                  <li key={i}>
                    <CMSLink {...link} />
                  </li>
                )
              })}
            </ul>
          )}
        </div>
      </div>
      <div className="min-h-[80vh] select-none">
        {media && typeof media === "object" && (
          <Media
            fill
            imgClassName="-z-10 object-cover"
            priority={false}
            loading="lazy"
            resource={media}
          />
        )}
      </div>
    </div>
  )
}
