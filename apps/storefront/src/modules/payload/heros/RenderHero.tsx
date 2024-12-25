import React from "react"
import { HighImpactHero } from "./HighImpact"
import { LowImpactHero } from "./LowImpact"
import { MediumImpactHero } from "./MediumImpact"
import { Page } from "@payload-types"

const heroes = {
  highImpact: HighImpactHero,
  lowImpact: LowImpactHero,
  mediumImpact: MediumImpactHero,
}

export const RenderHero: React.FC<Page["hero"]> = (props) => {
  const { type } = props || {}
  console.log("🚀 ~ type:", type)

  if (!type || type === "none") return null

  const HeroToRender = heroes[type]

  if (!HeroToRender) return null

  return <HeroToRender {...props} />
}
