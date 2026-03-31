import React, { createContext, useContext } from 'react'

/**
 * TunnelApiContext
 * 用于在组网隧道管理中注入远程节点的 API 适配器。
 * 当 Context 中有值时，各隧道页面组件使用注入的 API；否则使用默认的本地 API。
 */

interface TunnelApiContextValue {
  /** 自定义 API 对象（与各隧道页面的 API 接口兼容） */
  api: any
  /** 是否处于远程模式（嵌入在 MeshTunnels 中） */
  isRemoteMode: boolean
  /** 数据刷新回调（用于通知父组件刷新列表） */
  onRefresh?: () => void
}

const TunnelApiContext = createContext<TunnelApiContextValue | null>(null)

export const TunnelApiProvider = TunnelApiContext.Provider

/**
 * 获取隧道 API 上下文。
 * 如果在 MeshTunnels 中使用（有 Provider），返回注入的 API；
 * 否则返回 null，页面组件应使用默认的本地 API。
 */
export function useTunnelApi(): TunnelApiContextValue | null {
  return useContext(TunnelApiContext)
}

export default TunnelApiContext
