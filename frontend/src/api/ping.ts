export type PingResponse = {
  message: string
  dbTime: string
}

export async function fetchPing(): Promise<PingResponse> {
  const response = await fetch('/api/ping')
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }
  return response.json()
}
