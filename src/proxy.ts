import { ProxyAgent } from "proxy-agent";

/**
 * getProxyAgent - Return an ProxyAgent when a proxy URL is configured.
 *
 * @return {ProxyAgent | undefined}  An ProxyAgent instance or undefined if no proxy set.
 */
export function getProxyAgent(): ProxyAgent | undefined {
  return Proxy ? new ProxyAgent() : undefined;
}
