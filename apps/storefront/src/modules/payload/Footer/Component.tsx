// import { getCachedGlobal } from "@/utilities/getGlobals"
import Link from "next/link"
import React from "react"

// import types { Footer } from "@lib/payload-types"

// import { ThemeSelector } from "@/providers/Theme/ThemeSelector"
// import { CMSLink } from "@/components/Link"
// import { Logo } from "@/components/Logo/Logo"
import type { Footer } from "../../../../payload-types"
import { getCachedGlobal } from "@lib/data/pyaload"
import { CMSLink } from "../components/Link"

export async function Footer() {
  const footer: Footer = await getCachedGlobal("footer", 1)()

  const navItems = footer?.navItems || []

  return (
    <footer className="border-t border-border bg-black dark:bg-card text-white">
      <div className="container py-8 gap-8 flex flex-col md:flex-row md:justify-between">
        <Link className="flex items-center" href="/">
          {/* <Logo /> */}
          logo
        </Link>

        <div className="flex flex-col-reverse items-start md:flex-row gap-4 md:items-center">
          {/* <ThemeSelector /> */}
          <nav className="flex flex-col md:flex-row gap-4">
            {navItems.map(({ link }, i) => {
              return <CMSLink className="text-white" key={i} {...link} />
            })}
          </nav>
        </div>
      </div>
    </footer>
  )
}
