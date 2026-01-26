import { ProxyAgent } from "proxy-agent";

/**
 * getProxyAgent - Return a ProxyAgent when a proxy URL is configured.
 *
 * @return {ProxyAgent | undefined}  A ProxyAgent instance or undefined if no proxy set.
 */
export function getProxyAgent(): ProxyAgent | undefined {
  const hasProxyEnv = process.env.HTTP_PROXY || process.env.HTTPS_PROXY;
  return hasProxyEnv ? new ProxyAgent() : undefined;
}
