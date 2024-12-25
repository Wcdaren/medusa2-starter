import canUseDOM from "./canUseDOM"
import { getBaseURL } from "./env"

export const getServerSideURL = () => {
  let url = `${getBaseURL()}`
  return url
}

export const getClientSideURL = () => {
  if (canUseDOM) {
    const protocol = window.location.protocol
    const domain = window.location.hostname
    const port = window.location.port

    return `${protocol}//${domain}${port ? `:${port}` : ""}`
  }

  return getBaseURL() || ""
}
