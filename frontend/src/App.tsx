import { useEffect, useState } from 'react'
import { fetchPing, type PingResponse } from './api/ping'

function App() {
  const [ping, setPing] = useState<PingResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchPing()
      .then(setPing)
      .catch((e: Error) => setError(e.message))
  }, [])

  return (
    <main style={{ padding: 24 }}>
      <h1>clean-booking</h1>
      {error && <p>백엔드 연결 실패: {error}</p>}
      {!ping && !error && <p>백엔드 확인 중...</p>}
      {ping && (
        <p>
          백엔드 응답: {ping.message} · DB 시간: {ping.dbTime}
        </p>
      )}
    </main>
  )
}

export default App
